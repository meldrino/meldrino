import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'home_screen.dart';
import 'zbd_connect_screen.dart';

class ManageWalletsScreen extends StatefulWidget {
  final bool isFirstTime;
  const ManageWalletsScreen({super.key, this.isFirstTime = false});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  List<String> _wallets = [];
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  String _selectedCoin = 'Nano (XNO)';
  String _selectedWallet = 'Other';

  final List<String> _supportedCoins = ['Nano (XNO)', 'Ethereum (ETH)', 'Satoshi (SATS)'];

  // Wallets per coin — custodial ones are flagged
  static const Map<String, List<String>> _walletsByCoin = {
    'Nano (XNO)': ['Natrium', 'Nautilus', 'Cake Wallet', 'WeNano', 'Other'],
    'Ethereum (ETH)': ['MetaMask', 'Trust Wallet', 'Exodus', 'Rainbow', 'Coinbase Wallet', 'Other'],
    'Satoshi (SATS)': ['ZBD', 'Strike', 'Cash App', 'Other'],
  };

  static const List<String> _custodialWallets = ['ZBD', 'Strike', 'Cash App'];

  bool get _isCustodial => _custodialWallets.contains(_selectedWallet);
  bool get _isZbd => _selectedWallet == 'ZBD';

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  List<String> get _walletsForCoin =>
      _walletsByCoin[_selectedCoin] ?? ['Other'];

  void _onCoinChanged(String? coin) {
    if (coin == null) return;
    final wallets = _walletsByCoin[coin] ?? ['Other'];
    setState(() {
      _selectedCoin = coin;
      _selectedWallet = wallets.first;
      _addressController.clear();
    });
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallets = prefs.getStringList('wallets') ?? [];
    });
  }

  Future<void> _addWallet() async {
    final address = _addressController.text.trim();
    final label = _labelController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    wallets.add('$_selectedCoin|${label.isNotEmpty ? label : _selectedWallet}|$address');
    await prefs.setStringList('wallets', wallets);

    _addressController.clear();
    _labelController.clear();

    await _loadWallets();

    if (widget.isFirstTime && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _addZbdWallet() async {
    // Prevent duplicate ZBD entries
    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    final alreadyExists = wallets.any((w) => w.startsWith('Satoshi (SATS)|') && w.contains('|zbd'));
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ZBD wallet is already connected')),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZbdConnectScreen(
          onConnected: () async {
            final prefs = await SharedPreferences.getInstance();
            final wallets = prefs.getStringList('wallets') ?? [];
            wallets.add('Satoshi (SATS)|ZBD|zbd');
            await prefs.setStringList('wallets', wallets);
            await _loadWallets();
            if (mounted) Navigator.pop(context);
          },
        ),
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
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14),
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Coin dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCoin,
                    dropdownColor: const Color(0xFF16213E),
                    decoration: const InputDecoration(labelText: 'Coin'),
                    items: _supportedCoins
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: _onCoinChanged,
                  ),
                  const SizedBox(height: 12),
                  // Wallet dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedWallet,
                    dropdownColor: const Color(0xFF16213E),
                    decoration: const InputDecoration(labelText: 'Wallet'),
                    items: _walletsForCoin
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedWallet = v!;
                      _addressController.clear();
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Custodial: ZBD connect button
                  if (_isZbd) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.tealAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ZBD is a custodial wallet — connect via OAuth instead of pasting an address.',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addZbdWallet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Connect ZBD',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else if (_isCustodial) ...[
                    // Other custodial wallets — show address field with note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined, color: Colors.amber, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$_selectedWallet is a custodial wallet. Enter your deposit address.',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                          labelText: 'Label (optional)',
                          hintText: 'e.g. My Strike account'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Deposit Address'),
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
                  ] else ...[
                    // Normal non-custodial wallet
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                          labelText: 'Label (optional)',
                          hintText: 'e.g. Natrium, My main wallet'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Wallet Address'),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_wallets.isNotEmpty) ...[
              const Text('Saved Wallets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    final isZbd = address == 'zbd';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        isZbd
                            ? '$coin • Connected via OAuth'
                            : '$coin • ${address.length > 20 ? '${address.substring(0, 20)}...' : address}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isZbd)
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