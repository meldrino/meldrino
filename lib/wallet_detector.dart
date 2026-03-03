import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'wallet_registry.dart';

class DetectedWallet {
  final WalletDefinition definition;
  final Uint8List? iconBytes;

  const DetectedWallet({required this.definition, this.iconBytes});
}

class WalletDetector {
  static Future<List<DetectedWallet>> getInstalledWallets() async {
    if (!Platform.isAndroid) return [];

    try {
      // Get the list of installed apps with icons in one call
      final installed = await FlutterDeviceApps.listApps(
        includeSystem: false,
        onlyLaunchable: true,
        includeIcons: true,
      );

      // Build a map of packageName -> iconBytes
      final iconMap = <String, Uint8List?>{};
      for (final app in installed) {
        if (app.packageName != null) {
          Uint8List? bytes;
          try {
            bytes = (app as dynamic).iconBytes as Uint8List?;
          } catch (_) {}
          if (bytes == null) {
            try {
              bytes = (app as dynamic).icon as Uint8List?;
            } catch (_) {}
          }
          iconMap[app.packageName!] = bytes;
        }
      }

      final installedPackages = iconMap.keys.toSet();

      final matched = WalletRegistry.all
          .where((w) =>
              w.androidPackage != null &&
              installedPackages.contains(w.androidPackage))
          .toList();

      return matched
          .map((def) => DetectedWallet(
                definition: def,
                iconBytes: iconMap[def.androidPackage],
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
