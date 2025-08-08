import 'package:elabor/service/firestore_service.dart';
import 'package:elabor/widgets/animated_button.dart';
import 'package:elabor/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../labor/labor_documents_screen.dart';

class LaborProfessionalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> basicInfo;
  const LaborProfessionalDetailsScreen({super.key, required this.basicInfo});

  @override
  State<LaborProfessionalDetailsScreen> createState() =>
      _LaborProfessionalDetailsScreenState();
}

class _LaborProfessionalDetailsScreenState
    extends State<LaborProfessionalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _languagesController = TextEditingController();
  String _availability = 'Full-time';
  final _wageController = TextEditingController();
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
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => LaborDocumentsScreen(
                basicInfo: widget.basicInfo,
                professionalInfo: {
                  'skills':
                      _skillsController.text
                          .split(',')
                          .map((s) => s.trim())
                          .toList(),
                  'experience': _experienceController.text,
                  'languages':
                      _languagesController.text
                          .split(',')
                          .map((s) => s.trim())
                          .toList(),
                  'availability': _availability,
                  'wage': _wageController.text,
                },
              ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Convert skills and languages to List<String>
      final skills =
          _skillsController.text.split(',').map((s) => s.trim()).toList();
      final languages =
          _languagesController.text.split(',').map((s) => s.trim()).toList();

      // Navigate to LaborDocumentsScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LaborDocumentsScreen(
                  basicInfo: widget.basicInfo,
                  professionalInfo: {
                    'skills': skills,
                    'experience': _experienceController.text,
                    'languages': languages,
                    'availability': _availability,
                    'wage': _wageController.text,
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
          title: Text('Professional Details', style: GoogleFonts.poppins()),
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
                          'Enter Your Professional Details',
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        CustomTextField(
                          controller: _skillsController,
                          label:
                              'Skills (comma-separated, e.g., Electrician, Plumber)',
                          validator: (value) {
                            if (value!.isEmpty)
                              return 'Please enter your skills';
                            final skills =
                                value.split(',').map((s) => s.trim()).toList();
                            if (skills.any((s) => s.isEmpty)) {
                              return 'Skills cannot be empty';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustomTextField(
                          controller: _experienceController,
                          label: 'Years of Experience',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty)
                              return 'Please enter your experience';
                            if (int.tryParse(value) == null ||
                                int.parse(value) < 0) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustomTextField(
                          controller: _languagesController,
                          label:
                              'Languages (comma-separated, e.g., Urdu, Punjabi)',
                          validator: (value) {
                            if (value!.isEmpty)
                              return 'Please enter your languages';
                            final languages =
                                value.split(',').map((s) => s.trim()).toList();
                            if (languages.any((s) => s.isEmpty)) {
                              return 'Languages cannot be empty';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        DropdownButtonFormField<String>(
                          value: _availability,
                          items:
                              ['Full-time', 'Part-time', 'On-call']
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(a),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _availability = value!),
                          decoration: InputDecoration(
                            labelText: 'Availability',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustomTextField(
                          controller: _wageController,
                          label: 'Expected Wage (PKR/day)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter your wage';
                            if (double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Enter a valid wage';
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
    _skillsController.dispose();
    _experienceController.dispose();
    _languagesController.dispose();
    _wageController.dispose();
    super.dispose();
  }
}
