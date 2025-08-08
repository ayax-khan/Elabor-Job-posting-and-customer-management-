import 'package:elabor/service/cloudinary_service.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../widgets/custom_text_field.dart';
import '../../widgets/city_area_dropdown.dart';
import '../../widgets/animated_button.dart';

class JobPostDialog extends StatefulWidget {
  final VoidCallback onJobPosted;

  const JobPostDialog({super.key, required this.onJobPosted});

  @override
  State<JobPostDialog> createState() => _JobPostDialogState();
}

class _JobPostDialogState extends State<JobPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedCity;
  String? _selectedArea;
  File? _jobImage;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _jobImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select city and area')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl =
          _jobImage != null
              ? await CloudinaryService.uploadImage(_jobImage!)
              : null;

      await _firestoreService.postJob(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _addressController.text.trim(),
        _selectedCity!,
        _selectedArea!,
        imageUrl,
      );

      widget.onJobPosted();
      if (!mounted) return;
      Navigator.pop(context);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(size.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post a New Job',
                  style: GoogleFonts.poppins(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                // Image Selection Field
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: size.height * 0.15,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child:
                        _jobImage == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: size.width * 0.08,
                                  color: Colors.blueAccent,
                                ),
                                Text(
                                  'Select Job Image',
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width * 0.04,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_jobImage!, fit: BoxFit.cover),
                            ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                CustomTextField(
                  controller: _titleController,
                  label: 'Job Title',
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter job title' : null,
                ),
                SizedBox(height: size.height * 0.02),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 4,
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Please enter job description'
                              : null,
                ),
                SizedBox(height: size.height * 0.02),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  validator:
                      (value) => value!.isEmpty ? 'Please enter address' : null,
                ),
                SizedBox(height: size.height * 0.02),
                CityAreaDropdown(
                  onCityChanged: (city) => setState(() => _selectedCity = city),
                  onAreaChanged: (area) => setState(() => _selectedArea = area),
                ),
                SizedBox(height: size.height * 0.03),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AnimatedButton(
                      text: 'Post Job',
                      color: Colors.blueAccent,
                      onPressed: _postJob,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
