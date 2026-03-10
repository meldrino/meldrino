import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_holding.dart';
import 'coin_registry.dart';
import 'price_service.dart';
import 'app_bar.dart';
import 'coin_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CoinHolding> _holdings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _fiatSymbol(String currency) {
    switch (currency) {
      case 'GBP': return '£';
      case 'EUR': return '€';
      default: return '\$';
    }
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final wallets = prefs.getStringList('wallets') ?? [];
      final fiatCurrency = prefs.getString('fiatCurrency') ?? 'USD';
      final symbol = _fiatSymbol(fiatCurrency);
      final prices = await PriceService.getPrices(fiatCurrency);
      final List<CoinHolding> holdings = [];

      for (final entry in wallets) {
        final parts = entry.split('|');
        if (parts.length < 3) continue;

        final adapter = CoinRegistry.fromWalletEntry(entry);
        if (adapter == null) continue;

        final walletLabel = parts[1].isNotEmpty ? parts[1] : parts[0];
        final rawAddress = parts[2];

        try {
          final balance = await adapter.getBalance(rawAddress);
          final rawPrice = prices[adapter.coingeckoId] ?? 0.0;
          final price = adapter.adjustPrice(rawPrice);
          final displayAddress = adapter.isCustodial
              ? await adapter.resolveDisplayAddress(rawAddress)
              : rawAddress;

          holdings.add(CoinHolding(
            name: adapter.name,
            ticker: adapter.ticker,
            wallet: walletLabel,
            address: displayAddress,
            rawAddress: rawAddress,
            balance: balance,
            priceUsd: price,
            fiatCurrency: fiatCurrency,
            fiatSymbol: symbol,
          ));
        } catch (_) {
          // skip wallets that fail to load individually
        }
      }

      holdings.sort((a, b) => b.fiatValue.compareTo(a.fiatValue));
      setState(() { _holdings = holdings; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load data: $e'; _loading = false; });
    }
  }

  Widget _coinIcon(String ticker) {
    final adapter = CoinRegistry.byTicker(ticker);
    if (adapter != null) {
      return CircleAvatar(
        backgroundColor: const Color(0xFF2A2A4A),
        backgroundImage: AssetImage(adapter.iconPath),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF2A2A4A),
      child: Text(
        ticker.isNotEmpty ? ticker[0] : '?',
        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeldrinoAppBar(onRefresh: _loadData, showRefresh: true),
      body: _loading
          ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching balances...'),
              ]))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _holdings.isEmpty
                  ? const Center(child: Text('No wallets added yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _holdings.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFF2A2A4A)),
                      itemBuilder: (context, index) {
                        final coin = _holdings[index];
                        final dp = CoinRegistry.byTicker(coin.ticker)?.decimalPlaces ?? 4;
                        return ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CoinDetailScreen(holding: coin)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: _coinIcon(coin.ticker),
                          title: Text(coin.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Text(coin.wallet,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '${coin.fiatSymbol}${coin.fiatValue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                  '${coin.balance.toStringAsFixed(dp)} ${coin.ticker}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
