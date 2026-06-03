import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../models/incidents/bulk_incident.dart';

class BulkIncidentHeader extends StatelessWidget {
  final BulkIncident bulk;
  final String Function(DateTime) timeAgo;

  const BulkIncidentHeader({
    Key? key,
    required this.bulk,
    required this.timeAgo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = bulk.typeColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(bulk.typeIcon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bulk.type,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'incidents.reports_count_value'.tr(namedArgs: {'count': '${bulk.count}'}),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (bulk.locationText != null)
                Text(
                  bulk.locationText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                'incidents.first_reported_last_updated'.tr(namedArgs: {
                  'first': timeAgo(bulk.firstReportedAt),
                  'last': timeAgo(bulk.lastUpdatedAt)
                }),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
