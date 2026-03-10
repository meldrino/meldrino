import '../coin_adapter.dart';
import '../nano_service.dart';

class NanoAdapter extends CoinAdapter {
  @override String get ticker => 'XNO';
  @override String get name => 'Nano';
  @override String get iconPath => 'assets/icons/nano.png';
  @override String get coingeckoId => 'nano';

  @override
  Future<double> getBalance(String address) =>
      NanoService.getBalance(address);

  @override
  Future<List<TxRecord>> getHistory(String address, {int count = 5}) async {
    final raw = await NanoService.getHistory(address, count: count);
    return raw.map((tx) {
      final isReceive = tx['type'] == 'receive';
      final amount = NanoService.rawToXno(tx['amount'].toString());
      final time = _fmt(tx['local_timestamp']);
      return TxRecord(isReceive: isReceive, amount: amount, time: time);
    }).toList();
  }

  String _fmt(dynamic ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(ts.toString()) * 1000);
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
