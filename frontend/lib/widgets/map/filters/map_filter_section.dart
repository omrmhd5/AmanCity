import 'package:flutter/material.dart';
import '../../shared/custom_search_bar.dart';
import '../../shared/custom_filter_chips.dart';
import 'map_filter_button.dart';
import 'filter_options_sheet.dart';

class MapFilterSection extends StatefulWidget {
  final ValueChanged<String?>? onFilterChanged;
  final Function(FilterSettings settings)? onSettingsChanged;
  final ValueChanged<String>? onSearch;
  final double currentRadius;
  final Set<String> selectedIncidentTypes;
  final bool hideFilters;

  const MapFilterSection({
    Key? key,
    this.onFilterChanged,
    this.onSettingsChanged,
    this.onSearch,
    this.currentRadius = 5.0,
    this.selectedIncidentTypes = const {},
    this.hideFilters = false,
  }) : super(key: key);

  @override
  State<MapFilterSection> createState() => _MapFilterSectionState();
}

class _MapFilterSectionState extends State<MapFilterSection> {
  late Set<String> selectedFilters; // Track multiple selected filters
  final searchController = TextEditingController();

  final List<Map<String, dynamic>> filters = [
    {
      'label': 'Hospitals',
      'icon': Icons.local_hospital,
      'color': const Color(0xFFEF4444), // Red
    },
    {
      'label': 'Police Stations',
      'icon': Icons.local_police,
      'color': const Color(0xFF3B82F6), // Blue
    },
    {
      'label': 'Fire Stations',
      'icon': Icons.fire_truck,
      'color': const Color(0xFFF59E0B), // Orange
    },
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
                  onChanged: widget.onSearch,
                ),
              ),
              const SizedBox(width: 12),
              MapFilterButton(
                currentRadius: widget.currentRadius,
                selectedIncidentTypes: widget.selectedIncidentTypes,
                onSettingsChanged: widget.onSettingsChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter chips - animated collapse/expand
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: widget.hideFilters
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((filterItem) {
                        final label = filterItem['label'] as String;
                        final icon = filterItem['icon'] as IconData;
                        final color = filterItem['color'] as Color;
                        final isSelected = selectedFilters.contains(label);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CustomFilterChip(
                            label: label,
                            icon: icon,
                            isSelected: isSelected,
                            selectedColor: color,
                            iconColor: color,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedFilters.remove(label);
                                } else {
                                  selectedFilters.add(label);
                                }
                              });
                              widget.onFilterChanged?.call(label);
                            },
                            fontSize: 11.5,
                            iconSize: 13,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
