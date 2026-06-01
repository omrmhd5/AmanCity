import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../shared/custom_text_field.dart';
import '../../shared/custom_button.dart';
import '../../../utils/app_theme.dart';

class StepEmail extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepEmail({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'register.step_email_title'.tr(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "register.step_email_subtitle".tr(),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 36),
          CustomTextField(
            label: 'register.email'.tr(),
            placeholder: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            controller: controller,
          ),
          const SizedBox(height: 32),
          CustomButton(text: 'common.continue_btn'.tr(), onPressed: onNext),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onBack,
              child: Text(
                '← Back',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
