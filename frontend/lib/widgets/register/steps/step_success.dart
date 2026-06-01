import 'package:easy_localization/easy_localization.dart';
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
            "register.almost_there".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'register.verification_sent'.tr(),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'register.verify_before_login'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'register.back_to_login'.tr(),
            onPressed: onGoToLogin,
            icon: Icons.login,
          ),
        ],
      ),
    );
  }
}
