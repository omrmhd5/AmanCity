import 'package:flutter/material.dart';
import '../../models/osint_incident.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../../data/incident_types_config.dart';
import '../shared/custom_text.dart';

class NewsFeedCard extends StatelessWidget {
  final OsintIncident incident;
  final VoidCallback onTap;

  const NewsFeedCard({Key? key, required this.incident, required this.onTap})
    : super(key: key);

  /// Get color based on osintConfidence severity
  Color _getConfidenceColor() {
    if (incident.osintConfidence >= 0.7) {
      return AppColors.danger; // Red for high severity
    } else if (incident.osintConfidence >= 0.4) {
      return AppColors.warning; // Amber for medium
    } else {
      return AppColors.success; // Green for low
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeConfig = IncidentTypesConfig.getByKey(incident.type);
    final confidenceColor = _getConfidenceColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            typeConfig.color.withOpacity(0.04),
            AppTheme.getCardBackgroundColor(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: typeConfig.color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: typeConfig.color.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type Badge + Time + Source Badge
            Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeConfig.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeConfig.icon, size: 12, color: typeConfig.color),
                      const SizedBox(width: 4),
                      CustomText(
                        text: incident.type,
                        size: 10,
                        weight: FontWeight.w600,
                        color: typeConfig.color,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Time
                CustomText(
                  text: incident.timeAgo,
                  size: 11,
                  weight: FontWeight.w900,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            CustomText(
              text: incident.title,
              size: 13,
              weight: FontWeight.w600,
              color: AppTheme.getPrimaryTextColor(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Location + Precision Badge
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
                    text: incident.locationText,
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: incident.locationPrecision == "EXACT"
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomText(
                    text: incident.locationPrecision,
                    size: 8,
                    weight: FontWeight.w600,
                    color: incident.locationPrecision == "EXACT"
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Confidence Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      text:
                          '${(incident.osintConfidence * 100).toStringAsFixed(0)}%',
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
                    value: incident.osintConfidence,
                    minHeight: 6,
                    backgroundColor: AppTheme.getBorderColor(),
                    valueColor: AlwaysStoppedAnimation(confidenceColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Twitter Source Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  CustomText(
                    text:
                        '${incident.sourceUrls.length} source${incident.sourceUrls.length != 1 ? 's' : ''}',
                    size: 10,
                    weight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
