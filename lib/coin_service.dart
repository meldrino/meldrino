import 'dart:convert';
import 'package:http/http.dart' as http;
import 'nano_service.dart';

/// Unified balance fetching for all supported coins.
/// Returns balance as a double (in the coin's base unit, e.g. XNO, BTC, ETH).
/// Throws an exception if the address is invalid or unreachable.
class CoinService {
  /// Returns the balance for a given address and coin ticker.
  /// Throws if the address cannot be found on the network.
  static Future<double> getBalance(String ticker, String address) async {
    switch (ticker.toUpperCase()) {
      case 'XNO':
        return await NanoService.getBalance(address);
      case 'BAN':
        return await _getBananoBalance(address);
      case 'BTC':
        return await _getBitcoinBalance(address);
      case 'ETH':
        return await _getEthereumBalance(address);
      case 'SOL':
        return await _getSolanaBalance(address);
      case 'XRP':
        return await _getXrpBalance(address);
      case 'XMR':
        // Monero requires a view key — cannot verify from address alone
        throw UnsupportedError('Monero balance cannot be verified without a view key');
      case 'WOW':
        // Wownero — same limitation as Monero
        throw UnsupportedError('Wownero balance cannot be verified without a view key');
      case 'BTC LIGHTNING':
        // Lightning is custodial/channel-based — no on-chain address to verify
        throw UnsupportedError('Lightning balance is managed by your wallet app');
      case 'MULTI':
        throw UnsupportedError('Please select a specific coin for this wallet');
      default:
        throw UnsupportedError('Balance check not yet supported for $ticker');
    }
  }

  /// Returns true if balance verification is supported for this ticker.
  static bool isVerifiable(String ticker) {
    switch (ticker.toUpperCase()) {
      case 'XNO':
      case 'BAN':
      case 'BTC':
      case 'ETH':
      case 'SOL':
      case 'XRP':
        return true;
      default:
        return false;
    }
  }

  // ── Banano ────────────────────────────────────────────────────────────────
  static Future<double> _getBananoBalance(String address) async {
    final response = await http.post(
      Uri.parse('https://kalium.banano.cc/api/node-api'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'account_balance', 'account': address}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception('Invalid Banano address');
      }
      final rawBalance = BigInt.parse(data['balance'] ?? '0');
      // Banano uses 10^29 as its raw unit
      return rawBalance / BigInt.from(10).pow(29);
    }
    throw Exception('Failed to reach Banano network');
  }

  // ── Bitcoin ───────────────────────────────────────────────────────────────
  static Future<double> _getBitcoinBalance(String address) async {
    final response = await http.get(
      Uri.parse('https://blockstream.info/api/address/$address'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // funded_txo_sum - spent_txo_sum = current balance in satoshis
      final funded = data['chain_stats']['funded_txo_sum'] as int? ?? 0;
      final spent = data['chain_stats']['spent_txo_sum'] as int? ?? 0;
      return (funded - spent) / 100000000.0; // Convert satoshis to BTC
    } else if (response.statusCode == 400) {
      throw Exception('Invalid Bitcoin address');
    }
    throw Exception('Failed to reach Bitcoin network');
  }

  // ── Ethereum ──────────────────────────────────────────────────────────────
  static Future<double> _getEthereumBalance(String address) async {
    // Using Cloudflare's free public Ethereum RPC
    final response = await http.post(
      Uri.parse('https://cloudflare-eth.com/v1/mainnet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_getBalance',
        'params': [address, 'latest'],
        'id': 1,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception('Invalid Ethereum address');
      }
      final hexBalance = data['result'] as String;
      final wei = BigInt.parse(hexBalance.substring(2), radix: 16);
      return wei / BigInt.from(10).pow(18); // Convert wei to ETH
    }
    throw Exception('Failed to reach Ethereum network');
  }

  // ── Solana ────────────────────────────────────────────────────────────────
  static Future<double> _getSolanaBalance(String address) async {
    final response = await http.post(
      Uri.parse('https://api.mainnet-beta.solana.com'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'getBalance',
        'params': [address],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception('Invalid Solana address');
      }
      final lamports = data['result']['value'] as int? ?? 0;
      return lamports / 1000000000.0; // Convert lamports to SOL
    }
    throw Exception('Failed to reach Solana network');
  }

  // ── XRP ───────────────────────────────────────────────────────────────────
  static Future<double> _getXrpBalance(String address) async {
    final response = await http.post(
      Uri.parse('https://xrplcluster.com'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'method': 'account_info',
        'params': [
          {
            'account': address,
            'ledger_index': 'current',
          }
        ],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['result'];
      if (result['error'] != null) {
        // 'actNotFound' means valid format but never funded — treat as 0 balance
        if (result['error'] == 'actNotFound') return 0.0;
        throw Exception('Invalid XRP address');
      }
      final drops = int.parse(
          result['account_data']['Balance']?.toString() ?? '0');
      return drops / 1000000.0; // Convert drops to XRP
    }
    throw Exception('Failed to reach XRP network');
  }
}
