import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static Future<Map<String, double>> getPrices(String fiatCurrency) async {
    final currency = fiatCurrency.toLowerCase();
    final response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=nano,bitcoin&vs_currencies=$currency',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'xno': (data['nano'][currency] as num).toDouble(),
        'btc': (data['bitcoin'][currency] as num).toDouble(),
      };
    }
    return {'xno': 0, 'btc': 0};
  }
}
