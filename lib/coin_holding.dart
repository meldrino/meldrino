class CoinHolding {
  final String name;
  final String ticker;
  final String wallet;
  final String address;
  final double balance;
  final double priceUsd;
  final String fiatCurrency;
  final String fiatSymbol;

  const CoinHolding({
    required this.name,
    required this.ticker,
    required this.wallet,
    required this.address,
    required this.balance,
    required this.priceUsd,
    required this.fiatCurrency,
    required this.fiatSymbol,
  });

  double get fiatValue => balance * priceUsd;
}