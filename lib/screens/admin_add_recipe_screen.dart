import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAddRecipeScreen extends StatefulWidget {
  const AdminAddRecipeScreen({super.key});

  @override
  State<AdminAddRecipeScreen> createState() => _AdminAddRecipeScreenState();
}

class _AdminAddRecipeScreenState extends State<AdminAddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _difficulty = 'Easy';
  String _category = 'Breakfast';
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF2ECC71);

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newId = DateTime.now().millisecondsSinceEpoch;
      
      final ingredients = _ingredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final instructions = _instructionsController.text.split('.').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      await FirebaseFirestore.instance.collection('recipes').doc(newId.toString()).set({
        'id': newId,
        'name': _nameController.text.trim(),
        'time': _timeController.text.trim(),
        'rating': 5.0, 
        'calories': _caloriesController.text.trim(),
        'difficulty': _difficulty,
        'category': _category,
        'servings': 1,
        'ingredients': ingredients,
        'instructions': instructions,
        'colorValue': 0xFF2ECC71, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рецепт успешно добавлен в базу! 🚀'), backgroundColor: Color(0xFF2ECC71)),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Admin Panel 👑', style: GoogleFonts.lato(color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Название рецепта (напр. Caesar Salad)', _nameController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Время (напр. 15m)', _timeController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Калории (напр. 300 kcal)', _caloriesController)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: _inputDecoration('Категория'),
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Drinks'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _difficulty,
                        decoration: _inputDecoration('Сложность'),
                        items: ['Easy', 'Medium', 'Hard'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _difficulty = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Ингредиенты (через запятую)', _ingredientsController, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField('Шаги приготовления (через точку)', _instructionsController, maxLines: 4),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Добавить в базу', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (v) => v!.isEmpty ? 'Заполните поле' : null,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen, width: 2)),
    );
  }
}