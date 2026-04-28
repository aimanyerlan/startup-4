import 'package:flutter/material.dart';
import 'package:my_app/widgets/layout.dart';
// 1. Подключаем Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    bool hasError = false;

    if (name.isEmpty) {
      _nameError = 'Введите имя';
      hasError = true;
    }

    if (email.isEmpty) {
      _emailError = 'Введите email';
      hasError = true;
    } else if (!_emailRegex.hasMatch(email)) {
      _emailError = 'Некорректный email';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Введите пароль';
      hasError = true;
    } else if (password.length < 8) {
      _passwordError = 'Минимум 8 символов';
      hasError = true;
    }

    if (confirm.isEmpty) {
      _confirmError = 'Подтвердите пароль';
      hasError = true;
    } else if (confirm != password) {
      _confirmError = 'Пароли не совпадают';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Исправьте ошибки в форме')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. НАСТОЯЩАЯ РЕГИСТРАЦИЯ В FIREBASE
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final nameParts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        await user.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': '',
          'birthday': '',
          'location': '',
          'gender': 'male',
          'photoPath': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // Если регистрация прошла успешно:
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аккаунт успешно создан! 🎉'), 
            backgroundColor: Color(0xFF10B981)
          ),
        );
        // Перекидываем на главную (кнопка "Назад" больше не будет работать)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      // 3. ОБРАБОТКА ОШИБОК FIREBASE (Например, такой email уже есть)
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = 'Ошибка регистрации';
        
        if (e.code == 'weak-password') {
          errorMessage = 'Пароль слишком простой';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Аккаунт с таким email уже существует';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неизвестная ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      showNav: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF9FAFB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join FreshScan today',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    errorText: _nameError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _passwordError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    errorText: _confirmError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Create Account',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: const TextStyle(
                                color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}