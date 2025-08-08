import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CityAreaDropdown extends StatefulWidget {
  final Function(String) onCityChanged;
  final Function(String) onAreaChanged;

  const CityAreaDropdown({
    super.key,
    required this.onCityChanged,
    required this.onAreaChanged,
  });

  @override
  State<CityAreaDropdown> createState() => _CityAreaDropdownState();
}

class _CityAreaDropdownState extends State<CityAreaDropdown> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCity;
  String? _selectedArea;
  List<String> _cities = [];
  List<String> _areas = [];

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      final cities = await _firestoreService.getCities();
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching cities: $e')));
    }
  }

  Future<void> _fetchAreas(String city) async {
    try {
      final areas = await _firestoreService.getAreas(city);
      setState(() {
        _areas = areas;
        _selectedArea = null; // Reset selected area when city changes
      });
      widget.onAreaChanged(''); // Notify parent of area reset
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching areas: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCity,
          hint: Text('Select City', style: GoogleFonts.poppins()),
          items:
              _cities
                  .map(
                    (city) => DropdownMenuItem(
                      value: city,
                      child: Text(city, style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
              _areas = []; // Clear areas until new ones are fetched
              _selectedArea = null; // Reset selected area
            });
            widget.onCityChanged(value!);
            _fetchAreas(value); // Fetch areas for the selected city
          },
          decoration: InputDecoration(
            labelText: 'City',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.02,
            ),
          ),
          validator: (value) => value == null ? 'Please select a city' : null,
        ),
        SizedBox(height: size.height * 0.02),
        DropdownButtonFormField<String>(
          value: _selectedArea,
          hint: Text('Select Area', style: GoogleFonts.poppins()),
          items:
              _areas
                  .map(
                    (area) => DropdownMenuItem(
                      value: area,
                      child: Text(area, style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedArea = value;
            });
            widget.onAreaChanged(value!);
          },
          decoration: InputDecoration(
            labelText: 'Area',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.02,
            ),
          ),
          validator: (value) => value == null ? 'Please select an area' : null,
        ),
      ],
    );
  }
}
