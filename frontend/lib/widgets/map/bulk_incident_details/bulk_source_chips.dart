import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../models/incidents/bulk_incident.dart';

class BulkSourceChips extends StatelessWidget {
  final BulkIncident bulk;

  const BulkSourceChips({Key? key, required this.bulk}) : super(key: key);

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (bulk.hasHumanReports)
          _chip(
            Icons.person_outline,
            'map.human_reports'.tr(),
            AppColors.secondary,
          ),
        if (bulk.hasOsintReports)
          _chip(
            Icons.radar,
            'map.osint_intelligence'.tr(),
            const Color(0xFF7C3AED),
          ),
        _chip(
          Icons.analytics_outlined,
          'incidents.confidence_percent'.tr(namedArgs: {'n': '${(bulk.avgConfidence * 100).round()}'}),
          bulk.avgConfidence >= 0.7
              ? AppColors.danger
              : bulk.avgConfidence >= 0.4
              ? AppColors.warning
              : AppColors.success,
        ),
      ],
    );
  }
}
