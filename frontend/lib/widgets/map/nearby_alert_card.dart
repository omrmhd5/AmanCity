import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../shared/custom_text.dart';

class NearbyAlertCard extends StatelessWidget {
  final String incidentType;
  final String title;
  final String timeAgo;
  final String distance;
  final Color borderColor;
  final IconData icon;
  final double confidence;
  final String? locationText;
  final VoidCallback? onTap;

  const NearbyAlertCard({
    Key? key,
    required this.incidentType,
    required this.title,
    required this.timeAgo,
    required this.distance,
    required this.borderColor,
    required this.icon,
    this.confidence = 0.0,
    this.locationText,
    this.onTap,
  }) : super(key: key);

  Color _getConfidenceColor() {
    if (confidence >= 0.75) return AppColors.danger;
    if (confidence >= 0.65) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getConfidenceColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            borderColor.withOpacity(0.04),
            AppTheme.getCardBackgroundColor(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Type badge (with icon) + Time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: borderColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: borderColor),
                        const SizedBox(width: 4),
                        CustomText(
                          text: incidentType,
                          size: 10,
                          weight: FontWeight.w600,
                          color: borderColor,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  CustomText(
                    text: timeAgo,
                    size: 11,
                    weight: FontWeight.w900,
                    color: AppTheme.getSecondaryTextColor().withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              CustomText(
                text: title,
                size: 13,
                weight: FontWeight.w700,
                color: AppTheme.getPrimaryTextColor(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Location text
              if (locationText != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        text: locationText!,
                        size: 11,
                        weight: FontWeight.w400,
                        color: AppTheme.getSecondaryTextColor(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Confidence bar
              if (confidence > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Confidence',
                      size: 10,
                      weight: FontWeight.w500,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                    CustomText(
                      text: '${(confidence * 100).toStringAsFixed(0)}%',
                      size: 10,
                      weight: FontWeight.w600,
                      color: confidenceColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 6,
                    backgroundColor: AppTheme.getBorderColor(),
                    valueColor: AlwaysStoppedAnimation(confidenceColor),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Distance badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 11, color: borderColor),
                    const SizedBox(width: 4),
                    CustomText(
                      text: distance,
                      size: 10,
                      weight: FontWeight.w600,
                      color: borderColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
