import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Live Twitter News',
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.newspaper,
                        size: 28,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomText(
                          text: 'Powered by Grok AI',
                          size: 10,
                          weight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomText(
            text:
                'Real-time incidents detected from Twitter in Greater Cairo for the past 24 hours.',
            size: 12,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ],
      ),
    );
  }
}
