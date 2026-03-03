import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/widgets/layout.dart';

class Product {
  final int id;
  final String name;
  final String brand;
  final String status;
  final String calories;
  final bool saved;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.status,
    required this.calories,
    required this.saved,
  });
}

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  bool isGuest = false;
  Set<int> savedProductIds = {};
  final Set<int> _pendingRemovalIds = {};
  final Map<int, Timer> _removalTimers = {};

  late List<Product> savedProducts;

  static final List<Product> _initialProducts = [
    Product(id: 1, name: 'Organic Milk', brand: 'Happy Valley', status: 'safe', calories: '150 kcal', saved: true),
    Product(id: 2, name: 'Greek Yogurt', brand: 'Chobani', status: 'safe', calories: '100 kcal', saved: true),
    Product(id: 3, name: 'Almond Butter', brand: 'Natural', status: 'safe', calories: '190 kcal', saved: true),
    Product(id: 4, name: 'Whole Grain Bread', brand: "Dave's Organic", status: 'warning', calories: '120 kcal', saved: true),
    Product(id: 5, name: 'Organic Apples', brand: 'Local Farm', status: 'safe', calories: '52 kcal', saved: true),
  ];

  static Set<int> _persistedSavedIds = {for (var p in _initialProducts) p.id};

  @override
  void initState() {
    super.initState();
    savedProducts = List<Product>.from(_initialProducts);
    savedProductIds = Set<int>.from(_persistedSavedIds);
  }

  @override
  void dispose() {
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _removalTimers.clear();
    super.dispose();
  }

  void _toggleSaved(Product product) {
    final id = product.id;

    setState(() {
      final isSaved = savedProductIds.contains(id);

      if (isSaved) {
        savedProductIds.remove(id);
        _pendingRemovalIds.add(id);

        _removalTimers[id]?.cancel();
        _removalTimers[id] = Timer(const Duration(seconds: 5), () {
          if (!mounted) return;
          setState(() {
            _pendingRemovalIds.remove(id);
            _persistedSavedIds.remove(id);
            _removalTimers.remove(id);
          });
        });
      } else {
        savedProductIds.add(id);
        _persistedSavedIds.add(id);
        _pendingRemovalIds.remove(id);
        _removalTimers[id]?.cancel();
        _removalTimers.remove(id);
      }
    });
  }

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

  Widget _buildProductsList(BuildContext context) {
    final displayedProducts = savedProducts
        .where((p) => savedProductIds.contains(p.id) || _pendingRemovalIds.contains(p.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: displayedProducts.asMap().entries.map((entry) {
          final product = entry.value;
          final style = _getProductStyle(product.name);
          final isSaved = savedProductIds.contains(product.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/results',
                arguments: {
                  'source': 'saved',
                  'productName': product.name,
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
                            product.name,
                            style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.brand,
                            style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                product.calories,
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
                                product.status == 'safe' ? 'SAFE' : 'CHECK',
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: product.status == 'safe' ? const Color(0xFF2ECC71) : Colors.orange.shade500,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleSaved(product),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: isSaved ? const Color(0xFF2ECC71) : Colors.grey,
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
  }
}
