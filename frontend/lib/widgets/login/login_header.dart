import 'package:flutter/material.dart';
import '../shared/custom_text.dart';
import '../../utils/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          // App Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/logos/AmanCity_Logo_Only.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          // App Title
          CustomText(
            text: 'AmanCity',
            size: 32,
            weight: FontWeight.w700,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 8),
          // Tagline
          CustomText(
            text: 'Your Safety, Our Priority.',
            size: 13,
            weight: FontWeight.w500,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ],
      ),
    );
  }
}
