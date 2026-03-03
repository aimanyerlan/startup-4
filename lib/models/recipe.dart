import 'dart:ui';

class Recipe {
  final int id;
  final String name;
  final String time;
  final double rating;
  final String calories;
  final String difficulty;
  final String category;
  final int servings;
  final List<String> ingredients;
  final List<String> instructions;
  final Color color;

  Recipe({
    required this.id,
    required this.name,
    required this.time,
    required this.rating,
    required this.calories,
    required this.difficulty,
    required this.category,
    this.servings = 1,
    this.ingredients = const [],
    this.instructions = const [],
    this.color = const Color(0xFF2ECC71),
  });
}
