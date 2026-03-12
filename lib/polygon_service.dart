import 'dart:convert';
import 'package:http/http.dart' as http;

class PolygonService {
  static const String _apiKey = 'ZNNBHSAHWH9URCMPZRNH14H1G1AGDRN8HW';
  static const String _baseUrl = 'https://api.etherscan.io/v2/api?chainid=137';

  static Future<double> getBalance(String address) async {
    final response = await http.get(Uri.parse(
      '$_baseUrl&module=account&action=balance&address=$address&tag=latest&apikey=$_apiKey',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == '1') {
        final rawBalance = BigInt.parse(data['result']);
        // Convert from Wei to MATIC (1 MATIC = 10^18 Wei)
        return rawBalance / BigInt.from(10).pow(18);
      }
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String address,
      {int count = 5}) async {
    final response = await http.get(Uri.parse(
      '$_baseUrl&module=account&action=txlist&address=$address&startblock=0&endblock=99999999&page=1&offset=$count&sort=desc&apikey=$_apiKey',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == '1' && data['result'] is List) {
        return (data['result'] as List).cast<Map<String, dynamic>>();
      }
    }
    return [];
  }
}
