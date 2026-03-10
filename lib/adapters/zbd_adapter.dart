import '../coin_adapter.dart';
import '../zbd_service.dart';

class ZbdAdapter extends CoinAdapter {
  @override String get ticker => 'SATS';
  @override String get name => 'Satoshi';
  @override String get iconPath => 'assets/icons/sats.png';
  @override String get coingeckoId => 'bitcoin'; // price comes from BTC
  @override bool get isCustodial => true;
  @override String get addressLabel => 'ZBD Username';
  @override int get decimalPlaces => 0;

  /// SATS price = BTC price / 100,000,000
  @override
  double adjustPrice(double rawCoingeckoPrice) => rawCoingeckoPrice / 100000000;

  @override
  Future<double> getBalance(String address) async {
    final sats = await ZbdService.getBalanceSats();
    return sats.toDouble();
  }

  @override
  Future<String> resolveDisplayAddress(String address) =>
      ZbdService.getUsername();

  @override
  Future<List<TxRecord>> getHistory(String address, {int count = 5}) async {
    final raw = await ZbdService.getTransactions(count: count);
    return raw.map((tx) {
      final type = (tx['type'] ?? tx['transactionType'] ?? '').toString().toLowerCase();
      final isReceive = type.contains('receive') ||
          type.contains('credit') ||
          type.contains('in');
      double amount = 0;
      try {
        final msats = int.parse(
            (tx['amount'] ?? tx['msatoshi'] ?? tx['value'] ?? '0').toString());
        amount = msats / 1000;
      } catch (_) {}
      final timeRaw = tx['createdAt'] ?? tx['timestamp'] ?? tx['date'] ?? '';
      final time = _fmt(timeRaw.toString());
      final label = (tx['description'] ?? tx['memo'] ?? tx['note'])?.toString();
      return TxRecord(isReceive: isReceive, amount: amount, time: time, label: label);
    }).toList();
  }

  String _fmt(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = ts.contains('T')
          ? DateTime.parse(ts)
          : DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}
