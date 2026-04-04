import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_search_bar.dart';
import '../shared/custom_filter_chips.dart';
import 'map_filter_button.dart';
import 'filter_options_sheet.dart';

class MapFilterSection extends StatefulWidget {
  final ValueChanged<String?>? onFilterChanged;
  final Function(FilterSettings settings)? onSettingsChanged;
  final double currentRadius;

  const MapFilterSection({
    Key? key,
    this.onFilterChanged,
    this.onSettingsChanged,
    this.currentRadius = 5.0,
  }) : super(key: key);

  @override
  State<MapFilterSection> createState() => _MapFilterSectionState();
}

class _MapFilterSectionState extends State<MapFilterSection> {
  String? selectedFilter;
  final searchController = TextEditingController();

  final List<Map<String, dynamic>> filters = [
    {'label': 'Hospitals', 'icon': Icons.local_hospital},
    {'label': 'Police Stations', 'icon': Icons.local_police},
    {'label': 'Fire Stations', 'icon': Icons.fire_truck},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Search bar and filter button
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Search location...',
                  controller: searchController,
                ),
              ),
              const SizedBox(width: 12),
              MapFilterButton(
                currentRadius: widget.currentRadius,
                onSettingsChanged: widget.onSettingsChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          CustomFilterChips(
            filters: filters,
            selectedFilter: selectedFilter,
            onFilterChanged: (selected) {
              setState(() {
                selectedFilter = selected;
                widget.onFilterChanged?.call(selectedFilter);
              });
            },
            showIcon: true,
            selectedColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
