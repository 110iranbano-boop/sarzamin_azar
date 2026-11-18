import 'package:flutter/material.dart';
import 'home_map_page.dart';
import 'missions_page.dart';
import 'library_page.dart';
import 'forum_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeMapPage(),
    const MissionsPage(),
    const LibraryPage(),
    const ForumPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: const Color(0xFF6B4EE6),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'نقشه'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'مأموریت‌ها'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'کتابخانه'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'تالار گفتگو'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'شخصیت من'),
        ],
      ),
    );
  }
}