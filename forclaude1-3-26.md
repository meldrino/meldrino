# Meldrino — Session Handoff Document

## Project Overview
Meldrino is a Flutter crypto portfolio tracker app (Android first, then iOS).
Read the full README at: https://raw.githubusercontent.com/meldrino/meldrino/main/README.md
Read the full roadmap at: https://raw.githubusercontent.com/meldrino/meldrino/main/roadmap.md

## Current Status
- Phases 1 and 2 complete
- Phase 3 in progress
- ZBD custodial wallet integration attempted but not yet working

## Development Setup
- Flutter app located at: C:\meldrino_app
- All dart files in: C:\meldrino_app\lib
- GitHub repo: https://github.com/meldrino/meldrino
- To push to GitHub: run .\commit.ps1 from C:\meldrino_app
- To run app: flutter run from C:\meldrino_app
- Test device: Pixel 8 (Android)

## Dart Files in lib\
- main.dart
- app_bar.dart
- coin_holding.dart
- home_screen.dart
- manage_wallets_screen.dart
- nano_service.dart
- price_service.dart
- settings_screen.dart
- coin_detail_screen.dart
- zbd_service.dart
- zbd_connect_screen.dart

## Current Dart Files on GitHub
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/main.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/app_bar.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/home_screen.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/settings_screen.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/manage_wallets_screen.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/coin_detail_screen.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/coin_holding.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/nano_service.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/price_service.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/zbd_service.dart
https://raw.githubusercontent.com/meldrino/meldrino/main/lib/zbd_connect_screen.dart

## pubspec.yaml dependencies
- flutter
- cupertino_icons: ^1.0.8
- shared_preferences: ^2.5.4
- http: ^1.6.0
- url_launcher: ^6.3.2
- web_socket_channel: ^2.4.0

## AndroidManifest.xml location
C:\meldrino_app\android\app\src\main\AndroidManifest.xml
Required permissions already added:
- android.permission.INTERNET
- android.permission.CAMERA (can be removed if not needed)

---

## ZBD Integration — Current State and Problem

### What ZBD Is
ZBD is a custodial Bitcoin Lightning wallet app. We want to show the user's sat balance in Meldrino alongside their Nano holdings.

### Why It's Hard
- ZBD has no public user API — only a developer API requiring KYC and an invite code
- OAuth requires registering as a ZBD developer — also requires KYC
- The founder refuses to give ZBD any personal details (fair enough)

### The Solution We Found
By reverse engineering the ZBD Chrome browser extension, we discovered ZBD uses an undocumented internal WebSocket API for QR-based authentication:

**WebSocket URL:** wss://api.zebedee.io/api/internal/v1/qrauth-socket

**Auth flow:**
1. Connect to WebSocket
2. Send: {"type":"internal-connection-sub-qr-auth","data":{"browserOS":"Android","browserName":"Chrome","QRCodeZClient":"browser-extension"}}
3. Receive: {"type":"internal-hash-retrieved","data":"{hash}"}
4. The hash gets encoded into a QR URL: https://zebedee.io/qrauth/{hash}?QRCodeZClient=browser-extension
5. User scans QR with ZBD app → sees "Connect to Z Browser Extension" screen → taps Connect
6. Receive: {"type":"QR_CODE_AUTH_USER_DATA","data":{"username":"...","image":"..."}}
7. Receive: {"type":"QR_CODE_AUTH_USER_ACCEPT","data":{"token":"eyJ..."}}
8. Save JWT token to SharedPreferences
9. Use JWT as Bearer token for all subsequent API calls

**Balance endpoint:** GET https://api.zebedee.io/api/internal/v1/wallet
**Headers required:** Authorization: Bearer {jwt}, z-client: browser-extension
**Response:** balance in millisatoshis — divide by 1000 for sats, divide by 100000000 for BTC

**Username endpoint:** GET https://api.zebedee.io/api/internal/v1/me

### The One Remaining Problem
The user only has one phone. The ZBD app needs to scan a QR code, but Meldrino IS on that same phone — a phone can't scan its own screen.

**Current workaround approach:**
The website https://browser-extension.zebedee.io shows the same ZBD auth QR code. So the connect flow is:
1. User taps Connect ZBD in Meldrino
2. Meldrino shows instructions: go to browser-extension.zebedee.io on your PC
3. User taps "Ready — connect now" button — Meldrino connects to WebSocket and listens
4. User goes to browser-extension.zebedee.io on PC, scans QR with ZBD app, taps Connect
5. Token arrives via WebSocket in Meldrino

**Current bug:** The waiting screen appears but the token never arrives. The WebSocket connection may be timing out or the hash from browser-extension.zebedee.io and the hash Meldrino generates are different sessions — they need to be the SAME WebSocket session. This is the core bug to fix next session.

### Possible Fix to Investigate
The issue is likely that browser-extension.zebedee.io opens its OWN WebSocket session with its own hash. Meldrino opens a SEPARATE WebSocket session with a different hash. The user scans the PC's QR (PC's hash) but Meldrino is listening on its own different session. They never match.

**Solution options:**
1. Make Meldrino display ITS OWN hash/QR somehow on the PC — e.g. show the URL as text, user pastes into PC browser, PC renders that specific QR
2. Build a tiny static HTML page that takes a hash as a URL parameter and renders a QR — host it on GitHub Pages for free. Meldrino generates hash, constructs URL like https://meldrino.github.io/qr?h={hash}, user opens on PC, scans, done.
3. Find another way entirely

Option 2 (GitHub Pages QR page) is probably the cleanest solution. It's a one-page static HTML file, costs nothing to host, and means Meldrino controls the session end to end.

---

## What Works So Far
- App loads and shows Nano balances correctly
- Fiat currency switching (USD/GBP/EUR) works in settings
- Add/edit/delete non-custodial wallets works
- Manage wallets screen has ZBD connect/disconnect section
- Home screen shows ZBD balance when token is stored
- Internet permission fixed in AndroidManifest.xml

## Founder Profile
Non-technical but strategic. Directs Claude to write all code. Tests on his own Pixel 8. Hates giving up on problems. Does not want to give ZBD or any third party personal details.

## Next Steps
1. Fix ZBD WebSocket session mismatch problem (see above)
2. Consider GitHub Pages QR page as the solution
3. Once ZBD working, move to next wallet/coin on roadmap
4. Phase 3 items still to complete: price movement graph on coin detail screen, multi-wallet combined totals
