import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../shared/custom_text.dart';

class NearbyAlertCard extends StatefulWidget {
  final String incidentType;
  final String title;
  final String timeAgo;
  final String distance;
  final Color borderColor;
  final IconData icon;
  final double confidence;
  final String? locationText;
  final VoidCallback? onTap;

  const NearbyAlertCard({
    Key? key,
    required this.incidentType,
    required this.title,
    required this.timeAgo,
    required this.distance,
    required this.borderColor,
    required this.icon,
    this.confidence = 0.0,
    this.locationText,
    this.onTap,
  }) : super(key: key);

  @override
  State<NearbyAlertCard> createState() => _NearbyAlertCardState();
}

class _NearbyAlertCardState extends State<NearbyAlertCard> {
  bool _isPressed = false;

  Color _getConfidenceColor() {
    if (widget.confidence >= 0.75) return AppColors.danger;
    if (widget.confidence >= 0.65) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getConfidenceColor();

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              widget.borderColor.withOpacity(0.04),
              AppTheme.getCardBackgroundColor(),
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: widget.borderColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Type badge + Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.borderColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.borderColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            size: 12,
                            color: widget.borderColor,
                          ),
                          const SizedBox(width: 4),
                          CustomText(
                            text: widget.incidentType,
                            size: 10,
                            weight: FontWeight.w600,
                            color: widget.borderColor,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    CustomText(
                      text: widget.timeAgo,
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppTheme.getSecondaryTextColor().withOpacity(0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                CustomText(
                  text: widget.title,
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Location text
                if (widget.locationText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          text: widget.locationText!,
                          size: 11,
                          weight: FontWeight.w400,
                          color: AppTheme.getSecondaryTextColor(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Confidence bar
                if (widget.confidence > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Confidence',
                        size: 10,
                        weight: FontWeight.w500,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      CustomText(
                        text:
                            '${(widget.confidence * 100).toStringAsFixed(0)}%',
                        size: 10,
                        weight: FontWeight.w600,
                        color: confidenceColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.confidence,
                      minHeight: 6,
                      backgroundColor: AppTheme.getBorderColor(),
                      valueColor: AlwaysStoppedAnimation(confidenceColor),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Footer: distance · timeAgo
                Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 12,
                      color: widget.borderColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.distance,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.borderColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getSecondaryTextColor().withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppTheme.getSecondaryTextColor().withOpacity(0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.getSecondaryTextColor().withOpacity(
                          0.7,
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
    );
  }
}
