/// A normalised transaction record — every coin adapter returns this shape.
class TxRecord {
  final bool isReceive;
  final double amount;   // in the coin's display unit (XNO, ETH, SATS etc.)
  final String time;     // pre-formatted display string
  final String? label;   // optional memo / description

  const TxRecord({
    required this.isReceive,
    required this.amount,
    required this.time,
    this.label,
  });
}

/// Every coin must implement this interface.
/// Add a new coin = add one new file implementing CoinAdapter.
/// No other file needs to change.
abstract class CoinAdapter {
  /// Ticker symbol shown throughout the UI e.g. 'XNO', 'ETH', 'SATS'
  String get ticker;

  /// Display name e.g. 'Nano', 'Ethereum', 'Satoshi'
  String get name;

  /// Asset path for the coin icon e.g. 'assets/icons/nano.png'
  String get iconPath;

  /// CoinGecko id used to fetch the price e.g. 'nano', 'ethereum', 'bitcoin'
  String get coingeckoId;

  /// Whether this coin uses custodial auth (e.g. ZBD OAuth) instead of a raw address.
  bool get isCustodial => false;

  /// Label shown next to the identifier in the detail screen.
  /// Non-custodial coins show 'Address'; custodial coins can override this.
  String get addressLabel => 'Address';

  /// Whether to show the copy-to-clipboard button on the detail screen.
  bool get showCopyButton => !isCustodial;

  /// Fetch the balance for [address].
  /// For custodial coins [address] may be a sentinel value like 'zbd'.
  Future<double> getBalance(String address);

  /// Fetch transaction history. Return at most [count] records.
  Future<List<TxRecord>> getHistory(String address, {int count = 5});

  /// For custodial coins that store an OAuth token, return the display
  /// identifier (e.g. username) to show instead of a raw address.
  /// Non-custodial coins can ignore this — the raw address is used.
  Future<String> resolveDisplayAddress(String address) async => address;

  /// How many decimal places to show for balances.
  int get decimalPlaces => 4;

  /// Convert a price-per-coin value into a price-per-unit string.
  /// Most coins just return the price directly; SATS divides BTC price by 1e8.
  double adjustPrice(double rawCoingeckoPrice) => rawCoingeckoPrice;
}
