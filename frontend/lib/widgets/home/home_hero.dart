import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class HomeHero extends StatelessWidget {
  const HomeHero({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo with teal glow
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.28),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/logos/AmanCity_Logo_Only.png',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Gradient title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.secondary, AppTheme.getPrimaryTextColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'app.name'.tr(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        // Pill badge subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'app.tagline'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
