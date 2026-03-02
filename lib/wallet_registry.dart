enum WalletType { nonCustodial, custodial }

enum WalletCoin {
  xno,
  ban,
  btc,
  btcLightning,
  eth,
  sol,
  xrp,
  xmr,
  wow,
  multi,
}

class WalletDefinition {
  final String name;
  final List<WalletCoin> coins;
  final WalletType type;
  final String? androidPackage;
  final String category;

  const WalletDefinition({
    required this.name,
    required this.coins,
    required this.type,
    this.androidPackage,
    required this.category,
  });
}

class WalletRegistry {
  static const List<WalletDefinition> all = [

    // ── Nano ──────────────────────────────────────────────────
    WalletDefinition(
      name: 'Natrium',
      coins: [WalletCoin.xno],
      type: WalletType.nonCustodial,
      androidPackage: 'co.banano.natriumwallet',
      category: 'Nano',
    ),
    WalletDefinition(
      name: 'Nautilus',
      coins: [WalletCoin.xno],
      type: WalletType.nonCustodial,
      androidPackage: 'co.perish.nautiluswallet',
      category: 'Nano',
    ),
    WalletDefinition(
      name: 'Cake Wallet',
      coins: [WalletCoin.xno, WalletCoin.xmr],
      type: WalletType.nonCustodial,
      androidPackage: 'com.cakewallet.cake_wallet',
      category: 'Nano',
    ),
    WalletDefinition(
      name: 'WeNano',
      coins: [WalletCoin.xno],
      type: WalletType.nonCustodial,
      androidPackage: 'com.tipanano.WeNanoLight',
      category: 'Nano',
    ),
    WalletDefinition(
      name: 'Kalium',
      coins: [WalletCoin.ban],
      type: WalletType.nonCustodial,
      androidPackage: 'com.banano.kaliumwallet',
      category: 'Banano',
    ),

    // ── Bitcoin ───────────────────────────────────────────────
    WalletDefinition(
      name: 'BlueWallet',
      coins: [WalletCoin.btc, WalletCoin.btcLightning],
      type: WalletType.nonCustodial,
      androidPackage: 'io.bluewallet.bluewallet',
      category: 'Bitcoin',
    ),
    WalletDefinition(
      name: 'Muun',
      coins: [WalletCoin.btc, WalletCoin.btcLightning],
      type: WalletType.nonCustodial,
      androidPackage: 'io.muun.apollo',
      category: 'Bitcoin',
    ),
    WalletDefinition(
      name: 'Phoenix',
      coins: [WalletCoin.btcLightning],
      type: WalletType.nonCustodial,
      androidPackage: 'fr.acinq.phoenix.mainnet',
      category: 'Bitcoin',
    ),
    WalletDefinition(
      name: 'Breez',
      coins: [WalletCoin.btcLightning],
      type: WalletType.nonCustodial,
      androidPackage: 'com.breez.client',
      category: 'Bitcoin',
    ),
    WalletDefinition(
      name: 'Zeus',
      coins: [WalletCoin.btcLightning],
      type: WalletType.nonCustodial,
      androidPackage: 'app.zeusln.zeus',
      category: 'Bitcoin',
    ),
    WalletDefinition(
      name: 'Electrum',
      coins: [WalletCoin.btc],
      type: WalletType.nonCustodial,
      androidPackage: 'org.electrum.electrum',
      category: 'Bitcoin',
    ),
    WalletDefinition(
      name: 'Wasabi',
      coins: [WalletCoin.btc],
      type: WalletType.nonCustodial,
      androidPackage: null, // Desktop only
      category: 'Bitcoin',
    ),

    // ── Ethereum / EVM ────────────────────────────────────────
    WalletDefinition(
      name: 'MetaMask',
      coins: [WalletCoin.eth],
      type: WalletType.nonCustodial,
      androidPackage: 'io.metamask',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Trust Wallet',
      coins: [WalletCoin.eth, WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'com.wallet.crypto.trustapp',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Exodus',
      coins: [WalletCoin.eth, WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'exodusmovement.exodus',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Rainbow',
      coins: [WalletCoin.eth],
      type: WalletType.nonCustodial,
      androidPackage: 'me.rainbow',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Coinbase Wallet',
      coins: [WalletCoin.eth, WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'org.toshi',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Argent',
      coins: [WalletCoin.eth],
      type: WalletType.nonCustodial,
      androidPackage: 'im.argent.contractwallet',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Zerion',
      coins: [WalletCoin.eth, WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'io.zerion.android',
      category: 'Ethereum',
    ),
    WalletDefinition(
      name: 'Rabby',
      coins: [WalletCoin.eth],
      type: WalletType.nonCustodial,
      androidPackage: null, // Extension/desktop only
      category: 'Ethereum',
    ),

    // ── Solana ────────────────────────────────────────────────
    WalletDefinition(
      name: 'Phantom',
      coins: [WalletCoin.sol, WalletCoin.eth],
      type: WalletType.nonCustodial,
      androidPackage: 'app.phantom',
      category: 'Solana',
    ),
    WalletDefinition(
      name: 'Solflare',
      coins: [WalletCoin.sol],
      type: WalletType.nonCustodial,
      androidPackage: 'com.solflare.mobile',
      category: 'Solana',
    ),
    WalletDefinition(
      name: 'Backpack',
      coins: [WalletCoin.sol, WalletCoin.eth],
      type: WalletType.nonCustodial,
      androidPackage: 'app.backpack.exchange',
      category: 'Solana',
    ),

    // ── XRP ───────────────────────────────────────────────────
    WalletDefinition(
      name: 'Xaman',
      coins: [WalletCoin.xrp],
      type: WalletType.nonCustodial,
      androidPackage: 'com.xrpllabs.xumm',
      category: 'XRP',
    ),

    // ── Monero ────────────────────────────────────────────────
    WalletDefinition(
      name: 'Monerujo',
      coins: [WalletCoin.xmr],
      type: WalletType.nonCustodial,
      androidPackage: 'com.m2049r.xmrwallet',
      category: 'Monero',
    ),
    WalletDefinition(
      name: 'Feather',
      coins: [WalletCoin.xmr],
      type: WalletType.nonCustodial,
      androidPackage: null, // Desktop only
      category: 'Monero',
    ),
    WalletDefinition(
      name: 'Wownerujo',
      coins: [WalletCoin.wow],
      type: WalletType.nonCustodial,
      androidPackage: 'com.wownero.wownerujo',
      category: 'Wownero',
    ),
    WalletDefinition(
      name: 'Wowlet',
      coins: [WalletCoin.wow],
      type: WalletType.nonCustodial,
      androidPackage: null, // Desktop only
      category: 'Wownero',
    ),

    // ── Multi-chain ───────────────────────────────────────────
    WalletDefinition(
      name: 'Atomic Wallet',
      coins: [WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'io.atomicwallet',
      category: 'Multi-chain',
    ),
    WalletDefinition(
      name: 'Guarda',
      coins: [WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'com.guarda.ethereum',
      category: 'Multi-chain',
    ),
    WalletDefinition(
      name: 'Coinomi',
      coins: [WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'com.coinomi.wallet',
      category: 'Multi-chain',
    ),

    // ── Hardware ──────────────────────────────────────────────
    WalletDefinition(
      name: 'Ledger Live',
      coins: [WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'com.ledger.live',
      category: 'Hardware',
    ),
    WalletDefinition(
      name: 'Trezor',
      coins: [WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: 'io.trezor.suite',
      category: 'Hardware',
    ),
    WalletDefinition(
      name: 'Coldcard',
      coins: [WalletCoin.btc],
      type: WalletType.nonCustodial,
      androidPackage: null, // Hardware device, no app
      category: 'Hardware',
    ),
    WalletDefinition(
      name: 'BitBox',
      coins: [WalletCoin.multi],
      type: WalletType.nonCustodial,
      androidPackage: null, // Hardware device, no app
      category: 'Hardware',
    ),

    // ── Custodial / Exchange ──────────────────────────────────
    WalletDefinition(
      name: 'ZBD',
      coins: [WalletCoin.btcLightning],
      type: WalletType.custodial,
      androidPackage: 'io.zebedee.wallet',
      category: 'Custodial',
    ),
    WalletDefinition(
      name: 'Kraken',
      coins: [WalletCoin.multi],
      type: WalletType.custodial,
      androidPackage: 'com.kraken.trade',
      category: 'Custodial',
    ),
    WalletDefinition(
      name: 'Coinbase',
      coins: [WalletCoin.multi],
      type: WalletType.custodial,
      androidPackage: 'com.coinbase.android',
      category: 'Custodial',
    ),
    WalletDefinition(
      name: 'Binance',
      coins: [WalletCoin.multi],
      type: WalletType.custodial,
      androidPackage: 'com.binance.dev',
      category: 'Custodial',
    ),
    WalletDefinition(
      name: 'Bitfinex',
      coins: [WalletCoin.multi],
      type: WalletType.custodial,
      androidPackage: 'com.bitfinex.bfxapp',
      category: 'Custodial',
    ),
    WalletDefinition(
      name: 'Strike',
      coins: [WalletCoin.btcLightning],
      type: WalletType.custodial,
      androidPackage: 'com.strike.android',
      category: 'Custodial',
    ),
    WalletDefinition(
      name: 'Cash App',
      coins: [WalletCoin.btc],
      type: WalletType.custodial,
      androidPackage: 'com.squareup.cash',
      category: 'Custodial',
    ),
  ];

  /// Returns a coin label string for display
  static String coinLabel(WalletCoin coin) {
    switch (coin) {
      case WalletCoin.xno: return 'XNO';
      case WalletCoin.ban: return 'BAN';
      case WalletCoin.btc: return 'BTC';
      case WalletCoin.btcLightning: return 'BTC Lightning';
      case WalletCoin.eth: return 'ETH';
      case WalletCoin.sol: return 'SOL';
      case WalletCoin.xrp: return 'XRP';
      case WalletCoin.xmr: return 'XMR';
      case WalletCoin.wow: return 'WOW';
      case WalletCoin.multi: return 'Multi';
    }
  }
}
