import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'home_screen.dart';
import 'wallet_detector.dart';
import 'wallet_registry.dart';

class ManageWalletsScreen extends StatefulWidget {
  final bool isFirstTime;
  const ManageWalletsScreen({super.key, this.isFirstTime = false});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  List<String> _wallets = [];
  List<WalletDefinition> _detectedWallets = [];
  bool _scanning = true;

  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  String _selectedCoin = 'Nano (XNO)';
  final List<String> _supportedCoins = ['Nano (XNO)'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadWallets();
    await _scanForWallets();
  }

  Future<void> _scanForWallets() async {
    setState(() => _scanning = true);
    final detected = await WalletDetector.getInstalledWallets();
    if (!mounted) return;

    // Filter out wallets the user has already added (by matching label/name)
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('wallets') ?? [];
    final savedLabels = saved.map((w) => w.split('|')[1].toLowerCase()).toSet();

    setState(() {
      _detectedWallets = detected
          .where((w) => !savedLabels.contains(w.name.toLowerCase()))
          .toList();
      _scanning = false;
    });
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallets = prefs.getStringList('wallets') ?? [];
    });
  }

  Future<void> _addDetectedWallet(WalletDefinition walletDef) async {
    final addressController = TextEditingController();
    final primaryCoin = WalletRegistry.coinLabel(walletDef.coins.first);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text('Add ${walletDef.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coin: $primaryCoin',
              style: TextStyle(
                  color: Colors.tealAccent.withOpacity(0.8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Wallet Address',
                hintText: 'Paste your address here',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your address is read-only — we never ask for your seed or private key.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final address = addressController.text.trim();
              if (address.isEmpty) return;

              final prefs = await SharedPreferences.getInstance();
              final wallets = prefs.getStringList('wallets') ?? [];
              wallets.add('${walletDef.name} ($primaryCoin)|${walletDef.name}|$address');
              await prefs.setStringList('wallets', wallets);
              await _loadWallets();

              setState(() {
                _detectedWallets.removeWhere((w) => w.name == walletDef.name);
              });

              if (ctx.mounted) Navigator.pop(ctx);

              if (widget.isFirstTime && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
            child: const Text('Add',
                style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
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
    wallets.add('$_selectedCoin|$label|$address');
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
      await _scanForWallets(); // re-scan so removed wallet reappears in detected
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
          : MeldrinoAppBar(onRefresh: _init),
      body: _scanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.tealAccent),
                  SizedBox(height: 16),
                  Text('Scanning for wallet apps...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (widget.isFirstTime) ...[
                    const Text('Welcome to Meldrino',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Add a wallet address to get started. Your address is read-only — we never ask for your seed or private key.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Detected wallets ──────────────────────────────────
                  if (_detectedWallets.isNotEmpty) ...[
                    const Text('Detected on your phone',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'These wallet apps are installed. Tap Add to enter your address.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ...(_detectedWallets.map((w) => _buildDetectedTile(w))),
                    const SizedBox(height: 24),
                  ],

                  // ── Manual add ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Wallet Manually',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCoin,
                          dropdownColor: const Color(0xFF16213E),
                          decoration:
                              const InputDecoration(labelText: 'Coin'),
                          items: _supportedCoins
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCoin = v!),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _labelController,
                          decoration: const InputDecoration(
                              labelText: 'Label (optional)',
                              hintText: 'e.g. Natrium, My main wallet'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                              labelText: 'Wallet Address'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addWallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Add Wallet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Saved wallets ─────────────────────────────────────
                  if (_wallets.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Saved Wallets',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...List.generate(_wallets.length, (index) {
                      final parts = _wallets[index].split('|');
                      final coin = parts[0];
                      final label =
                          parts[1].isNotEmpty ? parts[1] : coin;
                      final address = parts[2];
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '$coin • ${address.substring(0, 20)}...',
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
                          ),
                          const Divider(
                              height: 1, color: Color(0xFF2A2A4A)),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDetectedTile(WalletDefinition w) {
    final coins = w.coins
        .map((c) => WalletRegistry.coinLabel(c))
        .join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2A2A4A),
          child: Text(
            w.name[0],
            style: const TextStyle(
                color: Colors.tealAccent, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(w.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(coins,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12)),
        trailing: ElevatedButton(
          onPressed: () => _addDetectedWallet(w),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
