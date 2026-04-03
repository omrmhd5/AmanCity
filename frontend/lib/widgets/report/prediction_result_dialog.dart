import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/prediction_result_model.dart';
import '../shared/custom_text.dart';

/// Dialog widget that displays YOLO prediction results
/// Shows the detected incident class, confidence score, and action buttons
/// Supports dual predictions (weapon + alternative) where user chooses
class PredictionResultDialog extends StatefulWidget {
  final PredictionResult prediction;
  final Function(PredictionResult)?
  onCreateIncident; // Callback with prediction data
  final VoidCallback? onDismiss;

  const PredictionResultDialog({
    Key? key,
    required this.prediction,
    this.onCreateIncident,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<PredictionResultDialog> createState() => _PredictionResultDialogState();
}

class _PredictionResultDialogState extends State<PredictionResultDialog> {
  late PredictionResult _selectedPrediction;

  @override
  void initState() {
    super.initState();
    _selectedPrediction = widget.prediction;
  }

  /// Get color based on prediction confidence
  Color _getConfidenceColor({
    required double confidence,
    bool isAlternative = false,
  }) {
    if (isAlternative) {
      // Use muted colors for alternative
      if (confidence >= 0.8) {
        return Colors.green.withOpacity(0.6);
      } else if (confidence >= 0.6) {
        return Colors.orange.withOpacity(0.6);
      } else {
        return Colors.red.withOpacity(0.6);
      }
    } else {
      // Bright colors for main prediction
      if (confidence >= 0.8) {
        return Colors.green;
      } else if (confidence >= 0.6) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
  }

  /// Get confidence level text
  String _getConfidenceLevelText(double confidence) {
    if (confidence >= 0.8) {
      return 'High Confidence';
    } else if (confidence >= 0.6) {
      return 'Medium Confidence';
    } else {
      return 'Low Confidence';
    }
  }

  Widget _buildPredictionCard({
    required String title,
    required String className,
    required double confidence,
    required bool isSelected,
    required bool isAlternative,
    VoidCallback? onTap,
  }) {
    final confidenceColor = _getConfidenceColor(
      confidence: confidence,
      isAlternative: isAlternative,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? confidenceColor.withOpacity(0.15)
                : AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.secondary.withOpacity(0.08)
                : AppColors.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? confidenceColor : AppTheme.getBorderColor(),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: title,
                          size: 12,
                          weight: FontWeight.w500,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          text: className,
                          size: 16,
                          weight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        text: _getConfidenceLevelText(confidence),
                        size: 11,
                        weight: FontWeight.w500,
                        color: confidenceColor,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        text: '${(confidence * 100).toStringAsFixed(1)}%',
                        size: 16,
                        weight: FontWeight.w700,
                        color: confidenceColor,
                      ),
                    ],
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.check_circle,
                        color: confidenceColor,
                        size: 24,
                      ),
                    ),
                ],
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      minHeight: 6,
                      backgroundColor: confidenceColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        confidenceColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build dialog for no incident (Normal classification)
  Widget _buildNoIncidentDialog(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 24),

              // Title
              CustomText(
                text: 'Nothing Found',
                size: 20,
                weight: FontWeight.w700,
                color: AppTheme.getPrimaryTextColor(),
              ),

              const SizedBox(height: 12),

              // Message
              CustomText(
                text:
                    widget.prediction.noIncidentReason ??
                    'This image is classified as Normal - no incident detected.\n\nPlease upload another photo.',
                size: 14,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Dismiss Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onDismiss?.call();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'OK',
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle no incident response
    if (widget.prediction.noIncident) {
      return _buildNoIncidentDialog(context);
    }

    final confidenceColor = _getConfidenceColor(
      confidence: widget.prediction.confidence,
    );
    final isDual =
        widget.prediction.isDualPrediction &&
        widget.prediction.alternativeResult != null;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Check Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDual
                      ? Colors.amber.withOpacity(0.2)
                      : confidenceColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDual ? Icons.info_outline : Icons.check_circle,
                  size: 48,
                  color: isDual ? Colors.amber : confidenceColor,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              CustomText(
                text: isDual ? 'Multiple Predictions' : 'Prediction Result',
                size: 20,
                weight: FontWeight.w700,
                color: AppTheme.getPrimaryTextColor(),
              ),

              if (isDual)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CustomText(
                    text:
                        'Both weapon and incident detected.\nPlease choose the correct classification:',
                    size: 13,
                    weight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const SizedBox(height: 16),

              const SizedBox(height: 24),

              // Primary Prediction Card
              _buildPredictionCard(
                title: isDual ? '⚠️ Primary Detection' : 'Detected Type',
                className: widget.prediction.className,
                confidence: widget.prediction.confidence,
                isSelected:
                    _selectedPrediction.className ==
                    widget.prediction.className,
                isAlternative: false,
                onTap: isDual
                    ? () => setState(() {
                        _selectedPrediction = widget.prediction;
                      })
                    : null,
              ),

              // Alternative Prediction Card (if dual)
              if (isDual) ...[
                const SizedBox(height: 16),
                _buildPredictionCard(
                  title: '📋 Alternative Detection',
                  className: widget.prediction.alternativeResult!.className,
                  confidence: widget.prediction.alternativeResult!.confidence,
                  isSelected:
                      _selectedPrediction.className ==
                      widget.prediction.alternativeResult!.className,
                  isAlternative: true,
                  onTap: () => setState(() {
                    _selectedPrediction = widget.prediction.alternativeResult!;
                  }),
                ),
              ],

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
                          widget.onDismiss?.call();
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
                          widget.onCreateIncident?.call(_selectedPrediction);
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
      ),
    );
  }
}
