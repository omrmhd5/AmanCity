import 'package:flutter/material.dart';
import '../custom_text.dart';
import '../custom_gesture_detector.dart';
import '../../utils/app_colors.dart';

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
            Expanded(child: Divider(color: AppColors.softGray, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CustomText(
                text: 'Or continue with',
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.slateGray,
              ),
            ),
            Expanded(child: Divider(color: AppColors.softGray, thickness: 1)),
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
                    border: Border.all(color: AppColors.softGray),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.language,
                        color: AppColors.darkText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const CustomText(
                        text: 'Google',
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.darkText,
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
                    border: Border.all(color: AppColors.softGray),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.apple,
                        color: AppColors.darkText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const CustomText(
                        text: 'Apple',
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.darkText,
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
