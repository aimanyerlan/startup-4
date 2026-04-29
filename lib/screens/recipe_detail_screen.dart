import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/widgets/layout.dart';
import 'package:my_app/models/recipe.dart';
import 'package:my_app/models/recipe_rating_store.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool initiallySaved;

  const RecipeDetailScreen({Key? key, required this.recipe, this.initiallySaved = false}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool saved = false;
  int userRating = 0;

  @override
  void initState() {
    super.initState();
    saved = widget.initiallySaved;
    userRating = RecipeRatingStore.getUserRating(widget.recipe.id);
  }

  void _toggleSave() {
    setState(() {
      saved = !saved;
    });
  }

  void _setRating(int r) {
    setState(() {
      userRating = r;
      RecipeRatingStore.setUserRating(widget.recipe, r);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Your rating: $r ★')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final primaryGreen = const Color(0xFF2ECC71);
    final averageRating = RecipeRatingStore.getAverage(r);
    final totalVotes = RecipeRatingStore.getVotes(r);

    return Layout(
      showNav: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 280,
                      width: double.infinity,
                      color: r.color,
                      child: Center(
                        child: Opacity(
                          opacity: 0.3,
                          child: Icon(Icons.restaurant, size: 120, color: Colors.white),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 16,
                      left: 16,
                      child: _glassButton(
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),

                    Positioned(
                      top: 16,
                      right: 16,
                      child: _glassButton(
                        child: Icon(Icons.favorite, color: saved ? Colors.white : Colors.grey),
                        backgroundColor: saved ? primaryGreen : Colors.white.withOpacity(0.9),
                        onTap: _toggleSave,
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name.toUpperCase(), style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _statItem(Icons.schedule, r.time),
                          const SizedBox(width: 12),
                          _statItem(Icons.local_fire_department, r.calories, iconColor: Colors.orange),
                          const SizedBox(width: 12),
                          _statItem(Icons.person, '${r.servings} servings', iconColor: Colors.blueAccent),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: r.difficulty == 'Easy' ? primaryGreen.withOpacity(0.1) : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(r.difficulty, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w900, color: r.difficulty == 'Easy' ? primaryGreen : Colors.orange.shade700)),
                      ),

                      const SizedBox(height: 20),

                      Text('INGREDIENTS', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Column(
                        children: r.ingredients.map((ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), shape: BoxShape.circle),
                                  child: Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(ing, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700))),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),

                      const SizedBox(height: 20),

                      Text('INSTRUCTIONS', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Column(
                        children: r.instructions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final text = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 16, backgroundColor: Colors.black, child: Text('${idx+1}', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
                                const SizedBox(width: 12),
                                Expanded(child: Text(text, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700))),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade100)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(5, (i) {
                                final index = i + 1;
                                final active = userRating >= index;
                                return GestureDetector(
                                  onTap: () => _setRating(index),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Icon(Icons.star, color: active ? Colors.amber : Colors.grey.shade300, size: 28),
                                  ),
                                );
                              }),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(averageRating.toStringAsFixed(1), style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('$totalVotes ratings', style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RECIPE INFO', style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _infoChip(Icons.category_outlined, r.category),
                                _infoChip(Icons.bolt_outlined, r.difficulty),
                                _infoChip(Icons.people_outline, '${r.servings} servings'),
                                _infoChip(Icons.local_fire_department_outlined, r.calories),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[800])),
      ],
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback onTap, Color? backgroundColor}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: backgroundColor ?? Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
