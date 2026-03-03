import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/camera_scan_screen.dart';
import 'package:my_app/screens/saved_products_screen.dart';
import 'package:my_app/screens/profile_screen.dart';

/// Reusable bottom navigation bar with page management.
class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CameraScanScreen(),
    const SavedProductsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.0,
              color: isSelected ? const Color(0xFF2ECC71) : Colors.grey.shade600,
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  height: 1.2,
                  color: isSelected ? const Color(0xFF2ECC71) : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _selectedIndex == 1
          ? null
          : SafeArea(
              top: false,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => _buildNavItem(
                            index: index,
                            icon: [
                              Icons.home,
                              Icons.qr_code_scanner,
                              Icons.bookmark,
                              Icons.person,
                            ][index],
                            label: ['HOME', 'SCAN', 'SAVED', 'PROFILE'][index],
                            isSelected: _selectedIndex == index,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

