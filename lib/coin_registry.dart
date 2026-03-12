import 'coin_adapter.dart';
import 'adapters/nano_adapter.dart';
import 'adapters/eth_adapter.dart';
import 'adapters/zbd_adapter.dart';
import 'adapters/polygon_adapter.dart';

/// The single place to register supported coins.
/// To add a new coin: create an adapter file, add one line here. Done.
class CoinRegistry {
  static final List<CoinAdapter> _adapters = [
    NanoAdapter(),
    EthAdapter(),
    ZbdAdapter(),
    PolygonAdapter(),
  ];

  /// All registered coin adapters.
  static List<CoinAdapter> get all => List.unmodifiable(_adapters);

  /// Look up an adapter by ticker (case-insensitive). Returns null if not found.
  static CoinAdapter? byTicker(String ticker) {
    try {
      return _adapters.firstWhere(
        (a) => a.ticker.toLowerCase() == ticker.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Dropdown items for the add-wallet screen: "Name (TICKER)"
  static List<String> get coinLabels =>
      _adapters.map((a) => '${a.name} (${a.ticker})').toList();

  /// Extract the ticker from a stored wallet string "Nano (XNO)|label|address"
  static CoinAdapter? fromWalletEntry(String entry) {
    final parts = entry.split('|');
    if (parts.length < 3) return null;
    final coinLabel = parts[0]; // e.g. "Nano (XNO)"
    final tickerMatch = RegExp(r'\(([^)]+)\)').firstMatch(coinLabel);
    if (tickerMatch == null) return null;
    return byTicker(tickerMatch.group(1)!);
  }
}
