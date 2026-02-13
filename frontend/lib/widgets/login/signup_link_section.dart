import 'package:flutter/material.dart';
import '../custom_text.dart';
import '../custom_gesture_detector.dart';
import '../../utils/app_colors.dart';

class SignUpLinkSection extends StatelessWidget {
  final VoidCallback onSignUpPressed;

  const SignUpLinkSection({Key? key, required this.onSignUpPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomText(
            text: "Don't have an account? ",
            size: 13,
            weight: FontWeight.w400,
            color: AppColors.slateGray,
          ),
          CustomGestureDetector(
            onTap: onSignUpPressed,
            enableScale: false,
            child: const CustomText(
              text: 'Sign Up',
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
