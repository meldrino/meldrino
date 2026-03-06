import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// This runs inside the foreground task isolate
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ZbdTaskHandler());
}

class ZbdTaskHandler extends TaskHandler {
  WebSocket? _socket;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _connectWebSocket();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Keep alive — ping is handled by the WebSocket listener
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _socket?.close();
    _socket = null;
  }

  @override
  void onReceiveData(Object data) {}

  Future<void> _connectWebSocket() async {
    try {
      _socket = await WebSocket.connect(
        'wss://api.zebedee.io/api/internal/v1/qrauth-socket',
        headers: {
          'Origin': 'chrome-extension://kpjdchaapjheajadlaakiiigcbhoppda',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
        },
      );

      _socket!.add(jsonEncode({
        'type': 'internal-connection-sub-qr-auth',
        'data': {
          'browserOS': 'Android',
          'browserName': 'Chrome',
          'QRCodeZClient': 'browser-extension',
        }
      }));

      _socket!.listen(
        (raw) async {
          try {
            final msg = jsonDecode(raw.toString()) as Map<String, dynamic>;
            final type = msg['type'] ?? '';

            if (type == 'ping') {
              _socket?.add(jsonEncode({'type': 'pong', 'data': 'pong'}));
            } else if (type == 'internal-hash-retrieved') {
              final hash = msg['data'] as String;
              final qrUrl =
                  'https://zebedee.io/qrauth/$hash?QRCodeZClient=browser-extension';
              FlutterForegroundTask.sendDataToMain(
                  {'type': 'qr_hash', 'data': hash, 'qr_url': qrUrl});
            } else if (type == 'QR_CODE_AUTH_USER_DATA') {
              FlutterForegroundTask.sendDataToMain({
                'type': 'user_preview',
                'username': msg['data']['username'] ?? '',
                'image': msg['data']['image'] ?? '',
              });
            } else if (type == 'QR_CODE_AUTH_USER_ACCEPT') {
              final token = msg['data']['token'] as String;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('zbd_jwt_token', token);
              FlutterForegroundTask.sendDataToMain(
                  {'type': 'authenticated', 'token': token});
              await FlutterForegroundTask.stopService();
            }
          } catch (_) {}
        },
        onError: (e) {
          FlutterForegroundTask.sendDataToMain(
              {'type': 'error', 'message': e.toString()});
        },
        onDone: () {
          FlutterForegroundTask.sendDataToMain(
              {'type': 'error', 'message': 'WebSocket closed by server'});
        },
        cancelOnError: false,
      );
    } catch (e) {
      FlutterForegroundTask.sendDataToMain(
          {'type': 'error', 'message': e.toString()});
    }
  }
}

class ZbdService {
  static const String _tokenKey = 'zbd_jwt_token';
  static const String _apiUrl = 'https://api.zebedee.io';

  static final ZbdService instance = ZbdService._internal();
  ZbdService._internal();

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

  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'zbd_connect',
        channelName: 'ZBD Connection',
        channelDescription: 'Keeping ZBD connection alive',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
      ),
    );
  }

  static Future<void> startQrAuthFlow() async {
    initForegroundTask();

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Meldrino',
      notificationText: 'Waiting for ZBD connection...',
      callback: startCallback,
    );
  }

  static Future<void> stopQrAuthFlow() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<int> getBalanceSats() async {
    final data = await _get('$_apiUrl/v0/wallet');
    final msats = int.parse(data['data']['balance'].toString());
    return msats ~/ 1000;
  }

  static Future<String> getUsername() async {
    final data = await _get('$_apiUrl/v0/user');
    return data['data']['gamertag'] ?? 'ZBD User';
  }

  static Future<Map<String, dynamic>> _get(String url) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('Not authenticated with ZBD');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token,
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
