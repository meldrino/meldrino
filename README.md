# Meldrino

> **A universal crypto portfolio tracker for every chain, every wallet, every ecosystem.**

---

## The Name

**Meldrino** is a coined word with deliberate meaning baked in:

- **Meld** — to merge or blend together. This is exactly what the app does: it melds incompatible blockchains, wallets, and ecosystems into a single unified view.
- **-rino** — an Italian diminutive suffix (as in *bambino*) that subconsciously suggests something small, slim, and elegant. The ethos is lean, fast code with no bloat.

**Meldro** was considered but rejected — it feels abrupt and truncated. Meldrino trips off the tongue more naturally and has better cadence.

Both **meldrino.com** and **meldrinowallet.com** have been confirmed unregistered via ICANN lookup.

---

## The Concept

A publicly available mobile app (Flutter — iOS & Android) that allows any user to enter their wallet addresses across multiple blockchains and see a unified dashboard of their entire crypto portfolio — including assets from blockchains that are architecturally incompatible with each other.

---

## The Gap in the Market

Existing apps (Zerion, DeBank, Zapper, CoinStats, Delta) are predominantly EVM-focused. Non-EVM chains like Nano are ignored, and cross-ecosystem NFT support is essentially nonexistent. Meldrino fills that gap.

Even at MVP stage, Meldrino will surpass all existing portfolio trackers in breadth of support.

---

## Core Features

- Multi-wallet, multi-chain balance tracking (EVM and non-EVM)
- Unified NFT gallery — including Nanswap NaNFTs alongside ERC-721/1155 NFTs
- Live fiat valuations via price feeds (CoinGecko)
- Read-only, no custody, no mandatory login — privacy respecting
- Any user can add their own wallet addresses per chain
- Supports both custodial and non-custodial wallets

---

## Technical Approach

- **Framework:** Flutter (single codebase for Android + iOS)
- **EVM chains:** Alchemy, Moralis or Etherscan APIs for balances + NFTs
- **Nano/NaNFTs:** Nanswap API + Nano RPC
- **Other non-EVM chains:** Bitcoin (Blockchain.com), Solana RPC, XRP etc.
- **Price data:** CoinGecko API

---

## Custodial Wallet Support

The app supports both custodial and non-custodial wallets. Custodial wallets require the user to provide a read-only API key or use an OAuth-style login. API keys never leave the user's device.

**Specific custodial wallets identified for integration:**

- **ZBD** — Bitcoin Lightning custodial wallet with developer API and potential OAuth login. Strong differentiator for the gaming/earning audience.
- **Kraken** — Standard exchange API with read-only key support.
- **Chainers Farm** — Web3 game on a Polygon sidechain via Immutable Passport. Likely custodial via Google/email login. Immutable has a public API that may allow asset reading without Chainers' direct cooperation. Two wallets may exist per user — an Immutable Passport wallet and a Chainers internal wallet.
- **Enjin Excavators / NFT.io** — Part of the broader Enjin multiverse. Enjin has its own blockchain, API, and SDKs. Supporting Enjin means automatically supporting all Enjin-based games.

---

## The Universal Vision

Meldrino should not maintain a fixed list of supported chains. It should be architected to support any platform with a public API — new blockchains, wallets, and games included — as they emerge.

---

## AI-Powered Discovery (Future Vision)

The long-term vision is for the app to autonomously discover and integrate new APIs without developer intervention — a self-expanding discovery engine. The Anthropic API (Claude) is a candidate for powering this but costs would scale with usage and is therefore a Phase 3 consideration.

---

## Startup Strategy / Roadmap

### Phase 1 — MVP
Build the Flutter app with manually integrated APIs for known platforms. No AI. Android first (founder can test on their own device). Already more capable than any existing portfolio tracker at launch.

### Phase 2 — Traction
Grow the user base using the MVP's unique multi-ecosystem support as the differentiator.

### Phase 3 — VC
Use traction and user demand for auto-discovery as leverage to bring in venture capital funding for the AI-powered expansion engine.

---

## Monetisation

- **Price:** $20 per year
- **Trial:** Free 3-month trial with a countdown timer visible in the app at all times — creates urgency without aggression, the cutoff is never a surprise
- **Hard cutoff:** App stops working entirely after trial if no payment received — no degraded mode, prevents users settling for reduced functionality
- **Payment method:** Crypto only — elegantly appropriate for the audience, avoids credit card processing, PCI compliance, chargebacks, and multi-jurisdiction payment law
- **Accepted currencies:** Bitcoin, Ethereum, Polygon (MATIC), Monero (privacy audience), Lightning Network, Nano (XNO — feeless and on-brand)
- **Running costs:** Expected to be negligible — purely client-side Flutter app, no proprietary backend, piggybacks on existing public APIs and RPC endpoints. Nearly all revenue is therefore profit.

---

## Development Approach

- **Framework:** Flutter — single codebase for Android and iOS simultaneously
- **Developer:** Claude (AI) writes the code, directed by the human founder
- **Version control:** This GitHub repository
- **Memory solution:** This README is the master project document. It is fed back to Claude at the start of each new session along with any relevant code files, giving Claude full project context.
- **File sync:** A PowerShell script handles committing and pushing Flutter project files to this repository at the end of each session — no manual Git commands required from the founder.
- **Human founder profile:** Non-technical but strategic. Responsible for product decisions, architecture direction, and testing.

---

## Session Workflow

At the start of each new Claude session:
1. Provide Claude with the raw URL of this README: `https://raw.githubusercontent.com/meldrino/meldrino/main/README.md`
2. Provide any relevant code files that Claude needs to work on
3. State what needs to be done that session

At the end of each session:
1. Copy any new/modified code files into the local Flutter project
2. Run the PowerShell sync script to push everything to GitHub
3. Update this README if any significant decisions were made

---

## Outstanding Decisions

- [ ] App name styling — `meldrino`, `Meldrino`, or `MELDRINO`?
- [ ] iOS simultaneously with Android, or Android first?
- [ ] Mobile only, or web version too?
- [ ] Which chains to prioritise for MVP beyond the core set
- [ ] App icon and brand identity
- [ ] Flutter and development environment setup on founder's Windows laptop

---

## Project Status

**Current stage:** Pre-development — concept fully defined, name confirmed, repository established.

**Next steps:**
1. Finalise outstanding decisions above
2. Set up Flutter development environment on founder's Windows machine
3. Create PowerShell sync script
4. Begin Flutter project structure
