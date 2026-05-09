import 'package:flutter/material.dart';
import '../../shared/custom_text_field.dart';
import '../../shared/custom_button.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';

class StepName extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const StepName({Key? key, required this.controller, required this.onNext})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            "What's your name?",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how you\'ll appear in the app.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 36),
          CustomTextField(
            label: 'Full Name',
            placeholder: 'e.g. Layla Ahmed',
            prefixIcon: Icons.person_outline,
            controller: controller,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Continue',
            onPressed: onNext,
            icon: Icons.arrow_forward,
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
