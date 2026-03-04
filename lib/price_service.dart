import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static Future<Map<String, double>> getPrices(String fiatCurrency) async {
    final currency = fiatCurrency.toLowerCase();
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=nano&vs_currencies=$currency',
        ),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['nano'] != null && data['nano'][currency] != null) {
          return {'xno': (data['nano'][currency] as num).toDouble()};
        }
      }
    } catch (_) {}
    return {'xno': 0};
  }
}
