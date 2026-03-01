import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'manage_wallets_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeldrinoApp());
}

class MeldrinoApp extends StatelessWidget {
  const MeldrinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meldrino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          surface: Color(0xFF1A1A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
          ),
        ),
      ),
      home: const StartupRouter(),
    );
  }
}

class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final wallets = prefs.getStringList('wallets') ?? [];
    if (!mounted) return;
    if (wallets.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const ManageWalletsScreen(isFirstTime: true)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}