import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _copied = false;
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
      _copied = false;
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

  Future<void> _openZbdApp() async {
    if (_qrHash == null) return;

    // Try ZBD's browser-extension URL — ZBD app is registered to handle this domain
    final uri = Uri.parse(
        'https://browser-extension.zebedee.io/?hash=${Uri.encodeComponent(_qrHash!)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: open ZBD app store page if ZBD isn't installed
      await launchUrl(
        Uri.parse(
            'https://play.google.com/store/apps/details?id=io.zebedee.android'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _copyHash() {
    if (_qrHash == null) return;
    Clipboard.setData(ClipboardData(text: _qrHash!));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _copied = false) : null);
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
            style:
                TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
    if (_qrHash != null) return _buildConnectPrompt();
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

  Widget _buildConnectPrompt() {
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
        const SizedBox(height: 24),
        const Text('Connect your ZBD wallet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Tap the button below to open the ZBD app and authorise Meldrino.',
          style:
              TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openZbdApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open ZBD App',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'After tapping Approve in ZBD, return here.',
          style:
              TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Fallback for power users / if deep link doesn't work
        TextButton.icon(
          onPressed: _copyHash,
          icon: Icon(
            _copied ? Icons.check : Icons.copy,
            size: 16,
            color: Colors.tealAccent,
          ),
          label: Text(
            _copied ? 'Copied!' : 'Copy connection code instead',
            style:
                const TextStyle(color: Colors.tealAccent, fontSize: 13),
          ),
        ),
        const SizedBox(height: 32),
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
          onPressed: _startFlow,
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
