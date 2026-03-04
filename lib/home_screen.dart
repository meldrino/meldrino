import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_holding.dart';
import 'nano_service.dart';
import 'price_service.dart';
import 'app_bar.dart';
import 'coin_detail_screen.dart';
import 'wallet_registry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CoinHolding> _holdings = [];
  bool _loading = true;
  String? _error;
  final Set<String> _expandedWallets = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _fiatSymbol(String currency) {
    switch (currency) {
      case "GBP": return "£";
      case "EUR": return "€";
      default: return "\$";
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final wallets = prefs.getStringList("wallets") ?? [];
      final fiatCurrency = prefs.getString("fiatCurrency") ?? "USD";
      final prices = await PriceService.getPrices(fiatCurrency);
      final xnoPrice = prices["xno"] ?? 0;
      final List<CoinHolding> holdings = [];

      for (final w in wallets) {
        final parts = w.split("|");
        final coin = parts[0];
        final label = parts[1].isNotEmpty ? parts[1] : parts[0];
        final address = parts[2];

        // Look up androidPackage from registry by wallet label
        String? androidPackage;
        try {
          final walletDef = WalletRegistry.all.firstWhere(
            (w) => w.name == label,
          );
          androidPackage = walletDef.androidPackage;
        } catch (_) {}

        if (coin.contains("Nano")) {
          final balance = await NanoService.getBalance(address);
          holdings.add(CoinHolding(
            name: "Nano",
            ticker: "XNO",
            wallet: label,
            address: address,
            balance: balance,
            priceUsd: xnoPrice,
            fiatCurrency: fiatCurrency,
            fiatSymbol: _fiatSymbol(fiatCurrency),
            androidPackage: androidPackage,
          ));
        }
      }

      holdings.sort((a, b) => b.fiatValue.compareTo(a.fiatValue));
      setState(() {
        _holdings = holdings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load data: " + e.toString();
        _loading = false;
      });
    }
  }

  Map<String, List<CoinHolding>> _groupByWallet() {
    final Map<String, List<CoinHolding>> grouped = {};
    for (final h in _holdings) {
      grouped.putIfAbsent(h.wallet, () => []).add(h);
    }
    return grouped;
  }

  void _navigateToDetail(CoinHolding holding) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoinDetailScreen(holding: holding),
      ),
    );
  }

  Widget _buildSingleRow(CoinHolding coin) {
    return ListTile(
      onTap: () => _navigateToDetail(coin),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2A2A4A),
        child: Text(
          coin.ticker[0],
          style: const TextStyle(
              color: Colors.tealAccent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(coin.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(coin.wallet,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
      trailing: SizedBox(
        width: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              coin.fiatSymbol + coin.fiatValue.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              coin.balance.toStringAsFixed(4) + " " + coin.ticker,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String walletName, List<CoinHolding> coins) {
    final isExpanded = _expandedWallets.contains(walletName);
    final totalFiat = coins.fold(0.0, (sum, c) => sum + c.fiatValue);
    final fiatSymbol = coins.first.fiatSymbol;
    final coinNames = coins.map((c) => c.ticker).join(", ");

    return ListTile(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedWallets.remove(walletName);
          } else {
            _expandedWallets.add(walletName);
          }
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2A2A4A),
        child: Text(
          walletName[0].toUpperCase(),
          style: const TextStyle(
              color: Colors.tealAccent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(walletName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(coinNames,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fiatSymbol + totalFiat.toStringAsFixed(2),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text("Multi",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildCoinSubRow(CoinHolding coin) {
    return InkWell(
      onTap: () => _navigateToDetail(coin),
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2A2A4A),
              child: Text(
                coin.ticker[0],
                style: const TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    coin.balance.toStringAsFixed(4) + " " + coin.ticker,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              coin.fiatSymbol + coin.fiatValue.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeldrinoAppBar(onRefresh: _loadData, showRefresh: true),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Fetching balances..."),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)))
              : _holdings.isEmpty
                  ? const Center(child: Text("No wallets added yet"))
                  : ListView(
                      children: () {
                        final grouped = _groupByWallet();
                        final List<Widget> rows = [];
                        for (final entry in grouped.entries) {
                          final walletName = entry.key;
                          final coins = entry.value;
                          if (rows.isNotEmpty) {
                            rows.add(const Divider(
                                height: 1, color: Color(0xFF2A2A4A)));
                          }
                          if (coins.length == 1) {
                            rows.add(_buildSingleRow(coins.first));
                          } else {
                            rows.add(_buildGroupHeader(walletName, coins));
                            if (_expandedWallets.contains(walletName)) {
                              for (final coin in coins) {
                                rows.add(const Divider(
                                    height: 1,
                                    color: Color(0xFF2A2A4A),
                                    indent: 32));
                                rows.add(_buildCoinSubRow(coin));
                              }
                            }
                          }
                        }
                        return rows;
                      }(),
                    ),
    );
  }
}
