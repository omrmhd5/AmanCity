import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/prediction/prediction_result_model.dart';
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
  bool _createPressed = false;
  bool _dismissPressed = false;

  @override
  void initState() {
    super.initState();
    _selectedPrediction = widget.prediction;
  }

  /// Get icon based on model type
  IconData _getModelIcon(String? model) {
    switch (model?.toLowerCase()) {
      case 'weapons':
        return Icons.gavel_rounded;
      case '7classes':
        return Icons.nature_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  /// Get label based on model type
  String _getModelLabel(String? model) {
    switch (model?.toLowerCase()) {
      case 'weapons':
        return 'report.type_weapon'.tr();
      case '7classes':
        return 'report.type_environmental'.tr();
      default:
        return 'report.type_crime'.tr();
    }
  }

  /// Get color based on prediction confidence
  Color _getConfidenceColor({
    required double confidence,
    bool isAlternative = false,
  }) {
    if (isAlternative) {
      // Use muted colors for alternative
      if (confidence >= 0.75) {
        return const Color(0xFF4CAF50);
      } else if (confidence >= 0.65) {
        return const Color(0xFFFF9800);
      } else {
        return const Color(0xFFF44336);
      }
    } else {
      // Bright colors for main prediction
      if (confidence >= 0.75) {
        return const Color(0xFF4CAF50);
      } else if (confidence >= 0.65) {
        return const Color(0xFFFFA500);
      } else {
        return const Color(0xFFFF5252);
      }
    }
  }

  /// Get confidence level text
  String _getConfidenceLevelText(double confidence) {
    if (confidence >= 0.75) {
      return 'map.high_confidence'.tr();
    } else if (confidence >= 0.65) {
      return 'map.medium_confidence'.tr();
    } else {
      return 'map.low_confidence'.tr();
    }
  }

  Widget _buildPredictionCard({
    required String title,
    required String className,
    required double confidence,
    required bool isSelected,
    required bool isAlternative,
    VoidCallback? onTap,
    IconData? titleIcon,
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
                        Row(
                          children: [
                            if (titleIcon != null)
                              Icon(
                                titleIcon,
                                size: 14,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            if (titleIcon != null) const SizedBox(width: 6),
                            Expanded(
                              child: CustomText(
                                text: title,
                                size: 12,
                                weight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            ),
                          ],
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

  /// Build dialog shown when AI-generated media is detected
  Widget _buildAiGeneratedDialog(BuildContext context) {
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
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              CustomText(
                text: 'report.ai_generated_title'.tr(),
                size: 20,
                weight: FontWeight.w700,
                color: AppTheme.getPrimaryTextColor(),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              CustomText(
                text: 'report.ai_generated_body'.tr(),
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
                        text: 'common.ok'.tr(),
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
                text: 'report.nothing_found'.tr(),
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
                        text: 'common.ok'.tr(),
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
    // Handle AI-generated media
    if (widget.prediction.isAiGenerated) {
      return _buildAiGeneratedDialog(context);
    }

    // Handle no incident response
    if (widget.prediction.noIncident) {
      return _buildNoIncidentDialog(context);
    }

    final confidenceColor = _getConfidenceColor(
      confidence: widget.prediction.confidence,
    );
    final isDual =
        widget.prediction.hasMultiplePredictions &&
        widget.prediction.alternatives != null &&
        widget.prediction.alternatives!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor().withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
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
                    text: isDual
                        ? 'report.multiple_predictions'.tr()
                        : 'report.prediction_result'.tr(),
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),

                  if (isDual)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: CustomText(
                        text:
                            'Multiple incidents detected.\nSelect which one to report:',
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
                    title: isDual
                        ? _getModelLabel(widget.prediction.model)
                        : 'report.detected_type'.tr(),
                    titleIcon: isDual
                        ? _getModelIcon(widget.prediction.model)
                        : null,
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

                  // Alternative Prediction Cards (if multiple - up to 3 total)
                  if (isDual && widget.prediction.alternatives != null)
                    ...widget.prediction.alternatives!.asMap().entries.map((
                      entry,
                    ) {
                      final alt = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildPredictionCard(
                          title: _getModelLabel(alt.model),
                          titleIcon: _getModelIcon(alt.model),
                          className: alt.className,
                          confidence: alt.confidence,
                          isSelected:
                              _selectedPrediction.className == alt.className,
                          isAlternative: true,
                          onTap: () => setState(() {
                            _selectedPrediction = alt;
                          }),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 16),

                  // "Inaccurate results?" hint
                  GestureDetector(
                    onTap: () {
                      final othersPrediction = PredictionResult(
                        classId: -1,
                        className: 'Others',
                        confidence: 0.0,
                      );
                      widget.onCreateIncident?.call(othersPrediction);
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'report.inaccurate_flag'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      // Dismiss Button
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _dismissPressed = true),
                          onTapUp: (_) {
                            setState(() => _dismissPressed = false);
                            widget.onDismiss?.call();
                            Navigator.of(context).pop();
                          },
                          onTapCancel: () =>
                              setState(() => _dismissPressed = false),
                          child: AnimatedScale(
                            scale: _dismissPressed ? 0.96 : 1.0,
                            duration: _dismissPressed
                                ? const Duration(milliseconds: 80)
                                : const Duration(milliseconds: 300),
                            curve: _dismissPressed
                                ? Curves.easeIn
                                : Curves.easeOutBack,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: AppTheme.getBackgroundColor()
                                    .withOpacity(0.5),
                                border: Border.all(
                                  color: AppTheme.getBorderColor().withOpacity(
                                    0.25,
                                  ),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Create Incident Button
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _createPressed = true),
                          onTapUp: (_) {
                            setState(() => _createPressed = false);
                            widget.onCreateIncident?.call(_selectedPrediction);
                            Navigator.of(context).pop();
                          },
                          onTapCancel: () =>
                              setState(() => _createPressed = false),
                          child: AnimatedScale(
                            scale: _createPressed ? 0.96 : 1.0,
                            duration: _createPressed
                                ? const Duration(milliseconds: 80)
                                : const Duration(milliseconds: 300),
                            curve: _createPressed
                                ? Curves.easeIn
                                : Curves.easeOutBack,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondary,
                                    AppColors.secondary.withOpacity(0.72),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'common.create'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
        ),
      ),
    );
  }
}
