import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class MapActionButtons extends StatefulWidget {
  final VoidCallback? onReportPressed;
  final VoidCallback onMyLocationPressed;

  const MapActionButtons({
    Key? key,
    required this.onReportPressed,
    required this.onMyLocationPressed,
  }) : super(key: key);

  @override
  State<MapActionButtons> createState() => _MapActionButtonsState();
}

class _MapActionButtonsState extends State<MapActionButtons> {
  bool _reportPressed = false;
  bool _locationPressed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Report button
        Positioned(
          right: 16,
          bottom: 180,
          child: _GlassFAB(
            icon: Icons.flag_rounded,
            tintColor: AppColors.danger,
            isPressed: _reportPressed,
            onTapDown: () => setState(() => _reportPressed = true),
            onTapUp: () {
              setState(() => _reportPressed = false);
              widget.onReportPressed?.call();
            },
            onTapCancel: () => setState(() => _reportPressed = false),
          ),
        ),

        // My Location button
        Positioned(
          right: 16,
          bottom: 110,
          child: _GlassFAB(
            icon: Icons.my_location_rounded,
            tintColor: AppColors.secondary,
            isPressed: _locationPressed,
            onTapDown: () => setState(() => _locationPressed = true),
            onTapUp: () {
              setState(() => _locationPressed = false);
              widget.onMyLocationPressed();
            },
            onTapCancel: () => setState(() => _locationPressed = false),
          ),
        ),
      ],
    );
  }
}

class _GlassFAB extends StatelessWidget {
  final IconData icon;
  final Color tintColor;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const _GlassFAB({
    required this.icon,
    required this.tintColor,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.88 : 1.0,
        duration: isPressed
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 320),
        curve: isPressed ? Curves.easeIn : Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Stack(
              children: [
                // Glass base
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              tintColor.withOpacity(0.22),
                              tintColor.withOpacity(0.10),
                            ]
                          : [
                              tintColor.withOpacity(0.18),
                              tintColor.withOpacity(0.08),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? tintColor.withOpacity(0.30)
                          : tintColor.withOpacity(0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.38 : 0.12),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: tintColor.withOpacity(0.18),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: tintColor, size: 24),
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
                            Colors.white.withOpacity(isDark ? 0.32 : 0.72),
                            Colors.white.withOpacity(isDark ? 0.14 : 0.45),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Inner sheen
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.06 : 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.50],
                        ),
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
