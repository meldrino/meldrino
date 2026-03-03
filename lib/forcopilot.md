Meldrino — Master Project Reference for Copilot

This document exists so Copilot can fully understand the Meldrino project even if the original chat history is lost.
It defines:

    the architecture

    the design philosophy

    the constraints

    the current progress

    the remaining work

    the GitHub structure

    the purpose of each Dart file

    the long‑term roadmap

    the development workflow (including commit.ps1)

Copilot should load this file at the start of any new session and use it as the authoritative reference.
1. Project Overview

Meldrino is a read‑only crypto portfolio viewer.

It:

    displays balances

    displays fiat values

    displays recent transactions

    opens the user’s real wallet app

    supports multiple wallets

    supports multiple coins

    never touches private keys

    never signs transactions

    never stores seeds

It is designed to be:

    safe

    simple

    scalable

    user‑friendly

    future‑proof

2. Core Principles
2.1 No seeds, ever

Meldrino must never request, store, or handle:

    seed phrases

    private keys

    signing

    broadcasting

It is read‑only.
2.2 Users only enter:

    coin type

    label

    address

Nothing else.

Users must never be asked for:

    RPC URLs

    deep‑link schemes

    explorer URLs

    package names

    chain IDs

    anything technical

The app must be “sufficiently intelligent” to handle all of that internally.
2.3 Wallet instances vs. coin types

    Adding another wallet of an existing coin → no app update needed

    Adding a new coin ecosystem → app update is acceptable

This distinction is important.
2.4 Architecture must not depend on the coin

Each coin should not require its own Dart file unless absolutely necessary.

The app should:

    use a coin registry for metadata

    use generic UI

    use generic wallet storage

    use per‑coin service classes only when needed

3. GitHub References

Copilot should refer to:
README.md

Contains:

    project description

    installation instructions

    screenshots

    basic usage

ROADMAP.md

Contains:

    planned features

    future coins

    UX improvements

    long‑term goals

forcopilot.md (this file)

The master reference for Copilot.
lib/ folder

Contains all Dart files.

Copilot should use the GitHub repo as the source of truth for file contents.
4. Development Workflow
4.1 commit.ps1 — Purpose

A PowerShell helper script that automates the entire Git workflow:

    stages all changes

    commits them

    pushes to GitHub

It exists to prevent partial commits, forgotten commands, or messy Git history.
4.2 Location

commit.ps1 lives in the root directory of the Meldrino project, alongside:

    pubspec.yaml

    README.md

    ROADMAP.md

    forcopilot.md

If you ever forget where it is, it’s always in the project root.
4.3 Usage

From the project root, run:
Code

./commit.ps1 "Your commit message"

Example:
Code

./commit.ps1 "Implemented Nano transaction history + detail screen"

The script performs:

    git add .

    git commit -m "<message>"

    git push

No extra steps required.
4.4 When to use it

Use commit.ps1 every time you finish a meaningful chunk of work, such as:

    adding a new screen

    updating a service

    modifying the coin registry

    fixing a bug

    updating this file

    adding a new coin type

    changing UI

This keeps the repo clean and prevents losing progress.
5. Current Architecture

Below is the current structure and purpose of each file.
5.1 coin_holding.dart

A minimal data model representing a single wallet entry.

Fields:

    coin — e.g. “Nano (XNO)”

    label — user label

    address

    balance

    price

It intentionally does not contain:

    deep‑link schemes

    package names

    RPC URLs

    explorers

Those come from the coin registry.
5.2 coin_detail_screen.dart

Displays:

    balance

    fiat value

    address

    copy button

    “Open Wallet App” button

    last 5 transactions

    “Show all transactions”

    refresh

It must remain generic and pull metadata from the coin registry.
5.3 nano_service.dart

Handles:

    Nano RPC

    balance

    transaction history

    raw → XNO conversion

This is the only coin‑specific service currently implemented.
5.4 app_bar.dart

Custom app bar with refresh support.
5.5 Future files (not yet created)
coin_registry.dart

A map of coin → metadata:

    ticker

    android package

    deep‑link scheme

    explorer URL

    history provider

wallet_form.dart

Allows users to add:

    coin

    label

    address

wallet_service.dart

Generic interface for:

    fetching balance

    fetching history

Coin‑specific services implement this.
6. What Has Been Completed
✔ Multi‑wallet support
✔ Multi‑coin UI structure
✔ Nano balance + history
✔ Generic detail screen
✔ Copy address
✔ Open external wallet
✔ Refresh
✔ Expand transaction history
✔ Clean architecture direction
✔ Safety model (read‑only, no seeds)
✔ Project philosophy defined
✔ Development workflow (commit.ps1) documented
7. What Still Needs To Be Done
7.1 Implement the coin registry

A built‑in map that defines:

    ticker

    android package

    deep‑link

    explorer

    history provider

This removes coin‑specific logic from the UI.
7.2 Implement wallet_form.dart

User flow:

    Choose coin

    Enter address

    Enter label

    Save

No technical fields.
7.3 Implement wallet storage

Likely using:

    shared_preferences

    or local JSON

7.4 Implement additional coin services

Examples:

    Ethereum

    Bitcoin

    Monero

    Solana

    Cardano

Each service handles:

    balance

    history

    formatting

7.5 Implement “lost coin scanning”

This is a future feature.

Goal:

    Scan a wallet address using multiple explorers / RPC endpoints to detect coins or tokens the user may not know they have.

Examples:

    ERC‑20 tokens

    ERC‑721 NFTs

    SPL tokens

    UTXOs

    sidechain balances

This requires:

    multi‑RPC querying

    token enumeration

    explorer fallbacks

This is a long‑term feature.
7.6 Implement portfolio aggregation

Sum:

    total fiat value

    per‑coin totals

    per‑wallet totals

7.7 Implement settings

Examples:

    fiat currency

    theme

    refresh interval

8. How Copilot Should Use This File

When this file is pasted into a new session:

    Load the architecture described here

    Understand the project is read‑only

    Understand users only enter coin + label + address

    Understand the app must be intelligent, not the user

    Understand the UI must be generic

    Understand coin metadata comes from the registry

    Understand services handle coin logic

    Provide full Dart files, never snippets

    Use the GitHub repo for file contents

    Continue development from the roadmap

    Use commit.ps1 for all commits

End of forcopilot.md
