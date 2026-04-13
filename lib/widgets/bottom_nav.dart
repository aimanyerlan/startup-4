import 'package:flutter/material.dart';
// Подтягиваем экраны из папки screens
import '../screens/home_screen.dart';
import '../screens/camera_scan_screen.dart';
import '../screens/saved_products_screen.dart';
import '../screens/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  // Список из 4 главных экранов
  final List<Widget> _screens = [
    const HomeScreen(),
    const CameraScanScreen(),
    const SavedProductsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Показываем экран в зависимости от того, какая иконка нажата
      body: _screens[_currentIndex],
      
      // Сама нижняя панель
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2ECC71),
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'SCAN'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline_rounded), activeIcon: Icon(Icons.bookmark_rounded), label: 'SAVED'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }
}