import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../shared/custom_text.dart';

class NearbyBulkAlertCard extends StatefulWidget {
  final String incidentType;
  final int count;
  final String timeAgo;
  final String distance;
  final Color borderColor;
  final IconData icon;
  final double avgConfidence;
  final String? locationText;
  final bool hasHumanReports;
  final bool hasOsintReports;
  final VoidCallback? onTap;

  const NearbyBulkAlertCard({
    Key? key,
    required this.incidentType,
    required this.count,
    required this.timeAgo,
    required this.distance,
    required this.borderColor,
    required this.icon,
    this.avgConfidence = 0.0,
    this.locationText,
    this.hasHumanReports = false,
    this.hasOsintReports = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<NearbyBulkAlertCard> createState() => _NearbyBulkAlertCardState();
}

class _NearbyBulkAlertCardState extends State<NearbyBulkAlertCard> {
  bool _isPressed = false;

  Color _getConfidenceColor() {
    if (widget.avgConfidence >= 0.75) return AppColors.danger;
    if (widget.avgConfidence >= 0.65) return AppColors.warning;
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
                // Top row: Type badge + Count badge
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
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.borderColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomText(
                        text: '×${widget.count}',
                        size: 10,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                CustomText(
                  text: 'map.grouped_incidents'.tr(namedArgs: {'count': '${widget.count}'}),
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                  maxLines: 1,
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

                const SizedBox(height: 10),

                // Source chips (Human/OSINT)
                Wrap(
                  spacing: 6,
                  children: [
                    if (widget.hasHumanReports)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 11,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 3),
                            CustomText(
                              text: 'authority.human'.tr(),
                              size: 10,
                              weight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    if (widget.hasOsintReports)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.radar,
                              size: 11,
                              color: Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 3),
                            CustomText(
                              text: 'authority.osint'.tr(),
                              size: 10,
                              weight: FontWeight.w600,
                              color: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Confidence bar
                if (widget.avgConfidence > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'map.avg_confidence'.tr(),
                        size: 10,
                        weight: FontWeight.w500,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      CustomText(
                        text:
                            '${(widget.avgConfidence * 100).toStringAsFixed(0)}%',
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
                      value: widget.avgConfidence,
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
