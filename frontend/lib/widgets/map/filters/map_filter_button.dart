import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import 'filter_options_sheet.dart';

class MapFilterButton extends StatefulWidget {
  final VoidCallback? onFilterPressed;
  final Function(FilterSettings settings)? onSettingsChanged;
  final double currentRadius;
  final Set<String> selectedIncidentTypes;
  final bool hasActiveFilters;

  const MapFilterButton({
    Key? key,
    this.onFilterPressed,
    this.onSettingsChanged,
    this.currentRadius = 5.0,
    this.selectedIncidentTypes = const {},
    this.hasActiveFilters = false,
  }) : super(key: key);

  @override
  State<MapFilterButton> createState() => _MapFilterButtonState();
}

class _MapFilterButtonState extends State<MapFilterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onFilterPressed?.call();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => FilterOptionsSheet(
            initialRadius: widget.currentRadius,
            initialSelectedTypes: widget.selectedIncidentTypes,
          ),
        ).then((result) {
          if (result is FilterSettings) {
            widget.onSettingsChanged?.call(result);
          }
        });
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: _pressed
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 320),
        curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.primary.withOpacity(0.58),
                              AppColors.primary.withOpacity(0.44),
                            ]
                          : [
                              Colors.white.withOpacity(0.72),
                              Colors.white.withOpacity(0.55),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.65),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: widget.hasActiveFilters
                        ? AppColors.secondary
                        : AppTheme.getPrimaryTextColor(),
                    size: 20,
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
                          top: Radius.circular(18),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(isDark ? 0.30 : 0.75),
                            Colors.white.withOpacity(isDark ? 0.14 : 0.45),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Active filter teal dot
                if (widget.hasActiveFilters)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.primary : Colors.white,
                          width: 1.5,
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
