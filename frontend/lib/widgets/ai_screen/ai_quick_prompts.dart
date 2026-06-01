import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../shared/custom_filter_chips.dart';

class AiQuickPrompts extends StatelessWidget {
  final Function(String) onPromptSelected;

  List<String> get prompts => [
    'ai.prompt_area_safe'.tr(),
    'ai.prompt_safest_route'.tr(),
    'ai.prompt_emergency_numbers'.tr(),
  ];

  const AiQuickPrompts({Key? key, required this.onPromptSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.0),
                AppColors.secondary.withOpacity(0.2),
                AppColors.secondary.withOpacity(0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 15,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'ai.quick_prompts'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getSecondaryTextColor(),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              prompts.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right: index < prompts.length - 1 ? 8 : 0,
                ),
                child: CustomFilterChip(
                  label: prompts[index],
                  isSelected: false,
                  selectedColor: AppColors.secondary,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  onTap: () => onPromptSelected(prompts[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
