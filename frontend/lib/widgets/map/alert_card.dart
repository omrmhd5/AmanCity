import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../custom_text.dart';

class AlertCard extends StatelessWidget {
  final String alertType;
  final String description;
  final String timeAgo;
  final String distance;
  final Color borderColor;
  final IconData icon;
  final VoidCallback? onTap;

  const AlertCard({
    Key? key,
    required this.alertType,
    required this.description,
    required this.timeAgo,
    required this.distance,
    required this.borderColor,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppTheme.getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
            top: BorderSide(color: AppTheme.getBorderColor(), width: 1),
            right: BorderSide(color: AppTheme.getBorderColor(), width: 1),
            bottom: BorderSide(color: AppTheme.getBorderColor(), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderColor.withOpacity(0.2),
                      ),
                      child: Icon(icon, color: borderColor, size: 14),
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      text: alertType,
                      size: 11,
                      weight: FontWeight.w600,
                      color: borderColor,
                    ),
                  ],
                ),
                CustomText(
                  text: timeAgo,
                  size: 9,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            CustomText(
              text: description,
              size: 10,
              weight: FontWeight.w400,
              color: AppTheme.getSecondaryTextColor(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Distance
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 12,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                const SizedBox(width: 4),
                CustomText(
                  text: distance,
                  size: 9,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
