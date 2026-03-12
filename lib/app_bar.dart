import 'package:flutter/material.dart';
import 'manage_wallets_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class MeldrinoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final bool showRefresh;

  const MeldrinoAppBar({
    super.key,
    required this.onRefresh,
    this.showRefresh = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Meldrino',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18),
          ),
          Text(
            'not another wallet',
            style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        if (showRefresh)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh balances',
          ),
        IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          ),
        ),
        // NFT placeholder — will link to NFT screen in a future session
        IconButton(
          icon: const Icon(Icons.image_outlined),
          tooltip: 'NFTs (coming soon)',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('NFT support coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          tooltip: 'Manage wallets',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageWalletsScreen()),
          ).then((_) => onRefresh()),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ).then((_) => onRefresh()),
        ),
      ],
    );
  }
}
