import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/camera_scan_screen.dart';
import 'screens/result_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/register_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/full_history_screen.dart';
import 'screens/recipes_screen.dart';
import 'widgets/bottom_nav.dart';

void main() {
  runApp(const FreshScanApp());
}

class FreshScanApp extends StatelessWidget {
  const FreshScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshScan',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const BottomNavBar(),
        '/scan': (context) => const CameraScanScreen(),
        '/results': (context) => const ResultScreen(),
        '/compare': (context) => const CompareScreen(),
        '/converter': (context) => const ConverterScreen(),
        '/history': (context) => const FullHistoryScreen(),
        '/recipes': (context) => const RecipesScreen(),
      },
    );
  }
}
