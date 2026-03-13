import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../shared/custom_text.dart';

class NearbyAlertCard extends StatelessWidget {
  final String incidentType; // e.g., "Damaged Building"
  final String title; // e.g., "HELLO"
  final String description; // e.g., "AHMED"
  final String timeAgo;
  final String distance;
  final Color borderColor;
  final IconData icon;
  final VoidCallback? onTap;

  const NearbyAlertCard({
    Key? key,
    required this.incidentType,
    required this.title,
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
              // Top row: Icon + Title/Type column + Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: borderColor.withOpacity(0.2),
                    ),
                    child: Icon(icon, color: borderColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Title and Type column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: title,
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
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
                          child: CustomText(
                            text: incidentType,
                            size: 10,
                            weight: FontWeight.w600,
                            color: borderColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time on top right
                  CustomText(
                    text: timeAgo,
                    size: 9,
                    weight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor().withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              CustomText(
                text: description,
                size: 11,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                height: 1.4,
              ),
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
