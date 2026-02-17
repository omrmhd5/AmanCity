import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../custom_text.dart';

class FilterOptionsSheet extends StatefulWidget {
  const FilterOptionsSheet({Key? key}) : super(key: key);

  @override
  State<FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<FilterOptionsSheet> {
  final List<Map<String, dynamic>> incidentTypes = [
    {
      'title': 'Fire / Smoke',
      'icon': Icons.local_fire_department,
      'color': Colors.red,
    },
    {
      'title': 'Road Accident',
      'icon': Icons.directions_car,
      'color': Colors.orange,
    },
    {'title': 'Flood / Water', 'icon': Icons.water, 'color': Colors.blue},
    {'title': 'Debris / Blockage', 'icon': Icons.block, 'color': Colors.amber},
    {
      'title': 'Road / Infrastructure Damage',
      'icon': Icons.construction,
      'color': Colors.brown,
    },
    {
      'title': 'Building Collapse',
      'icon': Icons.domain_disabled,
      'color': Colors.grey,
    },
    {
      'title': 'Weapon Visible / Threat Object',
      'icon': Icons.warning,
      'color': Colors.deepPurple,
    },
    {
      'title': 'Theft / Assault / Suspicious Movement',
      'icon': Icons.security,
      'color': Colors.red.shade700,
    },
  ];

  Set<String> selectedIncidentTypes = {};

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
                      text: 'Incident Types',
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
          // Filter options list
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: List.generate(incidentTypes.length, (index) {
                    final incident = incidentTypes[index];
                    final isSelected = selectedIncidentTypes.contains(
                      incident['title'],
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedIncidentTypes.remove(incident['title']);
                            } else {
                              selectedIncidentTypes.add(incident['title']);
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
                                  ? incident['color']
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
                                  color: incident['color'].withOpacity(0.15),
                                ),
                                child: Icon(
                                  incident['icon'],
                                  color: incident['color'],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomText(
                                  text: incident['title'],
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppTheme.getPrimaryTextColor(),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: incident['color'],
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedIncidentTypes.clear());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardBackgroundColor(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.getBorderColor(),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: CustomText(
                          text: 'Reset',
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
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
          ),
        ],
      ),
    );
  }
}
