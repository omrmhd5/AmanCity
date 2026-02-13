import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../utils/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isChecked,
              onChanged: (bool? newValue) {
                onChanged(newValue ?? false);
              },
              fillColor: MaterialStateProperty.all(
                isChecked
                    ? (AppTheme.currentMode == AppThemeMode.dark
                          ? Colors.white
                          : AppColors.primary)
                    : Colors.transparent,
              ),
              checkColor: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.primary
                  : AppColors.white,
              side: BorderSide(
                color: isChecked
                    ? (AppTheme.currentMode == AppThemeMode.dark
                          ? Colors.white
                          : AppColors.primary)
                    : const Color(0xFF404A5C),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 12,
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
                    text: ' and ',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 12,
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
                      fontSize: 12,
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
