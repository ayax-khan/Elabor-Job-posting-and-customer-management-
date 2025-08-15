import 'package:elabor/screens/labor/labor_chat_screen.dart';
import 'package:elabor/screens/labor/labor_home_screen.dart';
import 'package:elabor/screens/labor/labor_profile_screen.dart';
import 'package:elabor/screens/labor/labor_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/firestore_service.dart';

class LaborNavigationScreen extends StatefulWidget {
  const LaborNavigationScreen({super.key});

  @override
  State<LaborNavigationScreen> createState() => _LaborNavigationScreenState();
}

class _LaborNavigationScreenState extends State<LaborNavigationScreen> {
  int _currentIndex = 1; // Start with Home screen
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _screens = [
    const LaborChatScreen(),
    const LaborHomeScreen(),
    const LaborNotificationScreen(),
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
              label: 'Chats',
              index: 0,
            ),
            _buildNavItem(
              icon: 'Assets/images/home.png',
              label: 'Home',
              index: 1,
            ),
            _buildNotificationNavItem(),
            _buildNavItem(
              icon: 'Assets/images/profile.png',
              label: 'Profile',
              index: 3,
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

  Widget _buildNotificationNavItem() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = 2);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  Icons.notifications,
                  color: isSelected ? Colors.blueAccent : Colors.grey,
                  size: 28,
                ),
                if (_currentUserId != null)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.getNotificationsStream(_currentUserId!),
                    builder: (context, snapshot) {
                      final notifications = snapshot.data ?? [];
                      final unreadCount = notifications.where((n) => !(n['isRead'] ?? false)).length;
                      
                      if (unreadCount > 0) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Notifications',
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
