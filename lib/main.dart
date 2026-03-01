import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          surface: Color(0xFF1A1A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
          ),
        ),
      ),
      home: const StartupRouter(),
    );
  }
}

class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    if (!mounted) return;
    if (wallets.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AddWalletScreen(isFirstTime: true)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class AddWalletScreen extends StatefulWidget {
  final bool isFirstTime;
  const AddWalletScreen({super.key, this.isFirstTime = false});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  String _selectedCoin = 'Nano (XNO)';
  bool _saving = false;

  final List<String> _supportedCoins = ['Nano (XNO)'];

  Future<void> _saveWallet() async {
    final address = _addressController.text.trim();
    final label = _labelController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address')),
      );
      return;
    }

    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    wallets.add('$_selectedCoin|$label|$address');
    await prefs.setStringList('wallets', wallets);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Add Your First Wallet' : 'Add Wallet'),
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isFirstTime) ...[
              const Text(
                'Welcome to Meldrino',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a wallet address to get started. Your address is read-only — we never ask for your seed or private key.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 32),
            ],
            const Text('Coin', style: TextStyle(fontSize: 14, color: Colors.tealAccent)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCoin,
              dropdownColor: const Color(0xFF16213E),
              decoration: const InputDecoration(),
              items: _supportedCoins
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCoin = v!),
            ),
            const SizedBox(height: 24),
            const Text('Label (optional)', style: TextStyle(fontSize: 14, color: Colors.tealAccent)),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(hintText: 'e.g. Natrium, My main wallet'),
            ),
            const SizedBox(height: 24),
            const Text('Wallet Address', style: TextStyle(fontSize: 14, color: Colors.tealAccent)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: 'Paste your public address here'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Add Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- API Services ---

class NanoService {
  static const String _apiKey = '3biV6K9bbvp40bdoCOAQnmLpc2anmUQwlYD7ZNQzSmlMDnROQuNUPafbECsFhc5aM';
  static const String _rpcUrl = 'https://nodes.nanswap.com/XNO?api_key=$_apiKey';

  static Future<double> getBalance(String address) async {
    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'account_balance', 'account': address}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawBalance = BigInt.parse(data['balance'] ?? '0');
      // Convert from raw to XNO (1 XNO = 10^30 raw)
      final xno = rawBalance / BigInt.from(10).pow(30);
      return xno;
    }
    return 0;
  }
}

class PriceService {
  static Future<double> getXnoPrice() async {
    final response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=nano&vs_currencies=usd',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['nano']['usd'] as num).toDouble();
    }
    return 0;
  }
}

// --- Home Screen ---

class CoinHolding {
  final String name;
  final String ticker;
  final String wallet;
  final double balance;
  final double priceUsd;

  const CoinHolding({
    required this.name,
    required this.ticker,
    required this.wallet,
    required this.balance,
    required this.priceUsd,
  });

  double get fiatValue => balance * priceUsd;
}

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

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final wallets = prefs.getStringList('wallets') ?? [];
      final xnoPrice = await PriceService.getXnoPrice();
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
            balance: balance,
            priceUsd: xnoPrice,
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
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meldrino',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddWalletScreen()),
            ).then((_) => _loadData()),
          ),
        ],
      ),
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
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                )
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF2A2A4A),
                            child: Text('N',
                                style: TextStyle(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold)),
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
                              Text('\$${coin.fiatValue.toStringAsFixed(2)}',
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