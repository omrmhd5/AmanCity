import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class SosUtilityToggles extends StatelessWidget {
  final bool flashEnabled;
  final bool sirenEnabled;
  final ValueChanged<bool> onFlashToggle;
  final ValueChanged<bool> onSirenToggle;

  const SosUtilityToggles({
    Key? key,
    required this.flashEnabled,
    required this.sirenEnabled,
    required this.onFlashToggle,
    required this.onSirenToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              icon: Icons.flashlight_on,
              label: 'Strobe',
              sublabel: 'Flashlight',
              isActive: flashEnabled,
              onTap: () => onFlashToggle(!flashEnabled),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ToggleButton(
              icon: Icons.campaign,
              label: 'Alarm',
              sublabel: 'Loud Siren',
              isActive: sirenEnabled,
              onTap: () => onSirenToggle(!sirenEnabled),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.danger.withOpacity(0.10)
              : AppTheme.getBackgroundColor().withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.danger.withOpacity(0.40)
                : AppTheme.getBorderColor().withOpacity(0.15),
            width: isActive ? 1.5 : 0.75,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.danger.withOpacity(0.12)
                        : AppTheme.getBorderColor().withOpacity(0.08),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isActive
                          ? AppColors.danger.withOpacity(0.2)
                          : AppTheme.getBorderColor().withOpacity(0.12),
                      width: 0.75,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? AppColors.danger
                        : AppTheme.getSecondaryTextColor(),
                    size: 26,
                  ),
                ),
                if (isActive)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.getBackgroundColor(),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.danger
                    : AppTheme.getPrimaryTextColor(),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
