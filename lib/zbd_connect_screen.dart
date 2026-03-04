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
  final TextEditingController _tokenController = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please paste your token');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      // Save token and test it immediately
      await ZbdService.saveToken(token);
      final sats = await ZbdService.getBalanceSats();

      if (mounted) {
        // Show success briefly then call onConnected
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.tealAccent, size: 48),
                const SizedBox(height: 16),
                const Text('Connected!',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Balance: $sats sats',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context); // close dialog
          widget.onConnected();
        }
      }
    } catch (e) {
      await ZbdService.clearToken();
      setState(() {
        _verifying = false;
        _error = 'Token invalid or expired. Please try again.';
      });
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Paste your ZBD token below. To get your token, open Chrome on your PC, go to the ZBD extension DevTools console, and run:',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(
                    text:
                        "chrome.storage.local.get(['token'], (r) => console.log(r.token))"));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Command copied')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "chrome.storage.local.get(['token'], (r) => console.log(r.token))",
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.tealAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy,
                        color: Colors.tealAccent.withOpacity(0.5),
                        size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your token',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2), fontSize: 11),
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.tealAccent.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.tealAccent.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2))
                    : const Text('Connect',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The token is valid for approximately 30 days. You will need to repeat this process when it expires.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
