import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../custom_search_bar.dart';
import '../custom_filter_chips.dart';
import 'map_filter_button.dart';

class MapFilterSection extends StatefulWidget {
  final ValueChanged<String?>? onFilterChanged;

  const MapFilterSection({Key? key, this.onFilterChanged}) : super(key: key);

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
              MapFilterButton(),
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
