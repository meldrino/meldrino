import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'home_screen.dart';
import 'coin_registry.dart';
import 'wallet_registry.dart';
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
  final _customWalletController = TextEditingController();
  late String _selectedCoinLabel;
  String? _selectedWalletName;
  bool _isCustomWallet = false;

  @override
  void initState() {
    super.initState();
    _selectedCoinLabel = CoinRegistry.coinLabels.first;
    _loadWallets();
  }

  get _selectedAdapter =>
      CoinRegistry.fromWalletEntry('$_selectedCoinLabel||placeholder');

  /// Wallet names relevant to the currently selected coin.
  List<String> get _walletsForCoin {
    final ticker = _selectedAdapter?.ticker ?? '';
    final coinMatches = <WalletCoin>[];
    switch (ticker) {
      case 'XNO': coinMatches.add(WalletCoin.xno); break;
      case 'ETH': coinMatches.addAll([WalletCoin.eth, WalletCoin.multi]); break;
      case 'SATS': coinMatches.addAll([WalletCoin.btcLightning, WalletCoin.multi]); break;
      case 'BTC': coinMatches.addAll([WalletCoin.btc, WalletCoin.multi]); break;
      case 'SOL': coinMatches.addAll([WalletCoin.sol, WalletCoin.multi]); break;
      case 'XRP': coinMatches.add(WalletCoin.xrp); break;
      case 'XMR': coinMatches.add(WalletCoin.xmr); break;
      case 'WOW': coinMatches.add(WalletCoin.wow); break;
      case 'BAN': coinMatches.add(WalletCoin.ban); break;
    }
    if (coinMatches.isEmpty) return [];
    return WalletRegistry.all
        .where((w) => w.coins.any((c) => coinMatches.contains(c)))
        .map((w) => w.name)
        .toList();
  }

  String get _effectiveWalletLabel {
    if (_isCustomWallet) return _customWalletController.text.trim();
    return _selectedWalletName ?? '';
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallets = prefs.getStringList('wallets') ?? [];
    });
  }

  void _onCoinChanged(String newCoin) {
    setState(() {
      _selectedCoinLabel = newCoin;
      _selectedWalletName = null;
      _isCustomWallet = false;
      _customWalletController.clear();
    });
  }

  Future<void> _addWallet() async {
    final adapter = _selectedAdapter;
    if (adapter == null) return;

    if (adapter.isCustodial) {
      _handleCustodialConnect(adapter.ticker);
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address')),
      );
      return;
    }

    if (_effectiveWalletLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a wallet name')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    wallets.add('$_selectedCoinLabel|$_effectiveWalletLabel|$address');
    await prefs.setStringList('wallets', wallets);

    _addressController.clear();
    _customWalletController.clear();
    setState(() {
      _selectedWalletName = null;
      _isCustomWallet = false;
    });
    await _loadWallets();

    if (widget.isFirstTime && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      _showSuccessScreen(adapter.name);
    }
  }

  void _showSuccessScreen(String coinName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.check_circle_outline,
                color: Colors.tealAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Wallet added successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$coinName is now being tracked.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedCoinLabel = CoinRegistry.coinLabels.first;
                    _selectedWalletName = null;
                    _isCustomWallet = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Another Coin',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.tealAccent,
                  side: const BorderSide(color: Colors.tealAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to Home Screen',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCustodialConnect(String ticker) {
    if (ticker == 'SATS') {
      final alreadyConnected = _wallets.any((w) {
        final parts = w.split('|');
        return parts.length >= 3 && parts[2] == 'zbd';
      });
      if (alreadyConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ZBD is already connected')),
        );
        return;
      }
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
              if (mounted) _showSuccessScreen('Satoshi (ZBD)');
            },
          ),
        ),
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
    final adapter = _selectedAdapter;
    final isCustodial = adapter?.isCustodial ?? false;
    final walletOptions = _walletsForCoin;

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
                    value: _selectedCoinLabel,
                    dropdownColor: const Color(0xFF16213E),
                    decoration: const InputDecoration(labelText: 'Coin'),
                    items: CoinRegistry.coinLabels
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => _onCoinChanged(v!),
                  ),
                  const SizedBox(height: 12),

                  if (isCustodial) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${adapter?.name} uses OAuth — tap Connect to link your account.',
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[

                    // Wallet dropdown filtered by selected coin
                    if (walletOptions.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _isCustomWallet
                            ? '__custom__'
                            : _selectedWalletName,
                        dropdownColor: const Color(0xFF16213E),
                        decoration:
                            const InputDecoration(labelText: 'Wallet'),
                        hint: const Text('Select wallet app'),
                        items: [
                          ...walletOptions.map((w) => DropdownMenuItem(
                                value: w,
                                child: Text(w),
                              )),
                          const DropdownMenuItem(
                            value: '__custom__',
                            child: Text('Custom...',
                                style: TextStyle(
                                    color: Colors.tealAccent)),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == '__custom__') {
                              _isCustomWallet = true;
                              _selectedWalletName = null;
                            } else {
                              _isCustomWallet = false;
                              _selectedWalletName = v;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Custom wallet name field — only visible when Custom is selected
                    if (_isCustomWallet) ...[
                      TextField(
                        controller: _customWalletController,
                        decoration: const InputDecoration(
                          labelText: 'Wallet name',
                          hintText: 'e.g. My hardware wallet',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Address field
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Wallet Address'),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                      child: Text(
                        isCustodial
                            ? 'Connect ${adapter?.name}'
                            : 'Add Wallet',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_wallets.isNotEmpty) ...[
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
                    final isCustodialEntry = address == 'zbd';
                    final shortAddress = isCustodialEntry
                        ? 'Connected via OAuth'
                        : (address.length > 20
                            ? '${address.substring(0, 20)}...'
                            : address);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '$coin • $shortAddress',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCustodialEntry)
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
