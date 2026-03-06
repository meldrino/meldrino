import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
    WebSocket? socket;
    try {
      print('[ZBD] Attempting WebSocket connection to $_wsUrl');
      yield {'type': 'log', 'message': 'Connecting to ZBD...'};

      socket = await WebSocket.connect(
        _wsUrl,
        headers: {
          'Origin': 'chrome-extension://kpjdchaapjheajadlaakiiigcbhoppda',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      print('[ZBD] WebSocket connected successfully');
      yield {'type': 'log', 'message': 'Connected. Sending subscription...'};

      final subMsg = jsonEncode({
        'type': 'internal-connection-sub-qr-auth',
        'data': {
          'browserOS': 'Windows',
          'browserName': 'Chrome',
          'QRCodeZClient': 'browser-extension',
        }
      });
      print('[ZBD] Sending: $subMsg');
      socket.add(subMsg);
      yield {'type': 'log', 'message': 'Subscription sent. Waiting for hash...'};

      await for (final message in socket) {
        print('[ZBD] Received message: $message');
        yield {'type': 'log', 'message': 'Received: $message'};

        final Map<String, dynamic> parsed = jsonDecode(message.toString());
        final String type = parsed['type'] ?? '';

        if (type == 'internal-hash-retrieved') {
          print('[ZBD] Hash retrieved: ${parsed['data']}');
          yield {'type': 'qr_hash', 'data': parsed['data']};
        } else if (type == 'QR_CODE_AUTH_USER_DATA') {
          print('[ZBD] User data received: ${parsed['data']}');
          yield {
            'type': 'user_preview',
            'username': parsed['data']['username'] ?? '',
            'image': parsed['data']['image'] ?? '',
          };
        } else if (type == 'QR_CODE_AUTH_USER_ACCEPT') {
          print('[ZBD] Token received!');
          final token = parsed['data']['token'] as String;
          await saveToken(token);
          yield {'type': 'authenticated', 'token': token};
          break;
        } else if (type == 'ping') {
          print('[ZBD] Ping received, sending pong');
          socket.add(jsonEncode({'type': 'pong', 'data': 'pong'}));
          yield {'type': 'log', 'message': 'Ping received, pong sent'};
        } else {
          print('[ZBD] Unknown message type: $type');
          yield {'type': 'log', 'message': 'Unknown message: $type'};
        }
      }

      print('[ZBD] WebSocket stream ended');
      yield {'type': 'log', 'message': 'Connection closed by server'};

    } catch (e, stack) {
      print('[ZBD] ERROR: $e');
      print('[ZBD] STACK: $stack');
      yield {'type': 'error', 'message': e.toString()};
    } finally {
      socket?.close();
      print('[ZBD] Socket closed');
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
