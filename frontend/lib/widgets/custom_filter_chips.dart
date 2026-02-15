import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'custom_text.dart';

class CustomFilterChips extends StatelessWidget {
  final List<Map<String, dynamic>> filters; // [{label, icon}, ...]
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;
  final bool showIcon;
  final Color selectedColor;

  const CustomFilterChips({
    Key? key,
    required this.filters,
    this.selectedFilter,
    required this.onFilterChanged,
    this.showIcon = true,
    this.selectedColor = const Color(0xFF00A86B),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['label'];

          return Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 8,
            ),
            child: FilterChip(
              label: Row(
                children: [
                  if (showIcon && filter['icon'] != null) ...[
                    Icon(
                      filter['icon'],
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.getPrimaryTextColor(),
                    ),
                    const SizedBox(width: 6),
                  ],
                  CustomText(
                    text: filter['label'],
                    size: 11,
                    weight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.getPrimaryTextColor(),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                onFilterChanged(selected ? filter['label'] : null);
              },
              backgroundColor: AppTheme.getCardBackgroundColor(),
              selectedColor: selectedColor,
              side: BorderSide(
                color: isSelected ? selectedColor : AppTheme.getBorderColor(),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
