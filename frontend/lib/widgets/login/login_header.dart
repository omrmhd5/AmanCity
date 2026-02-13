import 'package:flutter/material.dart';
import '../../widgets/custom_text.dart';
import '../../utils/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          // Shield Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.shield, color: AppColors.white, size: 32),
          ),
          const SizedBox(height: 16),
          // App Title
          const CustomText(
            text: 'AmanCity',
            size: 32,
            weight: FontWeight.w700,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          // Tagline
          const CustomText(
            text: 'Your Safety, Our Priority.',
            size: 13,
            weight: FontWeight.w500,
            color: AppColors.slateGray,
          ),
        ],
      ),
    );
  }
}
