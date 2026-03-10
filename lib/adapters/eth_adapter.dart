import '../coin_adapter.dart';
import '../eth_service.dart';

class EthAdapter extends CoinAdapter {
  @override String get ticker => 'ETH';
  @override String get name => 'Ethereum';
  @override String get iconPath => 'assets/icons/ethereum.png';
  @override String get coingeckoId => 'ethereum';
  @override int get decimalPlaces => 6;

  @override
  Future<double> getBalance(String address) =>
      EthService.getBalance(address);

  @override
  Future<List<TxRecord>> getHistory(String address, {int count = 5}) async {
    final raw = await EthService.getHistory(address, count: count);
    return raw.map((tx) {
      final myAddr = address.toLowerCase();
      final from = (tx['from'] ?? '').toString().toLowerCase();
      final isReceive = from != myAddr;
      double amount = 0;
      try {
        final wei = BigInt.parse(tx['value'].toString());
        amount = wei / BigInt.from(10).pow(18);
      } catch (_) {}
      final time = _fmt(tx['timeStamp']);
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
