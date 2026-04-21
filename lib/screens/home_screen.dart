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
  @override
  Widget build(BuildContext context) {
    // Получаем текущего авторизованного пользователя
    final User? user = FirebaseAuth.instance.currentUser;

    // Статичные предложения рецептов
    final suggestions = [
      Recipe(id: 1, name: 'Avocado Toast', time: '15m', rating: 4.7, calories: '220 kcal', difficulty: 'Easy', category: 'Breakfast', servings: 1, ingredients: ['Bread','Avocado'], instructions: ['Toast bread','Smash avocado'], color: const Color(0xFF86BC25)),
      Recipe(id: 2, name: 'Berry Smoothie', time: '10m', rating: 4.5, calories: '150 kcal', difficulty: 'Easy', category: 'Drinks', servings: 1, ingredients: ['Berries','Yogurt'], instructions: ['Blend ingredients'], color: const Color(0xFFD946EF)),
      Recipe(id: 3, name: 'Salmon Salad', time: '25m', rating: 4.6, calories: '320 kcal', difficulty: 'Medium', category: 'Lunch', servings: 2, ingredients: ['Salmon','Lettuce'], instructions: ['Cook salmon','Assemble salad'], color: const Color(0xFFFF6B6B)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_rounded, color: Color(0xFF2ECC71), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HOME',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'FreshScan dashboard',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Action Card: Start Scan ---
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/scan'),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Start Scan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('Analyze ingredients', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Tools Grid ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/compare'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E3),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.trending_up, color: Color(0xFF2ECC71)),
                          SizedBox(height: 12),
                          Text('Compare Prices', style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('Market Deals', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/converter'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8F3),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.calculate, color: Color(0xFF2ECC71)),
                          SizedBox(height: 12),
                          Text('Unit Tool', style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('Kitchen Math', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Real Recent Scans Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Scans', style: TextStyle(letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.w900)),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('View all', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 180,
              child: user == null
                  ? const Center(child: Text("Please log in to see history"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('saved_scans')
                          .orderBy('timestamp', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        
                        if (docs.isEmpty) {
                          return const Center(child: Text("No scans yet", style: TextStyle(color: Colors.grey)));
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final bgColors = [const Color(0xFFE0F5F0), const Color(0xFFEDE9F3), const Color(0xFFE8F3FC)];
                            
                            // Форматирование даты
                            String timeText = "Just now";
                            if (data['timestamp'] != null) {
                              final date = (data['timestamp'] as Timestamp).toDate();
                              timeText = DateFormat.MMMd().format(date);
                            }

                            final bool isSafe = data['status']?.toString().toUpperCase() == 'SAFE';

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/results', arguments: data),
                                child: Container(
                                  width: 180,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: bgColors[index % bgColors.length],
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Icon(
                                          isSafe ? Icons.check_circle : Icons.warning_amber_rounded, 
                                          color: isSafe ? Colors.green : Colors.redAccent
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        data['productName'] ?? 'Unknown', 
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(timeText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

            const SizedBox(height: 24),

            // --- Cook Suggestions ---
            const Text('Cook suggestions', style: TextStyle(letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Column(
              children: suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: s, initiallySaved: false)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: s.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.restaurant_menu, color: Colors.black54),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(s.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(s.difficulty, style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // --- Show More Recipes Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/recipes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Show More Recipes', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}