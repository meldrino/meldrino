import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  // Existing method: fetches multiple prices at once
  static Future<Map<String, double>> getPrices(String fiatCurrency) async {
    final currency = fiatCurrency.toLowerCase();
    final response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=nano,bitcoin&vs_currencies=$currency',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'Nano (XNO)': (data['nano'][currency] as num).toDouble(),
        'Bitcoin (BTC)': (data['bitcoin'][currency] as num).toDouble(),
      };
    }

    return {
      'Nano (XNO)': 0,
      'Bitcoin (BTC)': 0,
    };
  }

  // NEW helper method: returns a single price for a single coin
  static Future<double> getPrice(String coin) async {
    // We always fetch USD prices
    final prices = await getPrices('usd');

    // Match the coin string used in home_screen.dart
    if (prices.containsKey(coin)) {
      return prices[coin]!;
    }

    return 0;
  }
}
