import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart'; 

// 1. Импортируем все твои готовые экраны из папки screens:
import 'screens/home_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/camera_scan_screen.dart';
import 'screens/full_history_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/result_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const FreshScanApp());
}

class FreshScanApp extends StatelessWidget {
  const FreshScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshScan',
      debugShowCheckedModeBanner: false, // Убираем красную полоску DEBUG в углу
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
      
      // 2. Связываем названия путей с твоими файлами:
      routes: {
        '/home': (context) => const HomeScreen(),
        '/converter': (context) => const ConverterScreen(),
        '/compare': (context) => const CompareScreen(),
        '/scan': (context) => const CameraScanScreen(),
        '/history': (context) => const FullHistoryScreen(),
        '/recipes': (context) => const RecipesScreen(),
        '/results': (context) => const ResultScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/saved': (context) => const SavedProductsScreen(),
      },
    );
  }
}