import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/prediction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/scan_screen.dart';
import 'services/api_service.dart';
import 'theme/app_colors.dart';

void main() {
  // ── API connection ──────────────────────────────────────────────────────
  // Uncomment and set this to your FastAPI server address.
  //
  // Android emulator  → http://10.0.2.2:8000
  // iOS simulator     → http://localhost:8000
  // Physical device   → http://YOUR_COMPUTER_LAN_IP:8000
  // Deployed server   → https://your-api.example.com
  //
  ApiService.apiBaseUrl = 'http://localhost:8000';
  // ───────────────────────────────────────────────────────────────────────

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const FreshSenseApp(),
    ),
  );
}

class FreshSenseApp extends StatelessWidget {
  const FreshSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'FreshSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.themeMode,
      home: const ScanScreen(),
    );
  }
}
