import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart'; 
import 'widgets/bottom_nav.dart'; 

import 'screens/welcome_screen.dart';
import 'screens/register_screen.dart'; 
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
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const BottomNavBar(),
        
        '/register': (context) => const RegisterScreen(), 
        
        '/converter': (context) => const ConverterScreen(),
        '/compare': (context) => const CompareScreen(),
        '/scan': (context) => const CameraScanScreen(),
        '/history': (context) => const FullHistoryScreen(),
        '/recipes': (context) => const RecipesScreen(),
        '/results': (context) => ResultScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/saved': (context) => const SavedProductsScreen(),
      },
    );
  }
}