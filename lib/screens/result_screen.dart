import 'package:flutter/material.dart';
// Подключаем магию Firebase:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  static const List<String> safeIngredients = [
    'Whole Wheat Flour',
    'Water',
    'Salt',
    'Sourdough Starter',
    'Olive Oil',
  ];

  static const List<String> allergens = [
    'SOY',
    'PEANUTS',
  ];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final source = args is Map<String, dynamic> ? (args['source']?.toString() ?? '') : '';
    final bool showActionButtons = source != 'saved';
    final bool fromScan = source == 'scan';

    Future<void> goHome() async {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }

    // --- НОВАЯ ФУНКЦИЯ ДЛЯ СОХРАНЕНИЯ В FIREBASE ---
    Future<void> saveToFirestore() async {
      try {
        // 1. Узнаем, кто сейчас сидит в приложении
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка: Пользователь не авторизован')),
          );
          return;
        }

        // 2. Отправляем данные продукта в Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid) // Личная папка пользователя
            .collection('saved_scans') // Подпапка с его сканами
            .add({
          'productName': 'Artisan Whole Grain',
          'ingredients': safeIngredients,
          'allergens': allergens,
          'weight': '500g',
          'calories': '120 kcal',
          'status': 'SAFE TO CONSUME',
          'timestamp': FieldValue.serverTimestamp(), // Время сохранения
        });

        // 3. Радуем пользователя и возвращаем домой
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Успешно сохранено в облако! ☁️'), 
              backgroundColor: Colors.green
            ),
          );
          goHome();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
    // -----------------------------------------------

    return PopScope(
      canPop: !fromScan,
      onPopInvoked: (didPop) async {
        if (!didPop && fromScan) {
          await goHome();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (fromScan) {
                        goHome();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Artisan Whole Grain',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Safety Analysis Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'SAFE TO CONSUME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Ingredients Section
              const Text(
                'Ingredients',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: safeIngredients.map((ing) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(ing),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Allergens
              const Text(
                'Allergens',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergens.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF6C00), size: 18),
                        const SizedBox(width: 8),
                        Text(a, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF6C00))),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.monitor_weight, color: Colors.black54),
                          SizedBox(height: 8),
                          Text('Weight', style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('500g', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.local_fire_department, color: Colors.black54),
                          SizedBox(height: 8),
                          Text('Calories', style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('120 kcal', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Action Buttons
              if (showActionButtons)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      // ПРИВЯЗАЛИ ФУНКЦИЮ СЮДА:
                      onPressed: saveToFirestore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Analysis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ));
  }
}