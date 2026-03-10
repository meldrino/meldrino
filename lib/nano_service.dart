import 'dart:convert';
import 'package:http/http.dart' as http;

class NanoService {
  // Primary: nanswap with API key in header
  static const String _apiKey =
      '3biV6K9bbvp40bdoCOAQnmLpc2anmUQwlYD7ZNQzSmlMDnROQuNUPafbECsFhc5aM';
  static const String _primaryUrl = 'https://nodes.nanswap.com/XNO';

  // Fallback: public Nano node (no key required)
  static const String _fallbackUrl = 'https://rpc.nano.to';

  static Future<http.Response> _post(String body) async {
    // Try primary first
    try {
      final response = await http.post(
        Uri.parse(_primaryUrl),
        headers: {
          'Content-Type': 'application/json',
          'nodes-api-key': _apiKey,
        },
        body: body,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // If response contains an error or empty balance, fall through to fallback
        if (data['error'] == null) return response;
      }
    } catch (_) {}

    // Fallback
    return await http.post(
      Uri.parse(_fallbackUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 8));
  }

  static Future<double> getBalance(String address) async {
    final response = await _post(
      jsonEncode({'action': 'account_balance', 'account': address}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) return 0;
      final rawBalance = BigInt.parse(data['balance'] ?? '0');
      return rawBalance / BigInt.from(10).pow(30);
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String address,
      {int count = 5}) async {
    final response = await _post(
      jsonEncode({
        'action': 'account_history',
        'account': address,
        'count': count.toString(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final history = data['history'];
      if (history is List) {
        return history.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  static double rawToXno(String raw) {
    final rawBalance = BigInt.parse(raw);
    return rawBalance / BigInt.from(10).pow(30);
  }
}
