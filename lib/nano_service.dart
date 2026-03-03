import 'dart:convert';
import 'package:http/http.dart' as http;

class NanoService {
  // FINAL, VERIFIED WORKING ENDPOINT
  static const String _rpcUrl = 'https://rpc.nano.to';

  /// Validate Nano address format
  static bool isValidAddress(String address) {
    final trimmed = address.trim();
    final regex = RegExp(r'^nano_[13456789abcdefghijkmnopqrstuwxyz]{60}$');
    return regex.hasMatch(trimmed);
  }

  /// Get Nano balance in XNO
  static Future<double> getBalance(String address) async {
    try {
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'account_balance',
          'account': address,
        }),
      );

      if (response.statusCode != 200) {
        return 0;
      }

      final data = jsonDecode(response.body);

      // rpc.nano.to returns both RAW and NANO
      if (data.containsKey('balance_nano')) {
        return double.tryParse(data['balance_nano'].toString()) ?? 0.0;
      }

      // Fallback: convert RAW → XNO
      final raw = data['balance'] ?? '0';
      final rawBalance = BigInt.parse(raw);
      return rawBalance / BigInt.from(10).pow(30);
    } catch (_) {
      return 0;
    }
  }

  /// Convert RAW → XNO
  static double rawToXno(String raw) {
    final rawBalance = BigInt.parse(raw);
    return rawBalance / BigInt.from(10).pow(30);
  }
}
