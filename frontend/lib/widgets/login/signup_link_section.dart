import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../shared/custom_text.dart';
import '../shared/custom_gesture_detector.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/navigation_service.dart' as navigation;

class SignUpLinkSection extends StatelessWidget {
  const SignUpLinkSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            text: 'auth.no_account'.tr(),
            size: 13,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
          ),
          CustomGestureDetector(
            onTap: () {
              navigation.Navigator.goTo('/register');
            },
            enableScale: false,
            child: CustomText(
              text: 'auth.sign_up'.tr(),
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
