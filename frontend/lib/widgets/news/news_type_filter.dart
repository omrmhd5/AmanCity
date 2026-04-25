import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/incident_types_config.dart';
import '../shared/custom_text.dart';

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
            // "All" button
            FilterChip(
              label: const Text(
                'All',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
              selected: selectedFilter == null,
              onSelected: (selected) {
                onFilterChanged(null);
              },
              selectedColor: const Color(0xFF00A86B),
              backgroundColor: AppTheme.getCardBackgroundColor(),
              side: BorderSide(
                color: selectedFilter == null
                    ? const Color(0xFF00A86B)
                    : AppTheme.getBorderColor(),
                width: selectedFilter == null ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 6),
            // Incident types (limited to 6 or all if expanded)
            ...List.generate(
              showAllTypes ? IncidentTypesConfig.allTypes.length : 6,
              (index) {
                final config = IncidentTypesConfig.allTypes[index];
                final isSelected = selectedFilter == config.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config.icon,
                          size: 14,
                          color: isSelected ? Colors.white : config.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          config.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.getPrimaryTextColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      onFilterChanged(selected ? config.key : null);
                    },
                    selectedColor: config.color,
                    backgroundColor: AppTheme.getCardBackgroundColor(),
                    side: BorderSide(
                      color: isSelected
                          ? config.color
                          : AppTheme.getBorderColor(),
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
            // Show More button
            if (!showAllTypes && IncidentTypesConfig.allTypes.length > 6)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () {
                    onShowAllTypesChanged(true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.getSecondaryTextColor(),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomText(
                      text: '+${IncidentTypesConfig.allTypes.length - 6}',
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
