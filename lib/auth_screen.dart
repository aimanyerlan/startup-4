import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Импортируем наш будущий навигатор:
import 'widgets/bottom_nav.dart'; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  // Функция обычного входа (по email/паролю)
  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        // После успеха переходим на главный экран с нижним меню!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // НОВАЯ ФУНКЦИЯ: Вход как Гость
  Future<void> loginAsGuest() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        // Успешно вошли как гость -> идем на главный экран
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка гостевого входа: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {}, // Заглушка для кнопки назад
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              
              // Поле Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Поле Пароль
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // КНОПКА ГОСТЯ С ПРИВЯЗАННОЙ ФУНКЦИЕЙ
              TextButton(
                onPressed: loginAsGuest, 
                child: const Text('Continue as Guest', style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              Row(
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Create Account', style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Кнопка Sign In
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}