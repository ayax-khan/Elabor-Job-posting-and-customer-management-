import 'package:elabor/widgets/city_area_dropdown.dart';
import 'package:elabor/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class SearchFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String?) onCityChanged;
  final Function(String?) onAreaChanged;
  final VoidCallback onFilterPressed;

  const SearchFilterSection({
    super.key,
    required this.searchController,
    required this.onCityChanged,
    required this.onAreaChanged,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CustomTextField(
            controller: searchController,
            label: 'Search Jobs',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CityAreaDropdown(
                  onCityChanged: onCityChanged,
                  onAreaChanged: onAreaChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
