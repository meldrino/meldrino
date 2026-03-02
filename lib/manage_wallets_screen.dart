import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'home_screen.dart';
import 'wallet_registry.dart';
import 'wallet_detector.dart';
import 'zbd_connect_screen.dart';
import 'zbd_connect_screen.dart';

class ManageWalletsScreen extends StatefulWidget {
  final bool isFirstTime;
  const ManageWalletsScreen({super.key, this.isFirstTime = false});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  List<String> _wallets = [];
  List<WalletDefinition> _installedWallets = [];
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _scanForWallets();
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallets = prefs.getStringList('wallets') ?? [];
    });
  }

  Future<void> _scanForWallets() async {
    setState(() => _scanning = true);
    final found = await WalletDetector.getInstalledWallets();
    setState(() {
      _installedWallets = found;
      _scanning = false;
    });
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
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
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
            child:
                const Text('Save', style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  void _onWalletTapped(WalletDefinition wallet) {
    if (wallet.type == WalletType.custodial) {
      _openCustodialFlow(wallet);
      return;
    }
    if (wallet.coins.length == 1) {
      _showAddressSheet(wallet, wallet.coins.first);
    } else {
      _showCoinPicker(wallet);
    }
  }

  void _openCustodialFlow(WalletDefinition wallet) {
    if (wallet.name == 'ZBD') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ZbdConnectScreen(
            onConnected: () {
              Navigator.pop(context);
              _loadWallets();
            },
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${wallet.name} connection coming soon')),
    );
  }

  void _showCoinPicker(WalletDefinition wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Which coin in ${wallet.name}?',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...wallet.coins.map((coin) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(WalletRegistry.coinLabel(coin)),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.tealAccent),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddressSheet(wallet, coin);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddressSheet(WalletDefinition wallet, WalletCoin coin) {
    final addressController = TextEditingController();
    final labelController =
        TextEditingController(text: wallet.name);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add ${wallet.name} — ${WalletRegistry.coinLabel(coin)}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Wallet Address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: Colors.tealAccent),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      addressController.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final address = addressController.text.trim();
                  if (address.isEmpty) return;
                  final label = labelController.text.trim();
                  final coinStr = WalletRegistry.coinLabel(coin);
                  final prefs = await SharedPreferences.getInstance();
                  final wallets = prefs.getStringList('wallets') ?? [];
                  wallets.add('$coinStr|$label|$address');
                  await prefs.setStringList('wallets', wallets);
                  await _loadWallets();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (widget.isFirstTime && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                },
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Custom Wallet',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Support for custom wallet entry is coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _scanForWallets();
          await _loadWallets();
        },
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.all(16),
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

            // ── Found on your phone ──────────────────────────
            const Text('Found on your phone',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: Colors.tealAccent)),
              )
            else if (_installedWallets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No known wallets found on this device.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
              )
            else
              ..._installedWallets.map((wallet) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2A2A4A),
                      child: Text(
                        wallet.name[0],
                        style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(wallet.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      wallet.coins
                          .map(WalletRegistry.coinLabel)
                          .join(', '),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12),
                    ),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: Colors.tealAccent),
                    onTap: () => _onWalletTapped(wallet),
                  )),

            const SizedBox(height: 24),

            // ── Add custom ───────────────────────────────────
            OutlinedButton.icon(
              onPressed: _showManualAddSheet,
              icon: const Icon(Icons.add, color: Colors.tealAccent),
              label: const Text('Add custom wallet',
                  style: TextStyle(color: Colors.tealAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.tealAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 32),

            // ── Saved wallets ────────────────────────────────
            if (_wallets.isNotEmpty) ...[
              const Text('Saved Wallets',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._wallets.asMap().entries.map((entry) {
                final index = entry.key;
                final parts = entry.value.split('|');
                final coin = parts[0];
                final label =
                    parts[1].isNotEmpty ? parts[1] : parts[0];
                final address = parts[2];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
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
              }),
            ],
          ],
        ),
        ),
          ),
      ),
    );
  }
}
