import 'package:elabor/screens/customer/customer_main_screen.dart';
import 'package:elabor/service/auth_service.dart';
import 'package:elabor/service/cloudinary_service.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:elabor/widgets/animated_button.dart';
import 'package:elabor/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _profilePhoto;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profilePhoto = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerUser(
        _emailController.text.trim(),
        _passwordController.text,
        'customer',
      );

      if (user != null) {
        String? profileUrl =
            _profilePhoto != null
                ? await CloudinaryService.uploadImage(_profilePhoto!)
                : null;

        await _firestoreService.saveCustomerData(
          user.uid,
          _nameController.text.trim(),
          _phoneController.text.trim(),
          profileUrl,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', 'customer');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Signup', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.03,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Your Customer Profile',
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.03),
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                validator:
                    (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              SizedBox(height: size.height * 0.02),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: size.height * 0.02),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value!.isEmpty
                            ? 'Please enter your phone number'
                            : null,
              ),
              SizedBox(height: size.height * 0.02),
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: size.height * 0.02),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: size.height * 0.02),
              AnimatedButton(
                text: 'Upload Profile Photo',
                color: Colors.blue.shade600,
                onPressed: _pickImage,
              ),
              if (_profilePhoto != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
                  child: Text(
                    'Profile Photo Selected',
                    style: GoogleFonts.poppins(fontSize: size.width * 0.04),
                  ),
                ),
              SizedBox(height: size.height * 0.04),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedButton(
                    text: 'Sign Up',
                    color: Colors.blueAccent,
                    onPressed: _submit,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
