import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_text.dart';

class AiChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback? onMicPress;

  const AiChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.onMicPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackgroundColor(),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Input field
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about safety...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (text) {
                    if (text.isNotEmpty) {
                      onSend(text);
                      controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Mic button
              GestureDetector(
                onTap: onMicPress,
                child: Icon(
                  Icons.mic,
                  color: AppTheme.getSecondaryTextColor(),
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: () {
                  if (controller.text.isNotEmpty) {
                    onSend(controller.text);
                    controller.clear();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CustomText(
          text: 'Not a replacement for emergency services. Call 122.',
          size: 9,
          weight: FontWeight.w500,
          color: AppTheme.getSecondaryTextColor(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
