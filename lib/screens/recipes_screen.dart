import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/widgets/layout.dart';
import 'package:my_app/models/recipe.dart';
import 'package:my_app/models/recipe_rating_store.dart';
import 'package:my_app/screens/recipe_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/admin_add_recipe_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final Color primaryGreen = const Color(0xFF2ECC71);

  List<Recipe> allRecipes = [];
  Set<int> saved = {};

  String selectedCategory = 'All';
  String searchQuery = '';
  bool showRecent = false;
  bool isLoading = true; 

  final FocusNode _searchFocus = FocusNode();

  final recentSearches = ['Pasta', 'Salad', 'Smoothie'];

  final categories = [
    'All',
    'Saved',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Drinks',
  ];

  String _getEmojiForCategory(String cat) {
    switch (cat) {
      case 'Breakfast': return '🍳';
      case 'Lunch': return '🥗';
      case 'Dinner': return '🍝';
      case 'Drinks': return '🍹';
      case 'Saved': return '❤️';
      case 'All': return '✨';
      default: return '🍽️';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecipesFromFirebase(); 
    
    _searchFocus.addListener(() {
      setState(() {
        showRecent = _searchFocus.hasFocus;
      });
    });
  }

  Future<void> _loadRecipesFromFirebase() async {
    try {
      final collection = FirebaseFirestore.instance.collection('recipes');
      var snapshot = await collection.get();

      if (snapshot.docs.isEmpty) {
        final mockRecipes = [
          Recipe(id: 1, name: 'Avocado Toast', time: '10m', rating: 4.7, calories: '220 kcal', difficulty: 'Easy', category: 'Breakfast', servings: 1, ingredients: ['Bread', 'Avocado', 'Salt'], instructions: ['Toast bread', 'Smash avocado', 'Season to taste'], color: const Color(0xFF86BC25)),
          Recipe(id: 2, name: 'Berry Smoothie', time: '5m', rating: 4.5, calories: '150 kcal', difficulty: 'Easy', category: 'Drinks', servings: 1, ingredients: ['Berries', 'Yogurt', 'Honey'], instructions: ['Blend all ingredients'], color: const Color(0xFFD946EF)),
          Recipe(id: 3, name: 'Salmon Salad', time: '20m', rating: 4.6, calories: '320 kcal', difficulty: 'Medium', category: 'Lunch', servings: 2, ingredients: ['Salmon', 'Lettuce', 'Dressing'], instructions: ['Cook salmon', 'Assemble salad'], color: const Color(0xFFFF6B6B)),
          Recipe(id: 4, name: 'Pasta Carbonara', time: '25m', rating: 4.3, calories: '480 kcal', difficulty: 'Medium', category: 'Dinner', servings: 2, ingredients: ['Pasta', 'Eggs', 'Pancetta'], instructions: ['Cook pasta', 'Mix with sauce'], color: const Color(0xFFF97316)),
          Recipe(id: 5, name: 'Egg Omelette', time: '12m', rating: 4.4, calories: '200 kcal', difficulty: 'Easy', category: 'Breakfast', servings: 1, ingredients: ['Eggs', 'Butter', 'Salt'], instructions: ['Beat eggs', 'Cook in pan'], color: const Color(0xFFFBBF24)),
          Recipe(id: 6, name: 'Tuna Salad', time: '15m', rating: 4.2, calories: '260 kcal', difficulty: 'Easy', category: 'Lunch', servings: 1, ingredients: ['Tuna', 'Lettuce', 'Dressing'], instructions: ['Mix ingredients'], color: const Color(0xFFFF6B6B)),
          Recipe(id: 7, name: 'Green Salad', time: '8m', rating: 4.8, calories: '120 kcal', difficulty: 'Easy', category: 'Lunch', servings: 1, ingredients: ['Greens', 'Olive oil'], instructions: ['Toss ingredients'], color: const Color(0xFF2ECC71)),
          Recipe(id: 8, name: 'Iced Coffee', time: '4m', rating: 4.1, calories: '90 kcal', difficulty: 'Easy', category: 'Drinks', servings: 1, ingredients: ['Coffee', 'Ice', 'Milk'], instructions: ['Brew coffee', 'Serve over ice'], color: const Color(0xFFA855F7)),
        ];

        for (var r in mockRecipes) {
          await collection.doc(r.id.toString()).set({
            'id': r.id,
            'name': r.name,
            'time': r.time,
            'rating': r.rating,
            'calories': r.calories,
            'difficulty': r.difficulty,
            'category': r.category,
            'servings': r.servings,
            'ingredients': r.ingredients,
            'instructions': r.instructions,
            'colorValue': r.color.value, 
          });
        }
        snapshot = await collection.get();
      }

      final fetchedRecipes = snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: data['id'] ?? 0,
          name: data['name'] ?? '',
          time: data['time'] ?? '',
          rating: (data['rating'] ?? 0).toDouble(),
          calories: data['calories'] ?? '',
          difficulty: data['difficulty'] ?? '',
          category: data['category'] ?? '',
          servings: data['servings'] ?? 1,
          ingredients: List<String>.from(data['ingredients'] ?? []),
          instructions: List<String>.from(data['instructions'] ?? []),
          color: Color(data['colorValue'] ?? 0xFF2ECC71),
        );
      }).toList();

      if (mounted) {
        setState(() {
          allRecipes = fetchedRecipes;
          isLoading = false; 
        });
      }
    } catch (e) {
      debugPrint("Firestore Error: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, dynamic> _getIconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('avocado') || lower.contains('guacamole')) {
      return {'icon': Icons.eco, 'color': const Color(0xFF86BC25)};
    } else if (lower.contains('berry') || lower.contains('smoothie')) {
      return {'icon': Icons.emoji_food_beverage, 'color': const Color(0xFFD946EF)};
    } else if (lower.contains('salmon') || lower.contains('fish') || lower.contains('tuna')) {
      return {'icon': Icons.set_meal, 'color': const Color(0xFFFF6B6B)};
    } else if (lower.contains('salad') || lower.contains('green')) {
      return {'icon': Icons.ramen_dining, 'color': const Color(0xFF2ECC71)};
    } else if (lower.contains('egg') || lower.contains('omelette') || lower.contains('scrambled')) {
      return {'icon': Icons.egg, 'color': const Color(0xFFFBBF24)};
    } else if (lower.contains('pasta') || lower.contains('noodle') || lower.contains('spaghetti')) {
      return {'icon': Icons.restaurant_menu, 'color': const Color(0xFFF97316)};
    } else if (lower.contains('coffee') || lower.contains('tea') || lower.contains('drink') || lower.contains('juice')) {
      return {'icon': Icons.local_cafe, 'color': const Color(0xFFA855F7)};
    }
    return {'icon': Icons.food_bank, 'color': const Color(0xFF2ECC71)};
  }

  List<Recipe> get recommendedRecipes => allRecipes
      .where((r) => RecipeRatingStore.getAverage(r) >= 4.5)
      .take(5)
      .toList();
  List<Recipe> get popularRecipes => allRecipes
      .where((r) {
        final avg = RecipeRatingStore.getAverage(r);
        return avg >= 4.3 && avg < 4.5;
      })
      .take(5)
      .toList();
  List<Recipe> get quickRecipes => allRecipes.where((r) {
        final minutes = int.tryParse(r.time.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        return minutes <= 15;
      }).take(5).toList();

  List<Recipe> get filteredRecipes {
    return allRecipes.where((recipe) {
      final matchesCategory =
          selectedCategory == 'All' || (selectedCategory == 'Saved' && saved.contains(recipe.id)) || recipe.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty || recipe.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void toggleSave(int id) {
    setState(() {
      if (saved.contains(id)) saved.remove(id); else saved.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      showNav: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))) ,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushNamed(context, '/home');
                                }
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('RECIPES', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                    if (['leelily030203@gmail.com', 'aimanyerlan@gmail.com'].contains(FirebaseAuth.instance.currentUser?.email))
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, color: Color(0xFF2ECC71)),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const AdminAddRecipeScreen()),
                                          );
                                          _loadRecipesFromFirebase(); 
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Based on your preferences', style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
                          child: Center(child: Icon(Icons.restaurant, color: primaryGreen)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    Stack(
                      children: [
                        TextField(
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => searchQuery = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                            hintText: 'SEARCH RECIPES',
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryGreen, width: 2)),
                          ),
                        ),
                        if (showRecent && searchQuery.isEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 60,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text('Recent Searches', style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                                    ),
                                    ...recentSearches.map((s) => TextButton(
                                          onPressed: () => setState(() {
                                            searchQuery = s; _searchFocus.unfocus();
                                          }),
                                          child: Align(alignment: Alignment.centerLeft, child: Text(s, style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey[800]))),
                                        ))
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),

              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final name = categories[idx];
                      final active = selectedCategory == name;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: active ? Colors.black : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(999),
                            border: active ? null : Border.all(color: Colors.grey.shade100),
                            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0,4))] : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${_getEmojiForCategory(name)} ${name.toUpperCase()}',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: active ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (searchQuery.isEmpty && selectedCategory == 'All') ...[
                              _buildSection('Recommended ✨', recommendedRecipes),
                              _buildSection('Popular This Week 🔥', popularRecipes),
                              _buildSection('Quick Recipes ⚡ Under 15 Min', quickRecipes, highlightTime: true),
                            ],

                            if (searchQuery.isNotEmpty || selectedCategory != 'All')
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                                child: filteredRecipes.isEmpty
                                    ? Column(
                                        children: [
                                          const SizedBox(height: 40),
                                          Icon(Icons.restaurant, size: 64, color: Colors.grey.shade300),
                                          const SizedBox(height: 12),
                                          Text(selectedCategory == 'Saved' ? 'No saved recipes yet' : 'No recipes found', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey)),
                                        ],
                                      )
                                    : Column(
                                        children: filteredRecipes.map((r) => _buildVerticalCard(r)).toList(),
                                      ),
                              )
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

  Widget _buildSection(String title, List<Recipe> list, {bool highlightTime = false}) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240, 
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 20), 
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                final r = list[idx];
                final iconData = _getIconFor(r.name);
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r, initiallySaved: saved.contains(r.id))));
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: iconData['color'].withOpacity(0.25), 
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 110,
                                decoration: BoxDecoration(color: iconData['color'].withOpacity(0.1)),
                                child: Center(
                                  child: Container(
                                    width: 60, height: 60,
                                    decoration: BoxDecoration(color: iconData['color'], borderRadius: BorderRadius.circular(16)),
                                    child: Icon(iconData['icon'], color: Colors.white, size: 32),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name, style: GoogleFonts.lato(fontWeight: FontWeight.w900, fontSize: 15)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(r.time, style: GoogleFonts.lato(fontSize: 12, color: highlightTime ? primaryGreen : Colors.grey, fontWeight: FontWeight.w800))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(RecipeRatingStore.getAverage(r).toStringAsFixed(1), style: GoogleFonts.lato(fontWeight: FontWeight.w900, fontSize: 13)),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          Positioned(
                            top: 12, right: 12,
                            child: GestureDetector(
                              onTap: () => toggleSave(r.id),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: saved.contains(r.id) ? primaryGreen : Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
                                    child: Icon(saved.contains(r.id) ? Icons.favorite : Icons.favorite_border, size: 18, color: saved.contains(r.id) ? Colors.white : Colors.grey[700]),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCard(Recipe r) {
    final iconData = _getIconFor(r.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r, initiallySaved: saved.contains(r.id))));
          if (mounted) setState(() {});
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: iconData['color'].withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                Container(
                  width: 110, height: 110,
                  color: iconData['color'].withOpacity(0.1),
                  child: Center(
                    child: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(color: iconData['color'], borderRadius: BorderRadius.circular(14)),
                      child: Icon(iconData['icon'], color: Colors.white, size: 28),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(r.time, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w800)),
                            const SizedBox(width: 12),
                            const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(r.calories, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: r.difficulty == 'Easy' ? primaryGreen.withOpacity(0.1) : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text(r.difficulty, style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w900, color: r.difficulty == 'Easy' ? primaryGreen : Colors.orange.shade700)),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(RecipeRatingStore.getAverage(r).toStringAsFixed(1), style: GoogleFonts.lato(fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}