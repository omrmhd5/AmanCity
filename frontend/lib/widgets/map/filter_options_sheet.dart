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
  final List<Map<String, dynamic>> filterOptions = [
    {'title': 'Incident Types', 'icon': Icons.warning, 'color': Colors.red},
    {
      'title': 'Emergency Services',
      'icon': Icons.local_hospital,
      'color': AppColors.secondary,
    },
    {'title': 'Danger Zones', 'icon': Icons.flag, 'color': Colors.amber},
    {
      'title': 'Distance Range',
      'icon': Icons.location_on,
      'color': Colors.blue,
    },
  ];

  Set<String> selectedFilters = {};

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
                      text: 'Filter Options',
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
                  children: List.generate(filterOptions.length, (index) {
                    final option = filterOptions[index];
                    final isSelected = selectedFilters.contains(
                      option['title'],
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedFilters.remove(option['title']);
                            } else {
                              selectedFilters.add(option['title']);
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
                                  ? option['color']
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
                                  color: option['color'].withOpacity(0.15),
                                ),
                                child: Icon(
                                  option['icon'],
                                  color: option['color'],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomText(
                                  text: option['title'],
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppTheme.getPrimaryTextColor(),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: option['color'],
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
                      setState(() => selectedFilters.clear());
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
