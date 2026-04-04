import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../utils/incident_types_config.dart';
import '../shared/custom_text.dart';

class FilterSettings {
  final double radiusKm;
  final Set<String> selectedIncidentTypes;

  FilterSettings({required this.radiusKm, required this.selectedIncidentTypes});
}

class FilterOptionsSheet extends StatefulWidget {
  final double initialRadius;
  final Set<String> initialSelectedTypes;

  const FilterOptionsSheet({
    Key? key,
    this.initialRadius = 5.0,
    this.initialSelectedTypes = const {},
  }) : super(key: key);

  @override
  State<FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<FilterOptionsSheet> {
  Set<String> selectedIncidentTypes = {};

  // POI Settings
  late double radiusKm;

  @override
  void initState() {
    super.initState();
    radiusKm = widget.initialRadius;
    // Use exactly what's passed in - map_screen always initializes with all types
    // so first open will have all, and subsequent opens will have the user's selection
    selectedIncidentTypes = {...widget.initialSelectedTypes};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Filters & Settings',
                      size: 16,
                      weight: FontWeight.w800,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppTheme.getSecondaryTextColor(),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0.5),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // POI Settings Section
                    CustomText(
                      text: '📍 POI Settings',
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    const SizedBox(height: 12),

                    // Radius Slider
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardBackgroundColor(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getBorderColor()),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: 'Search Radius',
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CustomText(
                                  text: '${radiusKm.toStringAsFixed(1)} km',
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: radiusKm,
                            min: 1.0,
                            max: 25.0,
                            divisions: 24,
                            label: '${radiusKm.toStringAsFixed(1)} km',
                            activeColor: AppColors.secondary,
                            onChanged: (value) {
                              setState(() => radiusKm = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Incident Types Section
                    CustomText(
                      text: '🚨 Incident Types',
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    const SizedBox(height: 12),

                    // Filter options list - using FilterChip like map_filter_section
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        IncidentTypesConfig.allTypes.length,
                        (index) {
                          final incident = IncidentTypesConfig.allTypes[index];
                          final isSelected = selectedIncidentTypes.contains(
                            incident.key,
                          );
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  incident.icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : incident.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  incident.displayName,
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
                                  selectedIncidentTypes.add(incident.key);
                                } else {
                                  selectedIncidentTypes.remove(incident.key);
                                }
                              });
                            },
                            selectedColor: incident.color,
                            backgroundColor: AppTheme.getCardBackgroundColor(),
                            side: BorderSide(
                              color: isSelected
                                  ? incident.color
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
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: GestureDetector(
              onTap: () {
                // Return settings and close
                Navigator.pop(
                  context,
                  FilterSettings(
                    radiusKm: radiusKm,
                    selectedIncidentTypes: selectedIncidentTypes,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CustomText(
                    text: 'Apply',
                    size: 14,
                    weight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
