// FULL FILE: home_screen.dart
// Debug logging enabled (full)
// Deletes and recreates C:/meldrino_app/debug.log at startup

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_holding.dart';
import 'nano_service.dart';
import 'price_service.dart';
import 'manage_wallets_screen.dart';
import 'app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CoinHolding> _holdings = [];
  bool _loading = true;

  final File _logFile = File('C:/meldrino_app/debug.log');

  void _log(String msg) {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[HOME] $timestamp $msg\n';
    try {
      _logFile.writeAsStringSync(line, mode: FileMode.append);
    } catch (_) {}
    // ignore: avoid_print
    print(line);
  }

  @override
  void initState() {
    super.initState();

    // Rotate log file
    try {
      if (_logFile.existsSync()) {
        _logFile.deleteSync();
      }
      _logFile.writeAsStringSync('');
    } catch (_) {}

    _log('=== Meldrino HomeScreen started ===');

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];

    _log('Loaded raw wallet list: $wallets');

    final List<CoinHolding> holdings = [];

    for (final w in wallets) {
      _log('Raw wallet entry: "$w"');

      final parts = w.split('|');
      if (parts.length != 3) {
        _log('ERROR: Invalid wallet entry format: "$w"');
        continue;
      }

      final coin = parts[0];
      final label = parts[1].isNotEmpty ? parts[1] : parts[0];
      final address = parts[2].trim();

      _log('Parsed coin="$coin" label="$label" address="$address" len=${address.length}');
      double balance = 0;

      if (coin.contains('Nano')) {
        _log('Calling NanoService.getBalance("$address")');
        balance = await NanoService.getBalance(address);
        _log('NanoService returned balance: $balance');
      }

      final price = await PriceService.getPrice(coin);
      _log('PriceService returned price: $price');

      holdings.add(
        CoinHolding(
          coin: coin,
          label: label,
          address: address,
          balance: balance,
          price: price,
        ),
      );
    }

    setState(() {
      _holdings = holdings;
      _loading = false;
    });

    _log('Finished loading holdings.');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeldrinoAppBar(onRefresh: _loadData),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _holdings.length,
              itemBuilder: (context, index) {
                final h = _holdings[index];

                return ListTile(
                  title: Text(
                    h.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${h.coin} • ${h.address.substring(0, 20)}...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        h.balance.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${(h.balance * h.price).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManageWalletsScreen(),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
}

