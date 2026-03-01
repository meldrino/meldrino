import 'package:flutter/material.dart';
import 'manage_wallets_screen.dart';
import 'settings_screen.dart';

class MeldrinoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final bool showRefresh;
  final bool showHome;

  const MeldrinoAppBar({
    super.key,
    required this.onRefresh,
    this.showRefresh = false,
    this.showHome = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        child: const Text(
          'Meldrino',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
      actions: [
        if (showHome)
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        if (showRefresh)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh balances',
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