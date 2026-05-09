import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class RegisterStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const RegisterStepIndicator({
    Key? key,
    required this.currentStep,
    this.totalSteps = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.currentMode == AppThemeMode.dark
        ? AppColors.secondary
        : AppColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isPast = index < currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isActive || isPast)
                ? activeColor
                : activeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
