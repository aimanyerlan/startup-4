import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/widgets/layout.dart'; // Проверь, правильный ли у тебя тут путь

// Подключаем магию Firebase:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  
  // Узнаем, кто сейчас в приложении и гость ли он
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool get isGuest => currentUser == null || currentUser!.isAnonymous;

  // Твоя шикарная функция для определения цветов иконок осталась без изменений!
  Map<String, dynamic> _getProductStyle(String name) {
    final lower = name.toLowerCase();
    
    if (lower.contains('milk')) {
      return {
        'bg': const Color(0xFFE0F5F0),
        'iconBg': const Color(0xFF2ECC71).withOpacity(0.15),
        'iconColor': const Color(0xFF2ECC71),
        'icon': Icons.local_drink,
      };
    } else if (lower.contains('bread') || lower.contains('grain')) {
      return {
        'bg': const Color(0xFFEDE9F3),
        'iconBg': const Color(0xFF9333EA).withOpacity(0.15),
        'iconColor': const Color(0xFF9333EA),
        'icon': Icons.bakery_dining,
      };
    } else if (lower.contains('yogurt')) {
      return {
        'bg': const Color(0xFFE8F3FC),
        'iconBg': Colors.blue.shade100,
        'iconColor': Colors.blue.shade500,
        'icon': Icons.local_cafe,
      };
    } else if (lower.contains('butter')) {
      return {
        'bg': const Color(0xFFFFF9E6),
        'iconBg': Colors.amber.shade100,
        'iconColor': Colors.amber.shade600,
        'icon': Icons.cookie,
      };
    } else if (lower.contains('protein') || lower.contains('bar')) {
      return {
        'bg': const Color(0xFFFCE8F5),
        'iconBg': Colors.pink.shade100,
        'iconColor': Colors.pink.shade600,
        'icon': Icons.fitness_center,
      };
    } else if (lower.contains('apple')) {
      return {
        'bg': const Color(0xFFFFF0F0),
        'iconBg': Colors.red.shade50,
        'iconColor': Colors.red.shade400,
        'icon': Icons.food_bank,
      };
    }
    
    return {
      'bg': Colors.white,
      'iconBg': Colors.grey.shade50,
      'iconColor': Colors.grey.shade400,
      'icon': Icons.bookmark,
    };
  }

  // Новая функция: Удаление продукта из Firebase
  Future<void> _deleteProduct(String docId) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('saved_scans')
          .doc(docId)
          .delete();
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продукт удален'), duration: Duration(seconds: 2)),
        );
      }
    }
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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bookmark, color: Color(0xFF2ECC71), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SAVED',
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isGuest
                    ? _buildGuestState(context)
                    : _buildProductsList(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.lock_outline, size: 36, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'SAVED LOCKED',
              style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Войдите, чтобы сохранять продукты.',
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/auth'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text(
                  'SIGN IN NOW',
                  style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- ВОТ ТУТ ПРОИСХОДИТ МАГИЯ FIREBASE ---
  Widget _buildProductsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Подключаемся к базе и сортируем продукты от самых новых к старым
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('saved_scans')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        // 1. Пока данные скачиваются из интернета
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }

        // 2. Если что-то пошло не так
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
        }

        // 3. Если база пустая (пользователь еще ничего не сканировал)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Нет сохраненных продуктов',
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        // 4. Ура! Данные есть. Берем их и строим список.
        final docs = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id; // Уникальный ID продукта в базе
              
              // Вытаскиваем значения из Firebase
              final productName = data['productName'] ?? 'Неизвестный продукт';
              final calories = data['calories'] ?? '-- kcal';
              final rawStatus = data['status'] ?? 'CHECK';
              final status = rawStatus == 'SAFE TO CONSUME' ? 'safe' : 'warning';
              
              // Подбираем цвета с помощью твоей функции
              final style = _getProductStyle(productName);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/results',
                    arguments: {
                      'source': 'saved',
                      'productName': productName,
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: style['bg'],
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: style['iconBg'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(style['icon'], size: 28, color: style['iconColor']),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scanned Product', 
                                style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    calories,
                                    style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status == 'safe' ? 'SAFE' : 'CHECK',
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: status == 'safe' ? const Color(0xFF2ECC71) : Colors.orange.shade500,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        GestureDetector(
                          // Кнопка удаления!
                          onTap: () => _deleteProduct(docId),
                          child: const Icon(
                            Icons.bookmark, // Закладка всегда зеленая, так как продукт сохранен
                            color: Color(0xFF2ECC71),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}