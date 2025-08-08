import 'package:elabor/screens/labor/labor_navigation_screen.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'screens/customer/customer_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');

    if (role == 'labor') {
      final firestoreService = FirestoreService();
      final roles = await firestoreService.getUserRoles(user.uid);
      if (roles.contains('labor')) {
        return const LaborNavigationScreen();
      }
    } else if (role == 'customer') {
      final firestoreService = FirestoreService();
      final roles = await firestoreService.getUserRoles(user.uid);
      if (roles.contains('customer')) {
        return const CustomerMainScreen();
      }
    }

    // Fallback for users who logged in but role is not set (e.g., incomplete registration)
    final firestoreService = FirestoreService();
    final customer = await firestoreService.getCustomerData();
    if (customer != null) {
      await prefs.setString('user_role', 'customer');
      return const CustomerMainScreen();
    }
    final labor = await firestoreService.getLaborData();
    if (labor != null) {
      await prefs.setString('user_role', 'labor');
      return const LaborNavigationScreen();
    }

    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eLabor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Poppins',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data ?? const WelcomeScreen();
        },
      ),
    );
  }
}
