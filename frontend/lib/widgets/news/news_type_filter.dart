import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../data/incident_types_config.dart';
import '../shared/custom_text.dart';
import '../shared/custom_filter_chips.dart';

class NewsTypeFilter extends StatelessWidget {
  final String? selectedFilter;
  final Function(String?) onFilterChanged;
  final bool showAllTypes;
  final Function(bool) onShowAllTypesChanged;

  const NewsTypeFilter({
    Key? key,
    this.selectedFilter,
    required this.onFilterChanged,
    this.showAllTypes = false,
    required this.onShowAllTypesChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip
            CustomFilterChip(
              label: 'common.all'.tr(),
              isSelected: selectedFilter == null,
              selectedColor: AppColors.secondary,
              onTap: () => onFilterChanged(null),
              fontSize: 12,
              iconSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            const SizedBox(width: 6),
            // Incident type chips
            ...List.generate(
              showAllTypes ? IncidentTypesConfig.allTypes.length : 6,
              (index) {
                final config = IncidentTypesConfig.allTypes[index];
                final isSelected = selectedFilter == config.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CustomFilterChip(
                    label: config.displayName,
                    icon: config.icon,
                    isSelected: isSelected,
                    selectedColor: config.color,
                    iconColor: config.color,
                    onTap: () =>
                        onFilterChanged(isSelected ? null : config.key),
                    fontSize: 12,
                    iconSize: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                  ),
                );
              },
            ),
            // Show More button
            if (!showAllTypes && IncidentTypesConfig.allTypes.length > 6)
              GestureDetector(
                onTap: () => onShowAllTypesChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.getBorderColor(),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    text: '+${IncidentTypesConfig.allTypes.length - 6}',
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
