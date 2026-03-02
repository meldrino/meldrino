import 'dart:io';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'wallet_registry.dart';

class WalletDetector {
  /// Returns wallets from the registry that are installed on this device.
  /// On non-Android platforms, always returns an empty list.
  static Future<List<WalletDefinition>> getInstalledWallets() async {
    if (!Platform.isAndroid) return [];

    try {
      final installed = await FlutterDeviceApps.listApps(
        includeSystem: false,
        onlyLaunchable: true,
        includeIcons: false,
      );

      final installedPackages = installed
          .map((a) => a.packageName)
          .whereType<String>()
          .toSet();

      return WalletRegistry.all
          .where((w) =>
              w.androidPackage != null &&
              installedPackages.contains(w.androidPackage))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
