import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'home_screen.dart';
import 'wallet_registry.dart';
import 'wallet_detector.dart';

class ManageWalletsScreen extends StatefulWidget {
  final bool isFirstTime;
  const ManageWalletsScreen({super.key, this.isFirstTime = false});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  List<String> _wallets = [];
  var _installedWallets = [];
  bool _loadingWallets = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadInstalledWallets();
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallets = prefs.getStringList('wallets') ?? [];
    });
  }

  Future<void> _loadInstalledWallets() async {
    final installed = await WalletDetector.getInstalledWallets();
    setState(() {
      _installedWallets = installed;
      _loadingWallets = false;
    });
  }

  String _coinLabel(dynamic wallet) {
    if (wallet.coins.length == 1) {
      return WalletRegistry.coinLabel(wallet.coins.first);
    }
    return (wallet.coins as List).map((c) => WalletRegistry.coinLabel(c)).join(', ');
  }

  String _coinStorageKey(dynamic wallet) {
    final coin = (wallet.coins as List).firstWhere(
      (c) => c != WalletCoin.multi,
      orElse: () => wallet.coins.first,
    );
    return '${wallet.name} (${WalletRegistry.coinLabel(coin)})';
  }

  void _showAddAddressDialog(dynamic wallet) {
    final addressController = TextEditingController();
    String? addressError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> handleAdd() async {
              final address = addressController.text.trim();

              if (address.isEmpty) {
                setDialogState(() => addressError = 'Please enter an address');
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final wallets = prefs.getStringList('wallets') ?? [];
              final storageKey = _coinStorageKey(wallet);
              wallets.add('$storageKey|${wallet.name}|$address');
              await prefs.setStringList('wallets', wallets);
              await _loadWallets();

              if (ctx.mounted) Navigator.pop(ctx);

              if (widget.isFirstTime && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: Text('Add ${wallet.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your ${_coinLabel(wallet)} address',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Wallet Address',
                      errorText: addressError,
                    ),
                    onChanged: (_) {
                      if (addressError != null) {
                        setDialogState(() => addressError = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: handleAdd,
                  child: const Text('Add',
                      style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            );
          },
        );
      },
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
            const Text('Your Installed Wallets',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_loadingWallets)
              const Center(child: CircularProgressIndicator())
            else if (_installedWallets.isEmpty)
              Text(
                'No supported wallets detected on this device.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14),
              )
            else
              ...(_installedWallets.map((wallet) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2A2A4A),
                      child: Icon(Icons.account_balance_wallet,
                          color: Colors.tealAccent, size: 20),
                    ),
                    title: Text(wallet.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(_coinLabel(wallet),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13)),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: Colors.tealAccent),
                    onTap: () => _showAddAddressDialog(wallet),
                  ))),
            if (_wallets.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Saved Wallets',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _wallets.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFF2A2A4A)),
                  itemBuilder: (context, index) {
                    final parts = _wallets[index].split('|');
                    final coin = parts[0];
                    final label =
                        parts[1].isNotEmpty ? parts[1] : coin;
                    final address = parts[2];
                    return ListTile(
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
