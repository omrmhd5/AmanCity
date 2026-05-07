import 'package:flutter/material.dart';
import '../shared/custom_text.dart';
import '../../utils/app_theme.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/logos/AmanCity_Logo_Only.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          CustomText(
            text: 'User Registration',
            size: 28,
            weight: FontWeight.w700,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 8),
          CustomText(
            text:
                'Create a secure account to access real-time safety alerts and reporting tools.',
            size: 13,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
