import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
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
  List<WalletDefinition> _installedWallets = [];
  Map<String, Uint8List?> _icons = {};
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

    final Map<String, Uint8List?> icons = {};
    try {
      final apps = await FlutterDeviceApps.listApps(
        includeSystem: false,
        onlyLaunchable: true,
        includeIcons: true,
      );
      for (final app in apps) {
        if (app.packageName != null) {
          icons[app.packageName!] = app.iconBytes;
        }
      }
    } catch (_) {}

    setState(() {
      _installedWallets = installed;
      _icons = icons;
      _loadingWallets = false;
    });
  }

  String _coinLabel(WalletDefinition wallet) {
    if (wallet.coins.length == 1) {
      return WalletRegistry.coinLabel(wallet.coins.first);
    }
    return wallet.coins.map((c) => WalletRegistry.coinLabel(c)).join(', ');
  }

  /// Returns the storage key that home_screen.dart can recognise.
  /// home_screen checks coin.contains('Nano') for XNO wallets.
  String _coinStorageKey(WalletDefinition wallet) {
    final coin = wallet.coins.firstWhere(
      (c) => c != WalletCoin.multi,
      orElse: () => wallet.coins.first,
    );
    switch (coin) {
      case WalletCoin.xno: return 'Nano (XNO)';
      case WalletCoin.ban: return 'Banano (BAN)';
      case WalletCoin.btc: return 'Bitcoin (BTC)';
      case WalletCoin.btcLightning: return 'Bitcoin Lightning (BTC)';
      case WalletCoin.eth: return 'Ethereum (ETH)';
      case WalletCoin.sol: return 'Solana (SOL)';
      case WalletCoin.xrp: return 'XRP (XRP)';
      case WalletCoin.xmr: return 'Monero (XMR)';
      case WalletCoin.wow: return 'Wownero (WOW)';
      default: return wallet.name;
    }
  }

  Widget _walletIcon(WalletDefinition wallet, {bool dimmed = false}) {
    final pkg = wallet.androidPackage;
    if (pkg != null && _icons.containsKey(pkg) && _icons[pkg] != null) {
      return CircleAvatar(
        backgroundColor: const Color(0xFF2A2A4A),
        backgroundImage: MemoryImage(_icons[pkg]!),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF2A2A4A),
      child: Text(
        wallet.name[0],
        style: TextStyle(
          color: dimmed ? Colors.white38 : Colors.tealAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddAddressDialog(WalletDefinition wallet) {
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

  List<WalletDefinition> get _notInstalledWallets {
    final installedNames = _installedWallets.map((w) => w.name).toSet();
    return WalletRegistry.all
        .where((w) => !installedNames.contains(w.name))
        .toList();
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
      body: _loadingWallets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Saved wallets
                  if (_wallets.isNotEmpty) ...[
                    const Text('Saved Wallets',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_wallets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final parts = entry.value.split('|');
                      final coin = parts[0];
                      final label =
                          parts[1].isNotEmpty ? parts[1] : coin;
                      final address = parts[2];
                      return Column(
                        children: [
                          if (index > 0)
                            const Divider(
                                height: 1, color: Color(0xFF2A2A4A)),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2A2A4A),
                              child: Text(
                                label[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
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
                        ],
                      );
                    })),
                    const SizedBox(height: 24),
                  ],

                  // Installed wallets
                  if (_installedWallets.isNotEmpty) ...[
                    const Text('Installed Wallets',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_installedWallets.map((wallet) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _walletIcon(wallet),
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
                    const SizedBox(height: 24),
                  ],

                  // Other wallets
                  const Text('Other Wallets',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(_notInstalledWallets.map((wallet) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _walletIcon(wallet, dimmed: true),
                        title: Text(wallet.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.5))),
                        subtitle: Text(_coinLabel(wallet),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13)),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: Colors.white24),
                        onTap: () => _showAddAddressDialog(wallet),
                      ))),
                ],
              ),
            ),
    );
  }
}
