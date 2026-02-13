import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/map_incident.dart';
import '../custom_text.dart';

class IncidentDetailSheet extends StatelessWidget {
  final MapIncident incident;
  final String timeAgo;

  const IncidentDetailSheet({
    Key? key,
    required this.incident,
    required this.timeAgo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: incident.severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  incident.typeIcon,
                  color: incident.severityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: incident.title,
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    CustomText(
                      text: incident.typeLabel,
                      size: 12,
                      weight: FontWeight.w400,
                      color: incident.severityColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          CustomText(
            text: incident.description,
            size: 13,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
          ),
          const SizedBox(height: 12),
          // Timestamp
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(width: 6),
              CustomText(
                text: timeAgo,
                size: 11,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
