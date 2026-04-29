import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/models/recipe.dart';
import 'package:my_app/screens/recipe_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryGreen = const Color(0xFF2ECC71);

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final suggestions = [
      Recipe(id: 1, name: 'Avocado Toast', time: '15m', rating: 4.7, calories: '220 kcal', difficulty: 'Easy', category: 'Breakfast', servings: 1, ingredients: ['Bread', 'Avocado'], instructions: ['Toast bread', 'Smash avocado'], color: const Color(0xFF86BC25)),
      Recipe(id: 2, name: 'Berry Smoothie', time: '10m', rating: 4.5, calories: '150 kcal', difficulty: 'Easy', category: 'Drinks', servings: 1, ingredients: ['Berries', 'Yogurt'], instructions: ['Blend ingredients'], color: const Color(0xFFD946EF)),
      Recipe(id: 3, name: 'Salmon Salad', time: '25m', rating: 4.6, calories: '320 kcal', difficulty: 'Medium', category: 'Lunch', servings: 2, ingredients: ['Salmon', 'Lettuce'], instructions: ['Cook salmon', 'Assemble salad'], color: const Color(0xFFFF6B6B)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.dashboard_rounded, color: Colors.black87, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'FreshScan',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            CircleAvatar(
              radius: 22,
              backgroundColor: primaryGreen.withOpacity(0.15),
              child: Icon(Icons.person_rounded, color: primaryGreen, size: 24),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ГЛАВНАЯ КНОПКА СКАНЕРА ---
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/scan'),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2ECC71).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Product', style: GoogleFonts.lato(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('Discover what is inside your food instantly', style: GoogleFonts.lato(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // --- ИНСТРУМЕНТЫ (COMPARE & CONVERTER) ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/compare'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.trending_up_rounded, color: Colors.orange),
                          ),
                          const SizedBox(height: 16),
                          Text('Compare\nPrices', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/converter'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.calculate_rounded, color: Colors.purple),
                          ),
                          const SizedBox(height: 16),
                          Text('Unit\nTool', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- НЕДАВНИЕ СКАНЫ ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT SCANS', style: GoogleFonts.lato(letterSpacing: 1.2, color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w900)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/history'),
                  child: Text('View All', style: GoogleFonts.lato(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 180,
              child: user == null
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.grey.shade200)),
                      child: const Center(child: Text("Please log in to see history", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('scan_history').orderBy('timestamp', descending: true).limit(5).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.grey.shade200)),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  const Text("No scans yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            String timeText = "Just now";
                            if (data['timestamp'] != null) {
                              final date = (data['timestamp'] as Timestamp).toDate();
                              timeText = DateFormat.MMMd().format(date);
                            }
                            final statusText = data['status']?.toString().toUpperCase() ?? '';
                            final bool isSafe = statusText.contains('SAFE');

                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/results', arguments: data),
                                child: Container(
                                  width: 160,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(color: isSafe ? primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
                                    ],
                                    border: Border.all(color: isSafe ? primaryGreen.withOpacity(0.3) : Colors.red.withOpacity(0.3), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSafe ? primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(isSafe ? Icons.check_circle_rounded : Icons.warning_rounded, color: isSafe ? primaryGreen : Colors.redAccent),
                                      ),
                                      const Spacer(),
                                      Text(
                                        data['productName'] ?? 'Unknown Product',
                                        style: GoogleFonts.lato(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(timeText, style: GoogleFonts.lato(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            const SizedBox(height: 32),

            // --- ПОДСКАЗКИ РЕЦЕПТОВ ---
            Text('COOK SUGGESTIONS', style: GoogleFonts.lato(letterSpacing: 1.2, color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Column(
              children: suggestions.map((s) {
                // Выбираем иконку по названию
                IconData rIcon = Icons.restaurant;
                if (s.name.contains('Avocado')) rIcon = Icons.eco;
                if (s.name.contains('Berry')) rIcon = Icons.emoji_food_beverage;
                if (s.name.contains('Salmon')) rIcon = Icons.set_meal;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: s, initiallySaved: false))),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: s.color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: s.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(rIcon, color: s.color, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(s.time, style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(s.calories, style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: s.difficulty == 'Easy' ? primaryGreen.withOpacity(0.1) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s.difficulty, style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w900, color: s.difficulty == 'Easy' ? primaryGreen : Colors.orange.shade700)),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/recipes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Explore All Recipes', style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}