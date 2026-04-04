import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../shared/custom_search_bar.dart';
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
  late Set<String> selectedFilters; // Track multiple selected filters
  final searchController = TextEditingController();

  final List<Map<String, dynamic>> filters = [
    {'label': 'Hospitals', 'icon': Icons.local_hospital},
    {'label': 'Police Stations', 'icon': Icons.local_police},
    {'label': 'Fire Stations', 'icon': Icons.fire_truck},
  ];

  @override
  void initState() {
    super.initState();
    // All filters selected by default
    selectedFilters = {'Hospitals', 'Police Stations', 'Fire Stations'};
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 8),
          // Filter chips - horizontal scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filterItem) {
                final label = filterItem['label'] as String;
                final icon = filterItem['icon'] as IconData;
                final isSelected = selectedFilters.contains(label);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.getPrimaryTextColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.getPrimaryTextColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedFilters.add(label);
                        } else {
                          selectedFilters.remove(label);
                        }
                      });
                      // Notify parent about the selected filter
                      widget.onFilterChanged?.call(label);
                    },
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppTheme.getCardBackgroundColor(),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.secondary
                          : AppTheme.getBorderColor(),
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
