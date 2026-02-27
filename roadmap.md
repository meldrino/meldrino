# Meldrino — Roadmap

## Phase 1 — Development Environment
Set up all tools needed to build and manage the project:
- **Flutter SDK** — the app framework
- **Android Studio** — required by Flutter for Android build tools and emulator, even if not used directly for coding
- **VS Code** — primary coding environment
- **Git** — version control
- **GitHub repository** — already created at github.com/meldrino/meldrino
- **PowerShell sync script** — run at the end of each session to commit and push all project files to GitHub; prompts the founder for a brief description which becomes the commit message

## Phase 2 — Basic App (Nano only, balances only)
Build the home screen with a single coin (Nano / XNO). This phase is deceptively large — every design and layout decision made here sets the pattern for the entire app.

**Home screen layout:** Each row displays one holding in the following column order:
- Coin icon (fixed width, left anchor)
- Coin name
- Wallet (user-defined label assigned when the wallet is added — e.g. "Nautilus", "Kraken". The app has no way to detect which wallet app the user is using, so this is always user-supplied)
- Fiat value (prominent)
- Ticker (e.g. XNO, BTC — less prominent, rightmost)

**Sorting:** Rows sorted by fiat value, highest first. Fiat value is always the comparator, never token quantity.

**Multiple wallets, same coin:** It is valid and common to hold the same coin in multiple wallets (e.g. Nano in Nautilus and WeNano). Each holding appears as its own row. Coins held in more than one wallet are flagged with a flag icon. Tapping the flag reveals which wallets hold that coin and offers an optional combined total. Auto-aggregation is never imposed on the user.

**Note on same-seed wallets:** Apps like WeNano, Nautilus, and Natrium can share the same Nano seed and therefore the same address. The app does not detect this — it is the user's responsibility not to add the same address twice under different labels.

**Adding a wallet:** User enters or pastes their wallet address and assigns a label, either by typing or selecting from a list of known wallet apps for that coin. Address is validated for correct format.

**Fiat currency:** User can set their preferred fiat currency (GBP, USD, EUR etc.). Defaults to device locale. All values throughout the app respect this setting.

**Price data:** Live prices fetched from CoinGecko API.

**Nano integration:** Balance read via Nano RPC and/or Nanswap API.

## Phase 3 — Coin Detail Screen
Tapping a row on the home screen opens a detail screen for that holding. This screen shows:
- Price movement graph (is the coin going up or down?)
- If the coin is held in multiple wallets: a breakdown of each holding and the option to see a combined total
- Whether any NFTs exist for this coin/blockchain (flagged here ahead of Phase 4)

## Phase 4 — NFT Support
Add the ability to view NFT images within the app. 

- Nano NFTs (NaNFTs) via Nanswap API
- ERC-721 / ERC-1155 NFTs via Alchemy or Moralis (for EVM chains)
- Home screen gains bottom navigation with an NFT icon alongside the home button

## Phase 5 — Additional Coins and Wallets
Expand beyond Nano to support the full range of planned chains and wallets. Users add their own wallet addresses. Coin/token lists sourced from a DEX or equivalent.

**Non-custodial wallets (address-based):**
- Bitcoin (Blockchain.com API)
- Solana (Solana RPC)
- XRP
- Ethereum + ERC-20 tokens (Alchemy or Moralis)
- Polygon, BSC and other EVM-compatible chains

**Custodial wallets (API key or OAuth):**
- Kraken (read-only API key)
- ZBD — Bitcoin Lightning, OAuth login. Key differentiator for gaming/earning audience
- Immutable Passport / Chainers Farm — Web3 gaming wallet. Note: users may have two wallets (Immutable Passport wallet + Chainers internal wallet)
- Enjin — supporting Enjin automatically supports all Enjin-based games

**Architecture note:** The app should be built to support any platform with a public API. It should not maintain a rigid fixed list — new chains and wallets should be addable without restructuring the app.

## Phase 6 — Monetisation
- **Price:** $20 per year
- **Trial:** 3-month free trial with a countdown timer visible in the app at all times — never a surprise
- **Hard cutoff:** App stops working entirely on expiry. No degraded mode — prevents users settling for reduced functionality
- **Anti-abuse:** Mechanism to prevent the free trial resetting on reinstall
- **Payment:** Crypto only — avoids credit card processing, PCI compliance, chargebacks, and multi-jurisdiction payment law
- **Accepted currencies:** Bitcoin, Ethereum, Polygon (MATIC), Monero (for the privacy audience), Lightning Network, Nano (XNO — feeless and on-brand)
- **Running costs:** Expected to be negligible — purely client-side Flutter app with no proprietary backend. Nearly all revenue is therefore profit.

## Phase 7 — iOS Port
Port the Flutter app to iOS and resolve any platform-specific issues. Flutter shares the majority of code between Android and iOS but some platform-specific work will be required.

## Phase 8 — Publish
- Submit to Google Play Store
- Submit to Apple App Store
- Launch and promote

## Phase 9 — Venture Capital
Approach VCs with real traction data. The pitch: Meldrino already surpasses every existing portfolio tracker in breadth of support. The next step is an AI-powered discovery engine (using the Anthropic / Claude API) that autonomously locates and integrates new coins, chains, and wallets without developer intervention — a self-expanding app. This requires funding as API costs scale with usage.

## Phase 10 — Take the Money and Run
