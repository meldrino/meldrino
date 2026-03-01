import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'coin_holding.dart';
import 'nano_service.dart';
import 'app_bar.dart';

class CoinDetailScreen extends StatefulWidget {
  final CoinHolding holding;
  const CoinDetailScreen({super.key, required this.holding});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;
  bool _showingAll = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({int count = 5}) async {
    setState(() => _loadingHistory = true);
    final history =
        await NanoService.getHistory(widget.holding.address, count: count);
    setState(() {
      _history = history;
      _loadingHistory = false;
    });
  }

  String _formatTimestamp(dynamic ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(ts.toString()) * 1000);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openInNatrium() async {
    final uri = Uri.parse('nano:${widget.holding.address}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Natrium not installed or not supported on this device')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final holding = widget.holding;
    return Scaffold(
      appBar: MeldrinoAppBar(onRefresh: () {}),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.wallet,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                    '${holding.balance.toStringAsFixed(6)} ${holding.ticker}',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    '${holding.fiatSymbol}${holding.fiatValue.toStringAsFixed(2)} ${holding.fiatCurrency}',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.tealAccent)),
                const SizedBox(height: 4),
                Text(
                    '1 ${holding.ticker} = ${holding.fiatSymbol}${holding.priceUsd.toStringAsFixed(4)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    holding.address,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: Colors.tealAccent, size: 20),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: holding.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInNatrium,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Natrium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Transactions',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            Text('No transactions found',
                style: TextStyle(color: Colors.white.withOpacity(0.5)))
          else ...[
            ..._history.map((tx) {
              final isReceive = tx['type'] == 'receive';
              final amount =
                  NanoService.rawToXno(tx['amount'].toString());
              final time = _formatTimestamp(tx['local_timestamp']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isReceive
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: isReceive
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReceive ? 'Received' : 'Sent',
                            style: TextStyle(
                              color: isReceive
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(time,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '${isReceive ? '+' : '-'}${amount.toStringAsFixed(4)} XNO',
                      style: TextStyle(
                        color: isReceive
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!_showingAll)
              TextButton(
                onPressed: () {
                  setState(() => _showingAll = true);
                  _loadHistory(count: 50);
                },
                child: const Text('Show all transactions',
                    style: TextStyle(color: Colors.tealAccent)),
              ),
          ],
        ],
      ),
    );
  }
}
