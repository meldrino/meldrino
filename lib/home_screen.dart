import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_holding.dart';
import 'nano_service.dart';
import 'eth_service.dart';
import 'zbd_service.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final wallets = prefs.getStringList('wallets') ?? [];
      final fiatCurrency = prefs.getString('fiatCurrency') ?? 'USD';
      final prices = await PriceService.getPrices(fiatCurrency);
      final xnoPrice = prices['xno'] ?? 0;
      final ethPrice = prices['eth'] ?? 0;
      final btcPrice = prices['btc'] ?? 0;
      final List<CoinHolding> holdings = [];

      for (final w in wallets) {
        final parts = w.split('|');
        final coin = parts[0];
        final label = parts[1].isNotEmpty ? parts[1] : parts[0];
        final address = parts[2];

        if (coin.contains('Nano')) {
          final balance = await NanoService.getBalance(address);
          holdings.add(CoinHolding(
            name: 'Nano',
            ticker: 'XNO',
            wallet: label,
            address: address,
            balance: balance,
            priceUsd: xnoPrice,
            fiatCurrency: fiatCurrency,
            fiatSymbol: _fiatSymbol(fiatCurrency),
          ));
        } else if (coin.contains('Ethereum')) {
          final balance = await EthService.getBalance(address);
          holdings.add(CoinHolding(
            name: 'Ethereum',
            ticker: 'ETH',
            wallet: label,
            address: address,
            balance: balance,
            priceUsd: ethPrice,
            fiatCurrency: fiatCurrency,
            fiatSymbol: _fiatSymbol(fiatCurrency),
          ));
        } else if (coin.contains('Satoshi')) {
          if (address == 'zbd') {
            try {
              final sats = await ZbdService.getBalanceSats();
              holdings.add(CoinHolding(
                name: 'Bitcoin (Lightning)',
                ticker: 'SATS',
                wallet: label,
                address: address,
                balance: sats.toDouble(),
                priceUsd: btcPrice / 100000000,
                fiatCurrency: fiatCurrency,
                fiatSymbol: _fiatSymbol(fiatCurrency),
              ));
            } catch (_) {
              // ZBD token expired or not connected — skip silently
            }
          }
        }
      }

      holdings.sort((a, b) => b.fiatValue.compareTo(a.fiatValue));
      setState(() {
        _holdings = holdings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  String _coinIcon(String ticker) {
    switch (ticker) {
      case 'XNO': return 'assets/icons/nano.png';
      case 'ETH': return 'assets/icons/ethereum.png';
      case 'SATS': return 'assets/icons/sats.png';
      default: return '';
    }
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
                  Text('Fetching balances...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)))
              : _holdings.isEmpty
                  ? const Center(child: Text('No wallets added yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _holdings.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFF2A2A4A)),
                      itemBuilder: (context, index) {
                        final coin = _holdings[index];
                        final iconPath = _coinIcon(coin.ticker);
                        return ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoinDetailScreen(holding: coin),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2A2A4A),
                            backgroundImage: iconPath.isNotEmpty
                                ? AssetImage(iconPath)
                                : null,
                            child: iconPath.isEmpty
                                ? Text(coin.ticker[0],
                                    style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                  '${coin.balance.toStringAsFixed(4)} ${coin.ticker}',
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