import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_holding.dart';
import 'nano_service.dart';
import 'price_service.dart';
import 'app_bar.dart';
import 'coin_detail_screen.dart';
import 'zbd_service.dart';

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
      final btcPrice = prices['btc'] ?? 0;
      final List<CoinHolding> holdings = [];

      // Non-custodial wallets
      for (final w in wallets) {
        final parts = w.split('|');
        final coin = parts[0];
        final label = parts[1].isNotEmpty ? parts[1] : parts[0];
        final address = parts[2];

        // Bitcoin Lightning is handled separately via ZBD JWT token
        if (coin.contains('Bitcoin Lightning')) continue;

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
        }
      }

      // ZBD custodial wallet
      final zbdToken = await ZbdService.getStoredToken();
      print('[HOME] ZBD token check: ${zbdToken != null ? "TOKEN FOUND (${zbdToken.substring(0, 10)}...)" : "NO TOKEN"}');
      if (zbdToken != null) {
        try {
          final zbdSats = await ZbdService.getBalanceSats();
          final zbdBtc = zbdSats / 100000000;
          holdings.add(CoinHolding(
            name: 'Bitcoin Lightning',
            ticker: 'BTC',
            wallet: 'ZBD',
            address: 'zbd',
            balance: zbdBtc,
            priceUsd: btcPrice,
            fiatCurrency: fiatCurrency,
            fiatSymbol: _fiatSymbol(fiatCurrency),
          ));
        } catch (e) {
          // ZBD token may be expired — just skip it silently
          print('[HOME] ZBD balance fetch failed: $e');
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
                        return ListTile(
                          onTap: () => Navigator.push(
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
                              coin.ticker == 'BTC' ? '₿' : 'N',
                              style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(coin.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
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
                                  coin.ticker == 'BTC'
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
