import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_text.dart';

class NewsHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const NewsHeader({Key? key, this.onBackPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBackPressed != null) ...[
                GestureDetector(
                  onTap: onBackPressed,
                  child: Container(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                ),
              ],
              Icon(Icons.newspaper, size: 28, color: AppColors.secondary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Live Twitter News',
                    size: 24,
                    weight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  CustomText(
                    text: 'Powered by Grok AI',
                    size: 12,
                    weight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          CustomText(
            text: 'Real-time incidents detected from Twitter in Greater Cairo',
            size: 12,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ],
      ),
    );
  }
}
