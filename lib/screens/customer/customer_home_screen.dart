import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/labor.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/city_area_dropdown.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String? _selectedCity;
  String? _selectedArea;
  List<Labor> _labors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLabors();
  }

  Future<void> _fetchLabors() async {
    setState(() => _isLoading = true);
    final labors = await _firestoreService.getLaborsByArea(
      _selectedCity,
      _selectedArea,
      _searchController.text,
    );
    setState(() {
      _labors = labors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.03,
          ),
          child: Column(
            children: [
              Text(
                'Find Skilled Labor',
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              CustomTextField(
                controller: _searchController,
                label: 'Search Labor by Name',
                onChanged: (value) => _fetchLabors(),
              ),
              SizedBox(height: size.height * 0.02),
              CityAreaDropdown(
                onCityChanged: (city) {
                  _selectedCity = city;
                  _fetchLabors();
                },
                onAreaChanged: (area) {
                  _selectedArea = area;
                  _fetchLabors();
                },
              ),
              SizedBox(height: size.height * 0.02),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                    child: ListView.builder(
                      itemCount: _labors.length,
                      itemBuilder: (context, index) {
                        final labor = _labors[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            vertical: size.height * 0.01,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  labor.profilePhotoUrl != null
                                      ? NetworkImage(labor.profilePhotoUrl!)
                                      : null,
                            ),
                            title: Text(
                              labor.fullName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              labor.skills.join(', '),
                              style: GoogleFonts.poppins(),
                            ),
                            onTap: () {
                              // Navigate to labor profile or chat
                            },
                          ),
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
