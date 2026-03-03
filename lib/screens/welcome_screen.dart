import 'package:flutter/material.dart';

// emerald green color used across the app
const Color _emerald = Color(0xFF10B981);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF9FAFB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo with shadow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _emerald,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _emerald.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shopping_basket, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 40),
                // Title
                const Text(
                  'FreshScan',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Subtitle/Description
                const Text(
                  'Your intelligent kitchen companion for smarter grocery choices',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(flex: 2),
                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Log In button - filled
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/auth');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
