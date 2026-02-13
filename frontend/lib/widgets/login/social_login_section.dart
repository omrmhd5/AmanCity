import 'package:flutter/material.dart';
import '../custom_text.dart';
import '../custom_gesture_detector.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class SocialLoginSection extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;

  const SocialLoginSection({
    Key? key,
    required this.onGooglePressed,
    required this.onApplePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(color: AppTheme.getBorderColor(), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CustomText(
                text: 'Or continue with',
                size: 12,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ),
            Expanded(
              child: Divider(color: AppTheme.getBorderColor(), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Social Login Buttons
        Row(
          children: [
            Expanded(
              child: CustomGestureDetector(
                onTap: onGooglePressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.getBorderColor()),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.currentMode == AppThemeMode.dark
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.language,
                        color: AppTheme.getPrimaryTextColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        text: 'Google',
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomGestureDetector(
                onTap: onApplePressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.getBorderColor()),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.currentMode == AppThemeMode.dark
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apple,
                        color: AppTheme.getPrimaryTextColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        text: 'Apple',
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
