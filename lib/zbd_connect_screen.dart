import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'zbd_service.dart';

class ZbdConnectScreen extends StatefulWidget {
  final VoidCallback onConnected;
  const ZbdConnectScreen({super.key, required this.onConnected});

  @override
  State<ZbdConnectScreen> createState() => _ZbdConnectScreenState();
}

class _ZbdConnectScreenState extends State<ZbdConnectScreen> {
  String? _qrUrl;
  String? _previewUsername;
  String? _previewImage;
  String? _error;
  bool _authenticated = false;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _start();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }

  void _onTaskData(Object data) {
    if (!mounted) return;
    final event = Map<String, dynamic>.from(data as Map);
    final type = event['type'];

    if (type == 'qr_hash') {
      setState(() {
        _qrUrl = event['qr_url'];
        _connecting = false;
      });
    } else if (type == 'user_preview') {
      setState(() {
        _previewUsername = event['username'];
        _previewImage = event['image'];
      });
    } else if (type == 'authenticated') {
      setState(() => _authenticated = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.onConnected();
      });
    } else if (type == 'error') {
      setState(() {
        _error = event['message'];
        _connecting = false;
      });
    }
  }

  Future<void> _start() async {
    setState(() {
      _connecting = true;
      _error = null;
      _qrUrl = null;
      _previewUsername = null;
      _previewImage = null;
      _authenticated = false;
    });
    await ZbdService.startQrAuthFlow();
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
    if (_error != null) return _buildError();
    if (_previewUsername != null) return _buildUserPreview();
    if (_qrUrl != null) return _buildInstructions();
    return _buildConnecting();
  }

  Widget _buildConnecting() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.tealAccent),
        SizedBox(height: 24),
        Text('Connecting to ZBD...',
            style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        const Text('Scan with your ZBD app',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        _buildStep('1', 'On your PC, go to:'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('browser-extension.zebedee.io',
                  style: TextStyle(
                      color: Colors.tealAccent,
                      fontFamily: 'monospace',
                      fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStep('2', 'Open your ZBD app and tap the scan icon'),
        const SizedBox(height: 12),
        _buildStep('3', 'Scan the QR code shown on your PC screen'),
        const SizedBox(height: 12),
        _buildStep('4', 'Tap Approve in ZBD — Meldrino will detect it automatically'),
        const SizedBox(height: 32),
        const CircularProgressIndicator(color: Colors.tealAccent),
        const SizedBox(height: 16),
        Text(
          'Waiting for you to approve in ZBD...',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Colors.tealAccent,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
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
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Colors.tealAccent),
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
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _start,
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
