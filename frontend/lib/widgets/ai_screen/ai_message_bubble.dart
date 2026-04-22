import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_text.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? citationText;
  final VoidCallback? onCitationTap;

  const AiMessageBubble({
    Key? key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citationText,
    this.onCitationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        Colors.blue[600] ?? Colors.blue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomText(
                      text: 'AI',
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : AppColors.secondary.withOpacity(0.15),
                    borderRadius: isUser
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          )
                        : const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                    border: !isUser
                        ? Border.all(color: AppTheme.getBorderColor(), width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: text,
                        size: 13,
                        weight: FontWeight.w400,
                        color: isUser
                            ? Colors.white
                            : AppTheme.getPrimaryTextColor(),
                      ),
                      if (citationText != null && !isUser) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getBackgroundColor(),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.secondary,
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.assessment,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    text: 'DATA SOURCE',
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              CustomText(
                                text: citationText!,
                                size: 11,
                                weight: FontWeight.w400,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: onCitationTap,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomText(
                                      text: 'View on Map',
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.open_in_new,
                                      size: 10,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: isUser
                ? const EdgeInsets.only(right: 40)
                : const EdgeInsets.only(left: 40),
            child: CustomText(
              text: timestamp,
              size: 10,
              weight: FontWeight.w400,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
        ],
      ),
    );
  }
}
