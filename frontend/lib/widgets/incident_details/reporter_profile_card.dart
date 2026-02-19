import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/map_incident.dart';
import '../custom_text.dart';

class ReporterProfileCard extends StatelessWidget {
  final MapIncident incident;
  final String timeAgo;
  final String reporterId;
  final double karma;

  const ReporterProfileCard({
    Key? key,
    required this.incident,
    required this.timeAgo,
    this.reporterId = 'Anon #442',
    this.karma = 4.8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incident Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: incident.severityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: incident.severityColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: CustomText(
              text: incident.type.name.toUpperCase(),
              size: 10,
              weight: FontWeight.w600,
              color: incident.severityColor,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          CustomText(
            text: incident.title,
            size: 14,
            weight: FontWeight.w700,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 8),
          CustomText(
            text:
                'An incident was reported in the Maadi sector. Emergency services have been notified and are responding to the situation.',
            size: 12,
            weight: FontWeight.w400,
            color: AppTheme.getSecondaryTextColor(),
            height: 1.5,
          ),
          const SizedBox(height: 12),

          // Time Info
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(width: 8),
              CustomText(
                text: timeAgo,
                size: 12,
                weight: FontWeight.w500,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: AppTheme.getBorderColor()),
          const SizedBox(height: 16),

          // Reporter Info Header
          CustomText(
            text: 'REPORTED BY',
            size: 10,
            weight: FontWeight.w600,
            color: AppTheme.getSecondaryTextColor(),
          ),
          const SizedBox(height: 12),

          // Reporter Profile
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 28,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: reporterId,
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
