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

  const FilterOptionsSheet({Key? key, this.initialRadius = 5.0})
    : super(key: key);

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

                    // Filter options list
                    Column(
                      children: List.generate(
                        IncidentTypesConfig.allTypes.length,
                        (index) {
                          final incident = IncidentTypesConfig.allTypes[index];
                          final isSelected = selectedIncidentTypes.contains(
                            incident.key,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedIncidentTypes.remove(incident.key);
                                  } else {
                                    selectedIncidentTypes.add(incident.key);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.getCardBackgroundColor(),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? incident.color
                                        : AppTheme.getBorderColor(),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: incident.color.withOpacity(0.15),
                                      ),
                                      child: Icon(
                                        incident.icon,
                                        color: incident.color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomText(
                                        text: incident.displayName,
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: AppTheme.getPrimaryTextColor(),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: incident.color,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
