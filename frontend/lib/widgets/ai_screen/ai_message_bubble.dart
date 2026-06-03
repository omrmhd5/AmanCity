import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../shared/custom_text.dart';
import 'ai_route_home_button.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? citationText;
  final SafeRouteHomeData? routeHomeData;

  const AiMessageBubble({
    Key? key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citationText,
    this.routeHomeData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    // In Arabic (RTL): user bubble on LEFT, AI on RIGHT — opposite of LTR
    // In English (LTR): user bubble on RIGHT, AI on LEFT
    final bool bubbleOnRight = isArabic ? !isUser : isUser;

    // Avatar is shown for AI (non-user) messages only
    final Widget aiAvatar = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, Colors.blue[600] ?? Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
      ),
    );

    // Corners always match the message type (same as English), regardless of RTL
    // User bubble: sharp top-right; AI bubble: sharp top-left
    final BorderRadius bubbleRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    final Widget bubble = Flexible(
      child: Container(
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.secondary.withOpacity(0.25)
              : AppTheme.getCardBackgroundColor(),
          borderRadius: bubbleRadius,
          border: Border.all(
            color: isUser
                ? AppColors.secondary.withOpacity(0.5)
                : AppTheme.getBorderColor(),
            width: 1,
          ),
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
                  ? (AppTheme.currentMode == AppThemeMode.dark
                        ? Colors.white
                        : AppColors.darkText)
                  : AppTheme.getPrimaryTextColor(),
            ),
            if (citationText != null && !isUser) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: AppColors.secondary, width: 3),
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
                          text: 'ai.data_source'.tr(),
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
                      onTap: null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: 'map.navigate_to_location'.tr(),
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new,
                            size: 10,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (routeHomeData != null && !isUser)
              AiRouteHomeButton(data: routeHomeData!),
            // Timestamp inside bubble
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timestamp,
                style: TextStyle(
                  fontSize: 10,
                  color: isUser
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.getSecondaryTextColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            bubbleOnRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                bubbleOnRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // AI avatar on left for LTR, on right for RTL
              if (!isUser && !isArabic) ...[aiAvatar, const SizedBox(width: 8)],
              bubble,
              if (!isUser && isArabic) ...[const SizedBox(width: 8), aiAvatar],
              const SizedBox(width: 8),
              if (isUser) const SizedBox(width: 32),
            ],
          ),
        ],
      ),
    );
  }
}
