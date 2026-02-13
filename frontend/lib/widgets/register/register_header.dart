import 'package:flutter/material.dart';
import '../../widgets/custom_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.currentMode == AppThemeMode.dark
                  ? Colors.white.withOpacity(0.1)
                  : AppColors.softGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.currentMode == AppThemeMode.dark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.softGray,
              ),
            ),
            child: Icon(
              Icons.security,
              color: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.white
                  : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          CustomText(
            text: 'User Registration',
            size: 28,
            weight: FontWeight.w700,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 8),
          CustomText(
            text:
                'Create a secure account to access real-time safety alerts and reporting tools.',
            size: 13,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
