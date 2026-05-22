import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../shared/custom_search_bar.dart';
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
                          child: _GlassFilterChip(
                            label: label,
                            icon: icon,
                            color: color,
                            isSelected: isSelected,
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

class _GlassFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GlassFilterChip> createState() => _GlassFilterChipState();
}

class _GlassFilterChipState extends State<_GlassFilterChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    final color = widget.color;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.91 : 1.0,
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 300),
        curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Stack(
              children: [
                // Glass base
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? isDark
                                ? [
                                    color.withOpacity(0.22),
                                    color.withOpacity(0.10),
                                  ]
                                : [
                                    color.withOpacity(0.18),
                                    color.withOpacity(0.08),
                                  ]
                          : isDark
                          ? [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.04),
                            ]
                          : [
                              Colors.white.withOpacity(0.55),
                              Colors.white.withOpacity(0.28),
                            ],
                    ),
                    border: Border.all(
                      color: isSelected
                          ? isDark
                                ? color.withOpacity(0.35)
                                : color.withOpacity(0.28)
                          : isDark
                          ? Colors.white.withOpacity(0.14)
                          : Colors.white.withOpacity(0.42),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: color.withOpacity(isSelected ? 0.22 : 0.0),
                        blurRadius: isSelected ? 12 : 0,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: color, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : AppTheme.getSecondaryTextColor(),
                          fontSize: 11.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Specular highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(isDark ? 0.32 : 0.72),
                            Colors.white.withOpacity(isDark ? 0.14 : 0.45),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Inner sheen
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.06 : 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.50],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
