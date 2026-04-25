import 'package:flutter/material.dart';
import '../../../models/osint_incident.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getConfidenceColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Confidence Score',
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SizedBox(
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: incident.osintConfidence,
                        strokeWidth: 8,
                        backgroundColor: AppTheme.getBorderColor(),
                        valueColor: AlwaysStoppedAnimation(confidenceColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          text:
                              '${(incident.osintConfidence * 100).toStringAsFixed(0)}%',
                          size: 24,
                          weight: FontWeight.w700,
                          color: confidenceColor,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          text: 'Confidence',
                          size: 10,
                          weight: FontWeight.w400,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
