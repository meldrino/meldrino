import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'coin_registry.dart';
import 'wallet_registry.dart';
import 'home_screen.dart';

class ManageWalletsScreen extends StatefulWidget {
  final bool isFirstTime;
  const ManageWalletsScreen({super.key, this.isFirstTime = false});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  List<String> _wallets = [];
  final _addressController = TextEditingController();
  final _customLabelController = TextEditingController();

  late String _selectedCoin;
  String? _selectedWalletLabel;
  bool _showCustomLabel = false;

  @override
  void initState() {
    super.initState();
    _selectedCoin = CoinRegistry.coinLabels.first;
    _resetWalletDropdown();
    _loadWallets();
  }

  void _resetWalletDropdown() {
    final options = _walletsForCoin(_selectedCoin);
    _selectedWalletLabel = options.isNotEmpty ? options.first : null;
    _showCustomLabel = _selectedWalletLabel == 'Custom...';
    _customLabelController.clear();
  }

  List<String> _walletsForCoin(String coinLabel) {
    final tickerMatch = RegExp(r'\(([^)]+)\)').firstMatch(coinLabel);
    if (tickerMatch == null) return ['Custom...'];
    final ticker = tickerMatch.group(1)!.toUpperCase();

    List<WalletCoin> coins;
    switch (ticker) {
      case 'XNO':
        coins = [WalletCoin.xno];
        break;
      case 'ETH':
        coins = [WalletCoin.eth, WalletCoin.multi];
        break;
      case 'SATS':
        coins = [WalletCoin.btcLightning, WalletCoin.multi];
        break;
      case 'BTC':
        coins = [WalletCoin.btc, WalletCoin.multi];
        break;
      case 'SOL':
        coins = [WalletCoin.sol, WalletCoin.multi];
        break;
      case 'XRP':
        coins = [WalletCoin.xrp];
        break;
      case 'XMR':
        coins = [WalletCoin.xmr];
        break;
      case 'WOW':
        coins = [WalletCoin.wow];
        break;
      case 'BAN':
        coins = [WalletCoin.ban];
        break;
      case 'MATIC':
        coins = [WalletCoin.multi];
        break;
      default:
        coins = [];
    }

    final names = WalletRegistry.all
        .where((w) => w.coins.any((c) => coins.contains(c)))
        .map((w) => w.name)
        .toList();
    names.add('Custom...');
    return names;
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallets = prefs.getStringList('wallets') ?? [];
    });
  }

  Future<void> _addWallet() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address')),
      );
      return;
    }

    final label = _showCustomLabel
        ? _customLabelController.text.trim()
        : (_selectedWalletLabel ?? '');

    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    wallets.add('$_selectedCoin|$label|$address');
    await prefs.setStringList('wallets', wallets);

    _addressController.clear();
    _customLabelController.clear();
    await _loadWallets();

    if (!mounted) return;

    if (widget.isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    // Success dialog
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Wallet added!'),
        content: const Text('Your wallet has been saved.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Add Another Coin',
                style: TextStyle(color: Colors.tealAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: const Text('Go to Home Screen',
                style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWallet(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Remove wallet?'),
        content: const Text(
            'This will remove the wallet from Meldrino. Your funds are safe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final wallets = prefs.getStringList('wallets') ?? [];
      wallets.removeAt(index);
      await prefs.setStringList('wallets', wallets);
      await _loadWallets();
    }
  }

  Future<void> _editWallet(int index) async {
    final parts = _wallets[index].split('|');
    final labelController = TextEditingController(text: parts[1]);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Edit wallet label'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(hintText: 'Label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final wallets = prefs.getStringList('wallets') ?? [];
              wallets[index] =
                  '${parts[0]}|${labelController.text.trim()}|${parts[2]}';
              await prefs.setStringList('wallets', wallets);
              await _loadWallets();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = _walletsForCoin(_selectedCoin);

    return Scaffold(
      appBar: widget.isFirstTime
          ? AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Meldrino',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            )
          : MeldrinoAppBar(onRefresh: _loadWallets),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isFirstTime) ...[
              const Text('Welcome to Meldrino',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Add a wallet address to get started. Your address is read-only — we never ask for your seed or private key.',
                style:
                    TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Wallet',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Coin dropdown — driven by CoinRegistry
                  DropdownButtonFormField<String>(
                    value: _selectedCoin,
                    dropdownColor: const Color(0xFF16213E),
                    decoration: const InputDecoration(labelText: 'Coin'),
                    items: CoinRegistry.coinLabels
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCoin = v!;
                        _resetWalletDropdown();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Wallet dropdown filtered by coin
                  DropdownButtonFormField<String>(
                    value: _selectedWalletLabel,
                    dropdownColor: const Color(0xFF16213E),
                    decoration: const InputDecoration(labelText: 'Wallet'),
                    items: walletOptions
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedWalletLabel = v;
                        _showCustomLabel = v == 'Custom...';
                        if (!_showCustomLabel) _customLabelController.clear();
                      });
                    },
                  ),
                  if (_showCustomLabel) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customLabelController,
                      decoration: const InputDecoration(
                          labelText: 'Custom label (optional)',
                          hintText: 'e.g. My main wallet'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration:
                        const InputDecoration(labelText: 'Wallet Address'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Wallet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_wallets.isNotEmpty) ...[
              const Text('Saved Wallets',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _wallets.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFF2A2A4A)),
                  itemBuilder: (context, index) {
                    final parts = _wallets[index].split('|');
                    final coin = parts[0];
                    final label = parts[1].isNotEmpty ? parts[1] : coin;
                    final address = parts[2];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(label,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '$coin • ${address.length > 20 ? '${address.substring(0, 20)}...' : address}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.tealAccent, size: 20),
                            onPressed: () => _editWallet(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteWallet(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
