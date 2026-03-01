import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_holding.dart';
import 'nano_service.dart';
import 'price_service.dart';
import 'zbd_service.dart';
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
      final symbol = _fiatSymbol(fiatCurrency);
      final prices = await PriceService.getPrices(fiatCurrency);
      final xnoPrice = prices['xno'] ?? 0;
      final btcPrice = prices['btc'] ?? 0;
      final List<CoinHolding> holdings = [];

      // Nano wallets
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
            fiatSymbol: symbol,
          ));
        }
      }

      // ZBD wallet (Bitcoin sats)
      final zbdToken = await ZbdService.getStoredToken();
      if (zbdToken != null) {
        try {
          final sats = await ZbdService.getBalanceSats();
          final username = await ZbdService.getUsername();
          final btcBalance = sats / 100000000; // sats to BTC
          holdings.add(CoinHolding(
            name: 'Bitcoin (ZBD)',
            ticker: 'BTC',
            wallet: '@$username',
            address: '',
            balance: btcBalance,
            priceUsd: btcPrice,
            fiatCurrency: fiatCurrency,
            fiatSymbol: symbol,
          ));
        } catch (e) {
          // Token may have expired — silently skip, user can reconnect from wallets screen
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
                        final isZbd = coin.ticker == 'BTC';
                        return ListTile(
                          onTap: isZbd
                              ? null // ZBD detail screen not yet built
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CoinDetailScreen(holding: coin),
                                    ),
                                  ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2A2A4A),
                            child: Text(
                              isZbd ? '₿' : 'N',
                              style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold),
                            ),
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
                                  isZbd
                                      ? '${(coin.balance * 100000000).toStringAsFixed(0)} sats'
                                      : '${coin.balance.toStringAsFixed(4)} ${coin.ticker}',
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
