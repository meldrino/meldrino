import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'coin_holding.dart';
import 'coin_adapter.dart';
import 'coin_registry.dart';
import 'app_bar.dart';

class CoinDetailScreen extends StatefulWidget {
  final CoinHolding holding;
  const CoinDetailScreen({super.key, required this.holding});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  List<TxRecord> _history = [];
  bool _loadingHistory = true;
  String? _historyError;
  bool _showingAll = false;

  CoinAdapter? get _adapter => CoinRegistry.byTicker(widget.holding.ticker);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({int count = 5}) async {
    setState(() { _loadingHistory = true; _historyError = null; });
    try {
      final adapter = _adapter;
      if (adapter == null) throw Exception('Unknown coin');
      // Use rawAddress for API calls (e.g. 'zbd' sentinel), not the display address
      final history = await adapter.getHistory(
          widget.holding.rawAddress, count: count);
      // Always cap to requested count client-side (some APIs ignore the limit param)
      final capped = history.length > count ? history.sublist(0, count) : history;
      setState(() { _history = capped; _loadingHistory = false; });
    } catch (e) {
      setState(() { _historyError = e.toString(); _loadingHistory = false; });
    }
  }

  String _formatBalance(double balance, int dp) => balance.toStringAsFixed(dp);

  @override
  Widget build(BuildContext context) {
    final holding = widget.holding;
    final adapter = _adapter;
    final dp = adapter?.decimalPlaces ?? 4;
    final isCustodial = adapter?.isCustodial ?? false;
    final addressLabel = adapter?.addressLabel ?? 'Address';
    final showCopy = adapter?.showCopyButton ?? true;

    return Scaffold(
      appBar: MeldrinoAppBar(onRefresh: () {}),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Balance card ────────────────────────────────────────────────
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
                        color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 8),
                Text('${_formatBalance(holding.balance, dp)} ${holding.ticker}',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    '${holding.fiatSymbol}${holding.fiatValue.toStringAsFixed(2)} ${holding.fiatCurrency}',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.tealAccent)),
                const SizedBox(height: 4),
                Text(
                    '1 ${holding.ticker} = ${holding.fiatSymbol}${holding.priceUsd.toStringAsFixed(dp >= 6 ? 8 : 4)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Address / identifier card ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(addressLabel,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        holding.address,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontFamily: isCustodial ? null : 'monospace'),
                      ),
                    ],
                  ),
                ),
                if (showCopy)
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: Colors.tealAccent, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: holding.address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied')),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── NFT button ───────────────────────────────────────────────────
          // Placeholder — will search / display NFTs in a future session.
          // Text changes once NFT data is available for this chain.
          _NftPlaceholderButton(ticker: holding.ticker),
          const SizedBox(height: 24),

          // ── Transaction history ──────────────────────────────────────────
          const Text('Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_historyError != null)
            Text('Could not load transactions: $_historyError',
                style: TextStyle(color: Colors.white.withOpacity(0.5)))
          else if (_history.isEmpty)
            Text('No transactions found',
                style: TextStyle(color: Colors.white.withOpacity(0.5)))
          else ...[
            ..._history.map((tx) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tx.isReceive
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: tx.isReceive
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
                              (tx.label != null && tx.label!.isNotEmpty)
                                  ? tx.label!
                                  : (tx.isReceive ? 'Received' : 'Sent'),
                              style: TextStyle(
                                color: tx.isReceive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (tx.time.isNotEmpty)
                              Text(tx.time,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.isReceive ? '+' : '-'}${_formatBalance(tx.amount, dp)} ${holding.ticker}',
                        style: TextStyle(
                          color: tx.isReceive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
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

/// NFT placeholder button. Shows different text depending on whether NFTs
/// have been found for this chain. Tapping navigates to the NFT screen
/// (not yet built — shows a snackbar for now).
class _NftPlaceholderButton extends StatelessWidget {
  final String ticker;
  const _NftPlaceholderButton({required this.ticker});

  // In a future session this will check a real NFT cache.
  // For now it always returns false (no NFTs known).
  bool get _nftsFound => false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFT support coming soon')),
          );
        },
        icon: Icon(
          _nftsFound ? Icons.image : Icons.image_search_outlined,
          size: 18,
        ),
        label: Text(
          _nftsFound
              ? 'NFTs found on this blockchain'
              : 'No NFTs found on this blockchain',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _nftsFound ? Colors.tealAccent : Colors.white54,
          side: BorderSide(
              color: _nftsFound
                  ? Colors.tealAccent
                  : Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
