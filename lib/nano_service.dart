import 'dart:convert';
import 'package:http/http.dart' as http;

class NanoService {
  static const String _apiKey =
      '3biV6K9bbvp40bdoCOAQnmLpc2anmUQwlYD7ZNQzSmlMDnROQuNUPafbECsFhc5aM';
  static const String _rpcUrl =
      'https://nodes.nanswap.com/XNO?api_key=$_apiKey';

  static Future<double> getBalance(String address) async {
    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'account_balance', 'account': address}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawBalance = BigInt.parse(data['balance'] ?? '0');
      return rawBalance / BigInt.from(10).pow(30);
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String address,
      {int count = 5}) async {
    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
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