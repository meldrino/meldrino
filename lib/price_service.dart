import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static Future<Map<String, double>> getPrices(String fiatCurrency) async {
    final currency = fiatCurrency.toLowerCase();
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=nano,bitcoin&vs_currencies=$currency',
        ),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, double> prices = {};
        if (data['nano'] != null && data['nano'][currency] != null) {
          prices['xno'] = (data['nano'][currency] as num).toDouble();
        }
        if (data['bitcoin'] != null && data['bitcoin'][currency] != null) {
          prices['btc'] = (data['bitcoin'][currency] as num).toDouble();
        }
        return prices;
      }
    } catch (_) {}
    return {'xno': 0, 'btc': 0};
  }
}
