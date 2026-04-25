import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../shared/custom_text.dart';

class NewsScanResultBanner extends StatelessWidget {
  final int scanned;
  final int saved;
  final VoidCallback onDismiss;

  const NewsScanResultBanner({
    Key? key,
    required this.scanned,
    required this.saved,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Scan Complete',
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppTheme.getPrimaryTextColor(),
                ),
                const SizedBox(height: 4),
                CustomText(
                  text:
                      'Scanned: $scanned tweets • Saved: $saved new incidents',
                  size: 11,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 18,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
        ],
      ),
    );
  }
}
