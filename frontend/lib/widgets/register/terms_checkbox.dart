import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/navigation_service.dart' as navigation;

class TermsCheckBox extends StatelessWidget {
  final bool isChecked;
  final Function(bool) onChanged;

  const TermsCheckBox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: isChecked,
              onChanged: (bool? newValue) {
                onChanged(newValue ?? false);
              },
              fillColor: MaterialStateProperty.all(
                isChecked ? AppColors.secondary : Colors.transparent,
              ),
              checkColor: Colors.white,
              side: BorderSide(
                color: isChecked
                    ? AppColors.secondary
                    : const Color(0xFF404A5C),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'register.agree_to_the'.tr(),
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: 'register.terms_of_service'.tr(),
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Navigate to Terms of Service page
                        navigation.Navigator.goTo('/terms');
                      },
                  ),
                  TextSpan(
                    text: 'register.and'.tr(),
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: 'register.privacy_policy'.tr(),
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Navigate to Privacy Policy page
                        navigation.Navigator.goTo('/privacy-policy');
                      },
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
