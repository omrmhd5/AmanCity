import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class CustomFilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color selectedColor;
  final Color? iconColor;
  final VoidCallback onTap;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;

  const CustomFilterChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.selectedColor,
    this.iconColor,
    required this.onTap,
    this.fontSize = 11,
    this.iconSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  });

  @override
  State<CustomFilterChip> createState() => _CustomFilterChipState();
}

class _CustomFilterChipState extends State<CustomFilterChip> {
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
          padding: widget.padding,
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
                  size: widget.iconSize,
                  color: widget.iconColor ?? widget.selectedColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.fontSize,
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
