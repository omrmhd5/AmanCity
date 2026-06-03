import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../utils/app_theme.dart';
import '../../../../data/app_colors.dart';

class IncomingSosSlideToIgnore extends StatefulWidget {
  final VoidCallback onDismiss;

  const IncomingSosSlideToIgnore({Key? key, required this.onDismiss}) : super(key: key);

  @override
  State<IncomingSosSlideToIgnore> createState() => _IncomingSosSlideToIgnoreState();
}

class _IncomingSosSlideToIgnoreState extends State<IncomingSosSlideToIgnore> {
  double _ignoreDragOffset = 0.0;
  static const double _ignoreThumbSize = 44.0;
  static const double _ignoreThreshold = 0.8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDark = AppTheme.currentMode == AppThemeMode.dark;
          final maxOffset = (constraints.maxWidth - _ignoreThumbSize - 8).clamp(
            0.0,
            double.infinity,
          );
          final progress = maxOffset > 0
              ? (_ignoreDragOffset / maxOffset).clamp(0.0, 1.0)
              : 0.0;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _ignoreDragOffset = (_ignoreDragOffset + details.delta.dx)
                    .clamp(0.0, maxOffset);
              });
            },
            onHorizontalDragEnd: (_) {
              if (maxOffset > 0 &&
                  _ignoreDragOffset / maxOffset >= _ignoreThreshold) {
                HapticFeedback.mediumImpact();
                widget.onDismiss();
              } else {
                setState(() => _ignoreDragOffset = 0.0);
              }
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.white.withOpacity(0.10)
                        : AppTheme.getPrimaryTextColor().withOpacity(0.12),
                    isDark
                        ? Colors.white.withOpacity(0.07)
                        : AppTheme.getPrimaryTextColor().withOpacity(0.06),
                  ],
                ),
                border: Border.all(color: AppTheme.getBorderColor(), width: 1),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 40),
                    width: (_ignoreDragOffset + _ignoreThumbSize + 6).clamp(
                      _ignoreThumbSize + 6,
                      constraints.maxWidth,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2 * progress),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: (1.0 - progress * 2).clamp(0.0, 0.7),
                      child: Text(
                        'sos.slide_to_ignore'.tr(),
                        style: TextStyle(
                          color: AppTheme.getPrimaryTextColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4 + _ignoreDragOffset,
                    top: 5,
                    child: Container(
                      width: _ignoreThumbSize,
                      height: _ignoreThumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        progress >= _ignoreThreshold
                            ? Icons.check
                            : Icons.close,
                        color: progress >= _ignoreThreshold
                            ? AppColors.success
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
