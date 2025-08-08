import 'package:elabor/screens/labor/screen/labor_chat_screen.dart';
import 'package:elabor/screens/labor/screen/labor_home_screen.dart';
import 'package:elabor/screens/labor/screen/labor_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LaborNavigationScreen extends StatefulWidget {
  const LaborNavigationScreen({super.key});

  @override
  State<LaborNavigationScreen> createState() => _LaborNavigationScreenState();
}

class _LaborNavigationScreenState extends State<LaborNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LaborHomeScreen(),
    const LaborChatScreen(),
    const LaborProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: 'Assets/images/chat.png',
              label: 'Chat',
              index: 1,
            ),
            _buildNavItem(
              icon: 'Assets/images/home.png',
              label: 'Home',
              index: 0,
            ),
            _buildNavItem(
              icon: 'Assets/images/profile.png',
              label: 'Profile',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageIcon(
              AssetImage(icon),
              color: isSelected ? Colors.blueAccent : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
