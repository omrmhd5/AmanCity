import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_text.dart';

class AiQuickPrompts extends StatelessWidget {
  final Function(String) onPromptSelected;

  static const List<String> prompts = [
    'Is my area safe?',
    'Report incident',
    'Safest route home',
    'Emergency numbers',
  ];

  const AiQuickPrompts({Key? key, required this.onPromptSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            prompts.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                right: index < prompts.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => onPromptSelected(prompts[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardBackgroundColor(),
                    border: Border.all(
                      color: AppTheme.getBorderColor(),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomText(
                    text: prompts[index],
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
