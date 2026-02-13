import 'package:flutter/material.dart';
import '../../widgets/custom_text.dart';
import '../../utils/app_colors.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.security, color: AppColors.white, size: 24),
          ),
          const SizedBox(height: 16),
          const CustomText(
            text: 'User Registration',
            size: 28,
            weight: FontWeight.w700,
            color: AppColors.white,
          ),
          const SizedBox(height: 8),
          const CustomText(
            text:
                'Create a secure account to access real-time safety alerts and reporting tools.',
            size: 13,
            weight: FontWeight.w400,
            color: Color(0xFFCBD5E1),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
