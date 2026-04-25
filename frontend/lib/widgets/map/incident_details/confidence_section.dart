import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../models/map_incident.dart';
import '../../shared/custom_text.dart';

class ConfidenceSection extends StatelessWidget {
  final MapIncident? incident;

  const ConfidenceSection({Key? key, this.incident}) : super(key: key);

  /// Get color based on confidence level
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.75) {
      return const Color(0xFFFF5252);
    } else if (confidence >= 0.65) {
      return const Color(0xFFFFA500);
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  /// Get confidence level text
  String _getConfidenceLevelText(double confidence) {
    if (confidence >= 0.75) {
      return 'High Confidence';
    } else if (confidence >= 0.65) {
      return 'Medium Confidence';
    } else {
      return 'Low Confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = incident?.confidence ?? 0.0;

    // Only show if confidence is > 0 (has a value)
    if (confidence <= 0) {
      return const SizedBox.shrink();
    }

    final confidenceColor = _getConfidenceColor(confidence);
    final confidenceLevelText = _getConfidenceLevelText(confidence);
    final confidencePercentage = (confidence * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'AI CONFIDENCE',
                size: 11,
                weight: FontWeight.w700,
                color: AppTheme.getSecondaryTextColor(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: confidenceColor, width: 1),
                ),
                child: CustomText(
                  text: confidenceLevelText,
                  size: 10,
                  weight: FontWeight.w600,
                  color: confidenceColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Confidence Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.secondary.withOpacity(0.08)
                : AppColors.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          ),
          child: Column(
            children: [
              // Percentage Display
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
                    text: '$confidencePercentage%',
                    size: 16,
                    weight: FontWeight.w700,
                    color: confidenceColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: confidence,
                  minHeight: 8,
                  backgroundColor: confidenceColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                ),
              ),
              const SizedBox(height: 12),

              // Confidence Level Info
              Row(
                children: [
                  Icon(
                    confidence >= 0.75
                        ? Icons.check_circle
                        : confidence >= 0.65
                        ? Icons.info
                        : Icons.warning_rounded,
                    size: 16,
                    color: confidenceColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      text: confidence >= 0.75
                          ? 'High AI confidence in detection'
                          : confidence >= 0.65
                          ? 'Moderate AI confidence in detection'
                          : 'Low AI confidence - verify manually',
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
    );
  }
}
