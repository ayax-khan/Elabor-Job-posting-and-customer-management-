import 'package:elabor/screens/auth/customer/customer_signup_screen.dart';
import 'package:elabor/screens/auth/labor/labor_basic_info_screen.dart';
import 'package:elabor/screens/customer/customer_main_screen.dart';
import 'package:elabor/screens/labor/labor_navigation_screen.dart';
import 'package:elabor/service/auth_service.dart';
import 'package:elabor/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  final bool isLabor;
  const LoginScreen({super.key, required this.isLabor});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_role',
          widget.isLabor ? 'labor' : 'customer',
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    widget.isLabor
                        ? const LaborNavigationScreen()
                        : const CustomerMainScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_role',
          widget.isLabor ? 'labor' : 'customer',
        );
        final isRegistered = await _authService.isUserRegistered(
          user.uid,
          widget.isLabor,
        );
        if (!mounted) return;
        if (!isRegistered) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      widget.isLabor
                          ? const LaborBasicInfoScreen()
                          : const CustomerSignupScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      widget.isLabor
                          ? const LaborNavigationScreen()
                          : const CustomerMainScreen(),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isLabor ? 'Labor Sign-In' : 'Customer Sign-In',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.blue.shade800,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign In to Continue',
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.03),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter your email' : null,
              ),
              SizedBox(height: size.height * 0.02),
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter your password' : null,
              ),
              SizedBox(height: size.height * 0.03),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedButton(
                    text: 'Sign In',
                    color: Colors.blueAccent,
                    onPressed: _signInWithEmail,
                  ),
              SizedBox(height: size.height * 0.02),
              AnimatedButton(
                text: 'Sign in with Google',
                color: Colors.redAccent,
                onPressed: _signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
