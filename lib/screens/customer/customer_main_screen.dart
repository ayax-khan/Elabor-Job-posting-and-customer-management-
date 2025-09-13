import 'package:elabor/screens/customer/profile_screen/screen/customer_profile_screen.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_home_screen.dart';
import 'chat_list_screen.dart';
import 'notification_screen.dart';
import '../../service/firestore_service.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 1; // Default to Home (center)
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  final List<Widget> _screens = [
    const ChatListScreen(),
    const CustomerHomeScreen(),
    const NotificationScreen(),
    const CustomerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  _currentUserId != null
                      ? _firestoreService.getNotificationsStream(
                        _currentUserId!,
                      )
                      : const Stream.empty(),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                final unreadCount =
                    notifications.where((n) => !(n['isRead'] ?? false)).length;

                return Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
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
                      ),
                  ],
                );
              },
            ),
            activeIcon: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  _currentUserId != null
                      ? _firestoreService.getNotificationsStream(
                        _currentUserId!,
                      )
                      : const Stream.empty(),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                final unreadCount =
                    notifications.where((n) => !(n['isRead'] ?? false)).length;

                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
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
                      ),
                  ],
                );
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
