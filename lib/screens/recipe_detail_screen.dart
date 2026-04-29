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
      SnackBar(
        content: Text('Your rating: $r ★', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.recipe.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Умная функция выбора иконки, как на других экранах
  Map<String, dynamic> _getIconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('avocado') || lower.contains('guacamole')) {
      return {'icon': Icons.eco};
    } else if (lower.contains('berry') || lower.contains('smoothie')) {
      return {'icon': Icons.emoji_food_beverage};
    } else if (lower.contains('salmon') || lower.contains('fish') || lower.contains('tuna')) {
      return {'icon': Icons.set_meal};
    } else if (lower.contains('salad') || lower.contains('green')) {
      return {'icon': Icons.ramen_dining};
    } else if (lower.contains('egg') || lower.contains('omelette') || lower.contains('scrambled')) {
      return {'icon': Icons.egg};
    } else if (lower.contains('pasta') || lower.contains('noodle') || lower.contains('spaghetti')) {
      return {'icon': Icons.restaurant_menu};
    } else if (lower.contains('coffee') || lower.contains('tea') || lower.contains('drink') || lower.contains('juice')) {
      return {'icon': Icons.local_cafe};
    }
    return {'icon': Icons.food_bank};
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final averageRating = RecipeRatingStore.getAverage(r);
    final totalVotes = RecipeRatingStore.getVotes(r);
    final iconData = _getIconFor(r.name);
    
    // Динамическая тень на основе цвета рецепта
    final recipeShadow = BoxShadow(
      color: r.color.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 8),
    );

    return Layout(
      showNav: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ШАПКА СВЕТЯЩАЯСЯ ---
              Stack(
                children: [
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Эффект свечения сзади иконки
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: r.color.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: r.color.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)
                              ],
                            ),
                          ),
                          Icon(iconData['icon'], size: 90, color: r.color),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    child: _glassButton(
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 20,
                    child: _glassButton(
                      child: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: saved ? Colors.white : Colors.grey[700]),
                      backgroundColor: saved ? r.color : Colors.white.withOpacity(0.8),
                      onTap: _toggleSave,
                    ),
                  ),
                ],
              ),

              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- НАЗВАНИЕ И СЛОЖНОСТЬ ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: r.difficulty == 'Easy' ? r.color.withOpacity(0.15) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              r.difficulty,
                              style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w900, color: r.difficulty == 'Easy' ? r.color : Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // --- ПАРЯЩИЕ КАРТОЧКИ ХАРАКТЕРИСТИК ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(Icons.schedule_rounded, r.time, 'Time', recipeShadow),
                          _buildStatCard(Icons.local_fire_department_rounded, r.calories, 'Calories', recipeShadow),
                          _buildStatCard(Icons.people_rounded, '${r.servings}', 'Servings', recipeShadow),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- ИНГРЕДИЕНТЫ ---
                      Text('INGREDIENTS', style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      Column(
                        children: r.ingredients.map((ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [recipeShadow],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(color: r.color.withOpacity(0.15), shape: BoxShape.circle),
                                  child: Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle))),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Text(ing, style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87))),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),

                      const SizedBox(height: 32),

                      // --- ШАГИ ПРИГОТОВЛЕНИЯ ---
                      Text('INSTRUCTIONS', style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      Column(
                        children: r.instructions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final text = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [recipeShadow],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(color: r.color, borderRadius: BorderRadius.circular(10)),
                                    child: Center(
                                      child: Text('${idx + 1}', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(text, style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5, color: Colors.grey[800])),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // --- ПРЕМИУМ РЕЙТИНГ ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [recipeShadow],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rate this recipe', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (i) {
                                    final index = i + 1;
                                    final active = userRating >= index;
                                    return GestureDetector(
                                      onTap: () => _setRating(index),
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.star_rounded, color: active ? Colors.amber : Colors.grey.shade200, size: 32),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(averageRating.toStringAsFixed(1), style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.amber.shade700)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 20),
                                    ],
                                  ),
                                  Text('$totalVotes votes', style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.amber.shade700)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- ДОП. ИНФОРМАЦИЯ ---
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _infoChip(Icons.category_rounded, r.category),
                          _infoChip(Icons.people_rounded, '${r.servings} servings'),
                        ],
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, BoxShadow shadow) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [shadow],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black87, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback onTap, Color? backgroundColor}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}