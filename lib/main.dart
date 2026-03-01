import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
      return rawBalance / BigInt.from(10).pow(30);
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String address, {int count = 5}) async {
    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'account_history',
        'account': address,
        'count': count.toString(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final history = data['history'];
      if (history is List) {
        return history.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  static double rawToXno(String raw) {
    final rawBalance = BigInt.parse(raw);
    return rawBalance / BigInt.from(10).pow(30);
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

// --- Models ---

class CoinHolding {
  final String name;
  final String ticker;
  final String wallet;
  final String address;
  final double balance;
  final double priceUsd;

  const CoinHolding({
    required this.name,
    required this.ticker,
    required this.wallet,
    required this.address,
    required this.balance,
    required this.priceUsd,
  });

  double get fiatValue => balance * priceUsd;
}

// --- Home Screen ---

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
            address: address,
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
                        return ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoinDetailScreen(holding: coin),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      fontWeight: FontWeight.bold, fontSize: 16)),
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

// --- Coin Detail Screen ---

class CoinDetailScreen extends StatefulWidget {
  final CoinHolding holding;
  const CoinDetailScreen({super.key, required this.holding});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;
  bool _showingAll = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({int count = 5}) async {
    setState(() => _loadingHistory = true);
    final history = await NanoService.getHistory(widget.holding.address, count: count);
    setState(() {
      _history = history;
      _loadingHistory = false;
    });
  }

  String _formatTimestamp(dynamic ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ts.toString()) * 1000);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openInNatrium() async {
    final uri = Uri.parse('nano:${widget.holding.address}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Natrium not installed or not supported on this device')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final holding = widget.holding;
    return Scaffold(
      appBar: AppBar(
        title: Text(holding.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.wallet,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 8),
                Text('${holding.balance.toStringAsFixed(6)} ${holding.ticker}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('\$${holding.fiatValue.toStringAsFixed(2)} USD',
                    style: const TextStyle(fontSize: 18, color: Colors.tealAccent)),
                const SizedBox(height: 4),
                Text('1 ${holding.ticker} = \$${holding.priceUsd.toStringAsFixed(4)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Wallet address
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    holding.address,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.tealAccent, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: holding.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Open in Natrium button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInNatrium,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Natrium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Transaction history
          const Text('Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            Text('No transactions found',
                style: TextStyle(color: Colors.white.withOpacity(0.5)))
          else ...[
            ..._history.map((tx) {
              final isReceive = tx['type'] == 'receive';
              final amount = NanoService.rawToXno(tx['amount'].toString());
              final time = _formatTimestamp(tx['local_timestamp']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isReceive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isReceive ? Colors.greenAccent : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReceive ? 'Received' : 'Sent',
                            style: TextStyle(
                              color: isReceive ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(time,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '${isReceive ? '+' : '-'}${amount.toStringAsFixed(4)} XNO',
                      style: TextStyle(
                        color: isReceive ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!_showingAll)
              TextButton(
                onPressed: () {
                  setState(() => _showingAll = true);
                  _loadHistory(count: 50);
                },
                child: const Text('Show all transactions',
                    style: TextStyle(color: Colors.tealAccent)),
              ),
          ],
        ],
      ),
    );
  }
}