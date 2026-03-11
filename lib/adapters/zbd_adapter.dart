import '../coin_adapter.dart';
import '../zbd_service.dart';

class ZbdAdapter extends CoinAdapter {
  @override String get ticker => 'SATS';
  @override String get name => 'Satoshi';
  @override String get iconPath => 'assets/icons/sats.png';
  @override String get coingeckoId => 'bitcoin';
  @override bool get isCustodial => true;
  @override String get addressLabel => 'ZBD Username';
  @override int get decimalPlaces => 0;

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
      // flow is TRANSACTION_FLOW_CREDIT (in) or TRANSACTION_FLOW_DEBIT (out)
      final flow = (tx['flow'] ?? '').toString();
      final isReceive = flow == 'TRANSACTION_FLOW_CREDIT';

      // amount is in msats
      double amount = 0;
      try {
        final msats = int.parse(tx['amount'].toString());
        amount = msats / 1000;
      } catch (_) {}

      final time = _fmt(tx['createdAt']?.toString() ?? '');
      final label = tx['description']?.toString();

      return TxRecord(
        isReceive: isReceive,
        amount: amount,
        time: time,
        label: label,
      );
    }).toList();
  }

  String _fmt(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}
