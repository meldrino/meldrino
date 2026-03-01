import 'package:flutter/material.dart';

void main() {
  runApp(const MeldrinoApp());
}

class MeldrinoApp extends StatelessWidget {
  const MeldrinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meldrino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          surface: const Color(0xFF1A1A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class CoinHolding {
  final String name;
  final String ticker;
  final String wallet;
  final double balance;
  final double priceUsd;
  final String iconUrl;
  final bool multiWallet;

  const CoinHolding({
    required this.name,
    required this.ticker,
    required this.wallet,
    required this.balance,
    required this.priceUsd,
    required this.iconUrl,
    this.multiWallet = false,
  });

  double get fiatValue => balance * priceUsd;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Hardcoded for Phase 2 — will be replaced with live API data
  static const List<CoinHolding> holdings = [
    CoinHolding(
      name: 'Nano',
      ticker: 'XNO',
      wallet: 'My Nano Wallet',
      balance: 250.0,
      priceUsd: 1.10,
      iconUrl: 'https://cryptologos.cc/logos/nano-xno-logo.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = [...holdings]..sort((a, b) => b.fiatValue.compareTo(a.fiatValue));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meldrino',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF2A2A4A)),
        itemBuilder: (context, index) {
          final coin = sorted[index];
          return CoinRow(coin: coin);
        },
      ),
    );
  }
}

class CoinRow extends StatelessWidget {
  final CoinHolding coin;

  const CoinRow({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2A2A4A),
        child: Image.network(
          coin.iconUrl,
          width: 28,
          height: 28,
          errorBuilder: (_, __, ___) => Text(
            coin.ticker[0],
            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Text(
        coin.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        coin.wallet,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (coin.multiWallet)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  // TODO: show wallet breakdown
                },
                child: const Icon(Icons.account_balance_wallet, color: Colors.orangeAccent, size: 20),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${coin.fiatValue.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                coin.ticker,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}