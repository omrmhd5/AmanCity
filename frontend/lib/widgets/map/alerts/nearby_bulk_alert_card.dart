import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../shared/custom_text.dart';

class NearbyBulkAlertCard extends StatelessWidget {
  final String incidentType;
  final int count;
  final String timeAgo;
  final String distance;
  final Color borderColor;
  final IconData icon;
  final double avgConfidence;
  final String? locationText;
  final bool hasHumanReports;
  final bool hasOsintReports;
  final VoidCallback? onTap;

  const NearbyBulkAlertCard({
    Key? key,
    required this.incidentType,
    required this.count,
    required this.timeAgo,
    required this.distance,
    required this.borderColor,
    required this.icon,
    this.avgConfidence = 0.0,
    this.locationText,
    this.hasHumanReports = false,
    this.hasOsintReports = false,
    this.onTap,
  }) : super(key: key);

  Color _getConfidenceColor() {
    if (avgConfidence >= 0.75) return AppColors.danger;
    if (avgConfidence >= 0.65) return AppColors.warning;
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
              // Top row: Type badge + Count badge
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
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomText(
                      text: '×$count',
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title (showing "Grouped Incidents")
              CustomText(
                text: '$count Grouped Incidents',
                size: 13,
                weight: FontWeight.w700,
                color: AppTheme.getPrimaryTextColor(),
                maxLines: 1,
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

              const SizedBox(height: 10),

              // Source chips (Human/OSINT)
              Wrap(
                spacing: 6,
                children: [
                  if (hasHumanReports)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 11,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          CustomText(
                            text: 'Human',
                            size: 10,
                            weight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  if (hasOsintReports)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.radar,
                            size: 11,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 3),
                          CustomText(
                            text: 'OSINT',
                            size: 10,
                            weight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Confidence bar
              if (avgConfidence > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Avg Confidence',
                      size: 10,
                      weight: FontWeight.w500,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                    CustomText(
                      text: '${(avgConfidence * 100).toStringAsFixed(0)}%',
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
                    value: avgConfidence,
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
