import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'zbd_service.dart';

// Method channel to bring app back to foreground
const _channel = MethodChannel('com.meldrino.app/foreground');

class ZbdConnectScreen extends StatefulWidget {
  final VoidCallback onConnected;
  const ZbdConnectScreen({super.key, required this.onConnected});

  @override
  State<ZbdConnectScreen> createState() => _ZbdConnectScreenState();
}

class _ZbdConnectScreenState extends State<ZbdConnectScreen> {
  String? _previewUsername;
  String? _previewImage;
  String? _error;
  String? _qrHash;
  bool _authenticated = false;
  bool _waiting = false;
  bool _scanning = false;
  bool _manualEntry = false;
  StreamSubscription? _sub;
  final TextEditingController _tokenController = TextEditingController();
  final List<String> _logs = [];

  void _addLog(String msg) {
    print('[ZBD_SCREEN] $msg');
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
      if (_logs.length > 50) _logs.removeAt(0);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tokenController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _waiting = true;
      _error = null;
      _qrHash = null;
      _previewUsername = null;
      _previewImage = null;
      _authenticated = false;
      _logs.clear();
    });
    _addLog('Starting direct connection...');

    _sub?.cancel();
    _sub = ZbdService.startQrAuthFlow().listen((event) async {
      if (!mounted) return;
      final type = event['type'];
      _addLog('Event received: $type');

      if (type == 'log') {
        _addLog(event['message']);
      } else if (type == 'qr_hash') {
        _addLog('Hash arrived! Launching ZBD app...');
        final hash = event['data'];
        setState(() => _qrHash = hash);
        final url = Uri.parse(
            'https://zebedee.io/qrauth/$hash?QRCodeZClient=browser-extension');
        if (await canLaunchUrl(url)) {
          _addLog('Opening ZBD app...');
          await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
          // Wait for ZBD to process, then bring Meldrino back to front
          await Future.delayed(const Duration(seconds: 2));
          _addLog('Bringing Meldrino back to foreground...');
          try {
            await _channel.invokeMethod('bringToFront');
          } catch (e) {
            _addLog('Could not auto-return: $e');
          }
        } else {
          _addLog('Could not launch ZBD app — URL: $url');
        }
      } else if (type == 'user_preview') {
        _addLog('User preview: ${event['username']}');
        setState(() {
          _previewUsername = event['username'];
          _previewImage = event['image'];
        });
      } else if (type == 'authenticated') {
        _addLog('AUTHENTICATED!');
        setState(() => _authenticated = true);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) widget.onConnected();
        });
      } else if (type == 'error') {
        _addLog('ERROR: ${event['message']}');
        setState(() {
          _error = event['message'];
          _waiting = false;
        });
      }
    }, onDone: () {
      _addLog('Stream closed');
    }, onError: (e) {
      _addLog('Stream error: $e');
    });
  }

  Future<void> _onQrScanned(String token) async {
    if (!token.startsWith('eyJ')) {
      setState(() {
        _scanning = false;
        _error = 'That doesn\'t look like a valid ZBD token. Try again.';
      });
      return;
    }
    await ZbdService.saveToken(token);
    setState(() {
      _scanning = false;
      _authenticated = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onConnected();
    });
  }

  Future<void> _onManualSubmit() async {
    final token = _tokenController.text.trim();
    if (!token.startsWith('eyJ')) {
      setState(() => _error = 'That doesn\'t look like a valid ZBD token.');
      return;
    }
    await ZbdService.saveToken(token);
    setState(() => _authenticated = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onConnected();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Connect ZBD',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_authenticated) return _buildSuccess();
    if (_scanning) return _buildScanner();
    if (_manualEntry) return _buildManualEntry();
    if (_error != null) return _buildError();
    if (_authenticated) return _buildSuccess();
    if (_waiting) return _buildWaiting();
    return _buildInstructions();
  }

  Widget _buildInstructions() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFF2A2A4A),
            child: Text('Z',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 28),
          const Text('Connect your ZBD wallet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connect directly',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent)),
                const SizedBox(height: 8),
                const Text(
                    'Meldrino connects to ZBD directly.\n'
                    'A QR code will appear — scan it with your ZBD app.',
                    style: TextStyle(fontSize: 13, height: 1.6)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Connect directly',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan from PC',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text(
                    '1. On your PC open the Meldrino ZBD Connect page\n'
                    '2. Scan the QR with your ZBD app\n'
                    '3. Tap below to scan the token QR from the PC screen',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _scanning = true),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan token QR code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _manualEntry = true),
            child: Text('Paste token manually',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // QR code display area
        if (_qrHash != null) ...[
          const Text('Scan this QR with your ZBD app',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: 'https://zebedee.io/qrauth/$_qrHash?QRCodeZClient=browser-extension',
              version: QrVersions.auto,
              size: 220,
            ),
          ),
          const SizedBox(height: 8),
          Text('Hash: ${_qrHash!.substring(0, 30)}...',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'monospace')),
        ] else ...[
          const CircularProgressIndicator(color: Colors.tealAccent),
          const SizedBox(height: 16),
          const Text('Connecting to ZBD...',
              style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
        ],

        const SizedBox(height: 20),

        // Live log
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, i) => Text(
                _logs[i],
                style: const TextStyle(
                    color: Colors.green, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        if (_qrHash != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConnected(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue to Meldrino',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        else
          TextButton(
            onPressed: () {
              _sub?.cancel();
              setState(() {
                _waiting = false;
                _qrHash = null;
              });
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUserPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_previewImage != null && _previewImage!.isNotEmpty)
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(_previewImage!),
            backgroundColor: const Color(0xFF2A2A4A),
          ),
        const SizedBox(height: 16),
        Text('@$_previewUsername',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent)),
        const SizedBox(height: 8),
        Text('Authorising...',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Colors.tealAccent),
      ],
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Point your camera at the token QR\non the PC screen',
            style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _onQrScanned(barcode!.rawValue!);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _scanning = false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Paste your ZBD token',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _tokenController,
          maxLines: 4,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'eyJhbGci...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: const Color(0xFF16213E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onManualSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Connect',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _manualEntry = false;
            _error = null;
          }),
          child: const Text('Back', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 64),
        SizedBox(height: 16),
        Text('Connected!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent)),
        SizedBox(height: 8),
        Text('Your ZBD balance will now appear in Meldrino.',
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        const Text('Connection failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_error!,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        // Show logs even on error
        if (_logs.isNotEmpty)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, i) => Text(
                  _logs[i],
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() {
            _error = null;
            _waiting = false;
            _logs.clear();
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Try Again',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
