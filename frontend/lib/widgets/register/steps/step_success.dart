import 'package:flutter/material.dart';
import '../../shared/custom_button.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';

class StepSuccess extends StatelessWidget {
  final String email;
  final VoidCallback onGoToLogin;

  const StepSuccess({Key? key, required this.email, required this.onGoToLogin})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "You're almost there!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A verification link has been sent to',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.secondary
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please verify your email before logging in.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Back to Login',
            onPressed: onGoToLogin,
            icon: Icons.login,
            backgroundColor: AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.secondary
                : AppColors.primary,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}
