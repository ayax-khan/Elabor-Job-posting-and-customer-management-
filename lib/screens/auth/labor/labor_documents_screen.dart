// import 'package:elabor/screens/auth/labor/labor_basic_info_screen.dart';
import 'package:elabor/screens/labor/labor_navigation_screen.dart';
import 'package:elabor/service/cloudinary_service.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:elabor/widgets/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class LaborDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> basicInfo;
  final Map<String, dynamic> professionalInfo;
  const LaborDocumentsScreen({
    super.key,
    required this.basicInfo,
    required this.professionalInfo,
  });

  @override
  State<LaborDocumentsScreen> createState() => _LaborDocumentsScreenState();
}

class _LaborDocumentsScreenState extends State<LaborDocumentsScreen> {
  File? _profilePhoto;
  File? _cnicFront;
  File? _cnicBack;
  File? _skillProof;
  bool _isLoading = false;
  final _firestoreService = FirestoreService();

  Future<void> _pickImage(String field) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (field == 'profile') {
          _profilePhoto = File(pickedFile.path);
        } else if (field == 'cnicFront') {
          _cnicFront = File(pickedFile.path);
        } else if (field == 'cnicBack') {
          _cnicBack = File(pickedFile.path);
        } else if (field == 'skillProof') {
          _skillProof = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _cancelRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LaborNavigationScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final roles = await _firestoreService.getUserRoles(user.uid);
      if (roles.contains('labor')) {
        throw Exception('You are already registered as a labor');
      }

      String? profileUrl =
          _profilePhoto != null
              ? await CloudinaryService.uploadImage(_profilePhoto!)
              : null;
      String? cnicFrontUrl =
          _cnicFront != null
              ? await CloudinaryService.uploadImage(_cnicFront!)
              : null;
      String? cnicBackUrl =
          _cnicBack != null
              ? await CloudinaryService.uploadImage(_cnicBack!)
              : null;
      String? skillProofUrl =
          _skillProof != null
              ? await CloudinaryService.uploadImage(_skillProof!)
              : null;

      // Ensure skills and languages are List<String>
      final skills =
          (widget.professionalInfo['skills'] as List<dynamic>)
              .map((s) => s.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
      final languages =
          (widget.professionalInfo['languages'] as List<dynamic>)
              .map((s) => s.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();

      if (skills.isEmpty || languages.isEmpty) {
        throw Exception('Skills and languages cannot be empty');
      }

      await _firestoreService.saveLaborData(
        user.uid,
        widget.basicInfo['fullName'],
        widget.basicInfo['cnic'],
        widget.basicInfo['gender'],
        widget.basicInfo['contactNumber'],
        widget.basicInfo['address'],
        widget.basicInfo['city']!,
        widget.basicInfo['area']!,
        skills,
        int.parse(widget.professionalInfo['experience']),
        languages,
        widget.professionalInfo['availability'],
        double.parse(widget.professionalInfo['wage']),
        profileUrl,
        cnicFrontUrl,
        cnicBackUrl,
        skillProofUrl,
      );

      // Set user_role only after successful registration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'labor');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LaborNavigationScreen()),
      );
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
          title: Text('Documents & Media', style: GoogleFonts.poppins()),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Your Documents',
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      AnimatedButton(
                        text: 'Upload Profile Photo',
                        color: Colors.blue.shade600,
                        onPressed: () => _pickImage('profile'),
                      ),
                      if (_profilePhoto != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.01,
                          ),
                          child: Text(
                            'Profile Photo Selected',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                            ),
                          ),
                        ),
                      SizedBox(height: size.height * 0.02),
                      AnimatedButton(
                        text: 'Upload CNIC Front',
                        color: Colors.blue.shade600,
                        onPressed: () => _pickImage('cnicFront'),
                      ),
                      if (_cnicFront != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.01,
                          ),
                          child: Text(
                            'CNIC Front Selected',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                            ),
                          ),
                        ),
                      SizedBox(height: size.height * 0.02),
                      AnimatedButton(
                        text: 'Upload CNIC Back',
                        color: Colors.blue.shade600,
                        onPressed: () => _pickImage('cnicBack'),
                      ),
                      if (_cnicBack != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.01,
                          ),
                          child: Text(
                            'CNIC Back Selected',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                            ),
                          ),
                        ),
                      SizedBox(height: size.height * 0.02),
                      AnimatedButton(
                        text: 'Upload Skill Proof (Optional)',
                        color: Colors.blue.shade600,
                        onPressed: () => _pickImage('skillProof'),
                      ),
                      if (_skillProof != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.01,
                          ),
                          child: Text(
                            'Skill Proof Selected',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                            ),
                          ),
                        ),
                      SizedBox(height: size.height * 0.04),
                      AnimatedButton(
                        text: 'Submit',
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
