import 'package:flutter/material.dart';
import '../../widgets/custom_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          // Shield Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.shield,
              color: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.primary
                  : AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          // App Title
          CustomText(
            text: 'AmanCity',
            size: 32,
            weight: FontWeight.w700,
            color: AppTheme.currentMode == AppThemeMode.dark
                ? Colors.white
                : AppColors.primary,
          ),
          const SizedBox(height: 8),
          // Tagline
          CustomText(
            text: 'Your Safety, Our Priority.',
            size: 13,
            weight: FontWeight.w500,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ],
      ),
    );
  }
}
