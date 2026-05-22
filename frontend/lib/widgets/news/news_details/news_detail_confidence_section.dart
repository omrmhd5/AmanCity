import 'package:flutter/material.dart';
import '../../../models/incidents/osint_incident.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../shared/custom_text.dart';

class NewsDetailConfidenceSection extends StatelessWidget {
  final OsintIncident incident;

  const NewsDetailConfidenceSection({Key? key, required this.incident})
    : super(key: key);

  Color _getConfidenceColor() {
    if (incident.osintConfidence >= 0.7) {
      return AppColors.danger;
    } else if (incident.osintConfidence >= 0.4) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  String _getConfidenceLevelText() {
    if (incident.osintConfidence >= 0.7) return 'HIGH';
    if (incident.osintConfidence >= 0.4) return 'MEDIUM';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getConfidenceColor();
    final levelText = _getConfidenceLevelText();
    final percent = '${(incident.osintConfidence * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 15,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI CONFIDENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getSecondaryTextColor(),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: confidenceColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  levelText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Confidence card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Detection Score',
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    CustomText(
                      text: percent,
                      size: 18,
                      weight: FontWeight.w700,
                      color: confidenceColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: incident.osintConfidence,
                    minHeight: 8,
                    backgroundColor: confidenceColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      incident.osintConfidence >= 0.7
                          ? Icons.check_circle_rounded
                          : incident.osintConfidence >= 0.4
                          ? Icons.info_rounded
                          : Icons.warning_rounded,
                      size: 15,
                      color: confidenceColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        text: incident.osintConfidence >= 0.7
                            ? 'High AI confidence in detection'
                            : incident.osintConfidence >= 0.4
                            ? 'Moderate AI confidence in detection'
                            : 'Low AI confidence — verify manually',
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
