import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static Future<Map<String, double>> getPrices(String fiatCurrency) async {
    final currency = fiatCurrency.toLowerCase();
    final response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=nano,ethereum,bitcoin,polygon-ecosystem-token&vs_currencies=$currency',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'nano':                     (data['nano']?[currency]                     as num?)?.toDouble() ?? 0,
        'ethereum':                 (data['ethereum']?[currency]                 as num?)?.toDouble() ?? 0,
        'bitcoin':                  (data['bitcoin']?[currency]                  as num?)?.toDouble() ?? 0,
        'polygon-ecosystem-token':  (data['polygon-ecosystem-token']?[currency]  as num?)?.toDouble() ?? 0,
      };
    }
    return {'nano': 0, 'ethereum': 0, 'bitcoin': 0, 'polygon-ecosystem-token': 0};
  }
}
