import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZbdService {
  static const String _wsUrl =
      'wss://api.zebedee.io/api/internal/v1/qrauth-socket';
  static const String _baseUrl = 'https://api.zebedee.io/api/internal/v1';
  static const String _tokenKey = 'zbd_jwt_token';

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Stream<Map<String, dynamic>> startQrAuthFlow() async* {
    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      channel.sink.add(jsonEncode({
        'type': 'internal-connection-sub-qr-auth',
        'data': {
          'browserOS': 'Android',
          'browserName': 'Chrome',
          'QRCodeZClient': 'browser-extension',
        }
      }));

      await for (final message in channel.stream) {
        final Map<String, dynamic> parsed = jsonDecode(message.toString());
        final String type = parsed['type'] ?? '';

        if (type == 'internal-hash-retrieved') {
          yield {'type': 'qr_hash', 'data': parsed['data']};
        } else if (type == 'QR_CODE_AUTH_USER_DATA') {
          yield {
            'type': 'user_preview',
            'username': parsed['data']['username'] ?? '',
            'image': parsed['data']['image'] ?? '',
          };
        } else if (type == 'QR_CODE_AUTH_USER_ACCEPT') {
          final token = parsed['data']['token'] as String;
          await saveToken(token);
          yield {'type': 'authenticated', 'token': token};
          break;
        }
      }
    } catch (e) {
      yield {'type': 'error', 'message': e.toString()};
    } finally {
      channel?.sink.close();
    }
  }

  static Future<int> getBalanceSats() async {
    final data = await _get('$_baseUrl/wallet');
    final int msats = int.parse(data['data']['balance'].toString());
    return msats ~/ 1000;
  }

  static Future<String> getUsername() async {
    final data = await _get('$_baseUrl/me');
    return data['data']['username'] ?? 'ZBD User';
  }

  static Future<Map<String, dynamic>> _get(String url) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('Not authenticated with ZBD');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'z-client': 'browser-extension',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await clearToken();
      throw Exception('ZBD session expired. Please reconnect.');
    } else {
      throw Exception('ZBD API error: ${response.statusCode}');
    }
  }
}