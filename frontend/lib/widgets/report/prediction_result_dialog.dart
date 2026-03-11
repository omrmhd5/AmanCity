import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/prediction_result_model.dart';
import '../custom_text.dart';

/// Dialog widget that displays YOLO prediction results
/// Shows the detected incident class, confidence score, and action buttons
class PredictionResultDialog extends StatelessWidget {
  final PredictionResult prediction;
  final VoidCallback? onCreateIncident;
  final VoidCallback? onDismiss;

  const PredictionResultDialog({
    Key? key,
    required this.prediction,
    this.onCreateIncident,
    this.onDismiss,
  }) : super(key: key);

  /// Get color based on prediction confidence
  Color _getConfidenceColor() {
    if (prediction.confidence >= 0.8) {
      return Colors.green;
    } else if (prediction.confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Get confidence level text
  String _getConfidenceLevelText() {
    if (prediction.confidence >= 0.8) {
      return 'High Confidence';
    } else if (prediction.confidence >= 0.6) {
      return 'Medium Confidence';
    } else {
      return 'Low Confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getConfidenceColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.currentMode == AppThemeMode.dark
              ? AppColors.primary
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Check Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 48, color: confidenceColor),
            ),
            const SizedBox(height: 24),

            // Title
            CustomText(
              text: 'Prediction Result',
              size: 20,
              weight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
            const SizedBox(height: 16),

            // Detected Class
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.currentMode == AppThemeMode.dark
                    ? AppColors.secondary.withOpacity(0.15)
                    : AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary, width: 1.5),
              ),
              child: Column(
                children: [
                  CustomText(
                    text: 'Detected Type',
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    text: prediction.className,
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confidence Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: confidenceColor, width: 1.5),
              ),
              child: Column(
                children: [
                  CustomText(
                    text: _getConfidenceLevelText(),
                    size: 12,
                    weight: FontWeight.w500,
                    color: confidenceColor,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    text:
                        '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                    size: 22,
                    weight: FontWeight.w700,
                    color: confidenceColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confidence Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Confidence Score',
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.currentMode == AppThemeMode.dark
                            ? AppColors.softGray.withOpacity(0.2)
                            : AppColors.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width:
                          MediaQuery.of(context).size.width *
                          0.5 *
                          prediction.confidence,
                      decoration: BoxDecoration(
                        color: confidenceColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                // Dismiss Button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onDismiss?.call();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.getBorderColor(),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CustomText(
                            text: 'Cancel',
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Create Incident Button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onCreateIncident?.call();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CustomText(
                            text: 'Create',
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
