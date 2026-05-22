import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../data/incident_types_config.dart';
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
            // "All" chip
            _FilterChip(
              label: 'All',
              isSelected: selectedFilter == null,
              selectedColor: AppColors.secondary,
              onTap: () => onFilterChanged(null),
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
                  child: _FilterChip(
                    label: config.displayName,
                    icon: config.icon,
                    isSelected: isSelected,
                    selectedColor: config.color,
                    iconColor: config.color,
                    onTap: () =>
                        onFilterChanged(isSelected ? null : config.key),
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

class _FilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color selectedColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.selectedColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: _pressed
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.selectedColor.withOpacity(0.15)
                : AppTheme.getCardBackgroundColor(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.selectedColor.withOpacity(0.5)
                  : AppTheme.getBorderColor(),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 13,
                  color: widget.iconColor ?? widget.selectedColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? widget.selectedColor
                      : AppTheme.getPrimaryTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
