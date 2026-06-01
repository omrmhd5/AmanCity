import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/custom_button.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';

class StepPhone extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepPhone({
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
            'register.step_phone_title'.tr(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'register.step_phone_subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'register.phone_number'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.currentMode == AppThemeMode.dark
                      ? const Color(0xFF162A4D)
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.getBorderColor()),
                ),
                child: Text(
                  '🇪🇬 +20',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: AppTheme.getPrimaryTextColor(),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: '100 123 4567',
                    hintStyle: TextStyle(
                      color: AppColors.slateGray.withOpacity(0.6),
                    ),
                    filled: true,
                    fillColor: AppTheme.currentMode == AppThemeMode.dark
                        ? const Color(0xFF162A4D)
                        : AppColors.lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.getBorderColor()),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.getBorderColor()),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'common.continue_btn'.tr(),
            onPressed: () {
              // Prepend +20 to the phone number before saving
              final phoneNumber = controller.text.trim();
              if (phoneNumber.isNotEmpty) {
                controller.text = '+20$phoneNumber';
              }
              onNext();
            },
            icon: Icons.arrow_forward,
          ),
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
