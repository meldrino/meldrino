class CoinHolding {
  final String coin;        // e.g. "Nano (XNO)"
  final String label;       // user label or coin name
  final String address;     // wallet address
  final double balance;     // on-chain balance
  final double price;       // price in USD

  const CoinHolding({
    required this.coin,
    required this.label,
    required this.address,
    required this.balance,
    required this.price,
  });

  double get fiatValue => balance * price;
}
