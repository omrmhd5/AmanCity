import 'package:flutter/material.dart';
import '../custom_button.dart';
import '../custom_text.dart';
import '../custom_gesture_detector.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/navigation_service.dart' as navigation;

class RegisterFooter extends StatelessWidget {
  final VoidCallback onRegisterPressed;
  final bool isLoading;

  const RegisterFooter({
    Key? key,
    required this.onRegisterPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.currentMode == AppThemeMode.dark
                ? [
                    AppColors.primary.withOpacity(0),
                    AppColors.primary,
                    AppColors.primary,
                  ]
                : [
                    AppColors.lightBackground.withOpacity(0),
                    AppColors.lightBackground,
                    AppColors.lightBackground,
                  ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          32,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'REGISTER ACCOUNT',
              onPressed: onRegisterPressed,
              isLoading: isLoading,
              backgroundColor: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.secondary
                  : AppColors.primary,
              textColor: AppColors.white,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: 'Already have an account? ',
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                CustomGestureDetector(
                  onTap: () {
                    navigation.Navigator.goBack();
                  },
                  enableScale: false,
                  child: CustomText(
                    text: 'Login',
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppTheme.currentMode == AppThemeMode.dark
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
