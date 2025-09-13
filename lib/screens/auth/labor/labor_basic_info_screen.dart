import 'package:elabor/service/firestore_service.dart';
import 'package:elabor/widgets/animated_button.dart';
import 'package:elabor/widgets/city_area_dropdown.dart';
import 'package:elabor/widgets/custom_text_field.dart';
import 'package:elabor/widgets/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../labor/labor_professional_details_screen.dart';
import '../login_screen.dart'; // Make sure this import is present

class LaborBasicInfoScreen extends StatefulWidget {
  const LaborBasicInfoScreen({super.key});

  @override
  State<LaborBasicInfoScreen> createState() => _LaborBasicInfoScreenState();
}

class _LaborBasicInfoScreenState extends State<LaborBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  String _gender = 'Male';
  String? _city;
  String? _area;
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue')),
        );
        Navigator.pop(context); // Return to LoginScreen
      }
      return;
    }

    final roles = await _firestoreService.getUserRoles(user.uid);
    if (roles.contains('labor')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already registered as a labor'),
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    }
  }

  Future<void> _cancelRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(isLabor: false),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null || _area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select city and area')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Navigate to LaborProfessionalDetailsScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LaborProfessionalDetailsScreen(
                  basicInfo: {
                    'fullName': _fullNameController.text,
                    'cnic': _cnicController.text,
                    'gender': _gender,
                    'contactNumber': _contactController.text,
                    'address': _addressController.text,
                    'city': _city!,
                    'area': _area!,
                    'password': _passwordController.text,
                    'email': _emailController.text,
                  },
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        await _cancelRegistration();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Basic Information', style: GoogleFonts.poppins()),
          backgroundColor: Colors.blue.shade800,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelRegistration,
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                          'Enter Your Basic Details',
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        CustomTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please enter your name'
                                      : null,
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
                            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustomTextField(
                          controller: _cnicController,
                          label: 'CNIC Number (e.g., 61101-1234567-1)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [CnicInputFormatter()],
                          validator: (value) {
                            if (value == null ||
                                !RegExp(cnicPattern).hasMatch(value)) {
                              return 'Enter valid CNIC (e.g., 61101-1234567-1)';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustomTextField(
                          controller: _contactController,
                          label: 'Contact Number (e.g., 0321-1234567)',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneInputFormatter()],
                          validator: (value) {
                            if (value == null ||
                                !RegExp(phonePattern).hasMatch(value)) {
                              return 'Enter valid phone number (e.g., 0321-1234567)';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items:
                              ['Male', 'Female', 'Other']
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _gender = value!),
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustomTextField(
                          controller: _addressController,
                          label: 'Address',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please enter your address'
                                      : null,
                        ),
                        SizedBox(height: size.height * 0.02),
                        CityAreaDropdown(
                          onCityChanged: (city) => setState(() => _city = city),
                          onAreaChanged: (area) => setState(() => _area = area),
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
                        SizedBox(height: size.height * 0.04),
                        AnimatedButton(
                          text: 'Next',
                          color: Colors.blueAccent,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cnicController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
