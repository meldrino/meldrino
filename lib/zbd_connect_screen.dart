import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'zbd_service.dart';

class ZbdConnectScreen extends StatefulWidget {
  final VoidCallback onConnected;
  const ZbdConnectScreen({super.key, required this.onConnected});

  @override
  State<ZbdConnectScreen> createState() => _ZbdConnectScreenState();
}

class _ZbdConnectScreenState extends State<ZbdConnectScreen> {
  String? _qrHash;
  String? _previewUsername;
  String? _previewImage;
  String? _error;
  bool _authenticated = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  void _startFlow() {
    setState(() {
      _qrHash = null;
      _previewUsername = null;
      _previewImage = null;
      _error = null;
      _authenticated = false;
    });

    _sub?.cancel();
    _sub = ZbdService.startQrAuthFlow().listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'qr_hash') {
        setState(() => _qrHash = event['data']);
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
        setState(() => _error = event['message']);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
    if (_qrHash != null) return _buildQrCode();
    return _buildConnecting();
  }

  Widget _buildConnecting() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.tealAccent),
          SizedBox(height: 20),
          Text('Connecting to ZBD...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Connect your ZBD wallet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildStep('1', 'Screenshot this QR code'),
          const SizedBox(height: 10),
          _buildStep('2', 'Open your ZBD app'),
          const SizedBox(height: 10),
          _buildStep('3', 'Tap the scan icon and choose your camera roll'),
          const SizedBox(height: 10),
          _buildStep('4', 'Select the screenshot and tap Approve'),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: _qrHash!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.tealAccent),
              ),
              const SizedBox(width: 10),
              Text('Waiting for approval...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.tealAccent,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15)),
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
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
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
          onPressed: _startFlow,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Try Again',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
