import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static Future<Map<String, double>> getPrices(String fiatCurrency) async {
    final currency = fiatCurrency.toLowerCase();
    final response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=nano,ethereum,bitcoin&vs_currencies=$currency',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'nano': (data['nano']?[currency] as num? ?? 0).toDouble(),
        'ethereum': (data['ethereum']?[currency] as num? ?? 0).toDouble(),
        'bitcoin': (data['bitcoin']?[currency] as num? ?? 0).toDouble(),
      };
    }
    return {'nano': 0, 'ethereum': 0, 'bitcoin': 0};
  }
}
