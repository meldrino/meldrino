import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'zbd_service.dart';

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
  bool _authenticated = false;
  bool _waiting = false;
  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _waiting = true;
      _error = null;
      _previewUsername = null;
      _previewImage = null;
      _authenticated = false;
    });

    _sub?.cancel();
    _sub = ZbdService.startQrAuthFlow().listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'qr_hash') {
        // Hash received, WebSocket is ready and listening
        // Nothing to display for this — we just wait
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
          _waiting = false;
        });
      }
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
    if (_error != null) return _buildError();
    if (_previewUsername != null) return _buildUserPreview();
    if (_waiting) return _buildWaiting();
    return _buildInstructions();
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
        const Text('Connect your ZBD wallet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        _buildStep('1', 'On your PC, go to:'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(const ClipboardData(
                text: 'https://browser-extension.zebedee.io'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL copied')),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('browser-extension.zebedee.io',
                    style: TextStyle(
                        color: Colors.tealAccent,
                        fontFamily: 'monospace',
                        fontSize: 13)),
                Icon(Icons.copy,
                    color: Colors.tealAccent.withOpacity(0.6), size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStep('2', 'Scan the QR code shown there using your ZBD app'),
        const SizedBox(height: 12),
        _buildStep('3', 'Tap Connect in your ZBD app'),
        const SizedBox(height: 12),
        _buildStep('4', 'Tap the button below — Meldrino will wait for the connection'),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startListening,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Ready — connect now',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
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
          child: Text(text,
              style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.tealAccent),
        const SizedBox(height: 24),
        const Text('Waiting for ZBD connection...',
            style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Scan the QR at browser-extension.zebedee.io with your ZBD app and tap Connect.',
          style:
              TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          textAlign: TextAlign.center,
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
          onPressed: () => setState(() {
            _error = null;
            _waiting = false;
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
