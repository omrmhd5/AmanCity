import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/map/hotspot_zone.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../shared/custom_text.dart';
import 'hotspot_detail_row.dart';

class HotspotDetailSheet extends StatelessWidget {
  final HotspotZone hotspot;

  const HotspotDetailSheet({Key? key, required this.hotspot}) : super(key: key);

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.getSecondaryTextColor(),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scorePercent = (hotspot.riskScore * 100).toStringAsFixed(0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorderColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.crisis_alert_rounded,
                        size: 17,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          text: 'Risk Zone Details',
                          size: 16,
                          weight: FontWeight.w800,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                      GestureDetector(
                        onTap: Navigator.of(context).pop,
                        child: Icon(
                          Icons.close,
                          color: AppTheme.getSecondaryTextColor(),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // Teal gradient divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.0),
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Risk level headline
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hotspot.riskColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hotspot.riskColor.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: hotspot.riskColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: hotspot.riskColor.withOpacity(0.15),
                                  width: 0.75,
                                ),
                              ),
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: hotspot.riskColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: 'Predicted Risk Zone',
                                    size: 11,
                                    color: AppTheme.getSecondaryTextColor(),
                                    weight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    text: hotspot.riskLevel,
                                    size: 20,
                                    weight: FontWeight.w900,
                                    color: hotspot.riskColor,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: hotspot.riskColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: hotspot.riskColor.withOpacity(0.15),
                                  width: 0.75,
                                ),
                              ),
                              child: CustomText(
                                text: '$scorePercent%',
                                size: 16,
                                weight: FontWeight.w900,
                                color: hotspot.riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Risk Score section
                      _sectionLabel(Icons.speed_rounded, 'Risk Score'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.getBackgroundColor().withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.getBorderColor().withOpacity(0.15),
                            width: 0.75,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  text: 'Score Level',
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                                CustomText(
                                  text: '$scorePercent / 100',
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: hotspot.riskColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: hotspot.riskScore,
                                minHeight: 10,
                                backgroundColor: AppTheme.getBorderColor()
                                    .withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  hotspot.riskColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Zone Info section
                      _sectionLabel(Icons.info_outline_rounded, 'Zone Info'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.getBackgroundColor().withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.getBorderColor().withOpacity(0.15),
                            width: 0.75,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            HotspotDetailRow(
                              label: 'Incidents in Zone',
                              value: '${hotspot.incidentCount}',
                            ),
                            const SizedBox(height: 4),
                            Divider(
                              height: 16,
                              color: AppTheme.getBorderColor().withOpacity(0.3),
                            ),
                            HotspotDetailRow(
                              label: 'Zone Radius',
                              value:
                                  '${hotspot.radiusKm.toStringAsFixed(2)} km',
                            ),
                            const SizedBox(height: 4),
                            Divider(
                              height: 16,
                              color: AppTheme.getBorderColor().withOpacity(0.3),
                            ),
                            HotspotDetailRow(
                              label: 'Avg Confidence',
                              value:
                                  '${(hotspot.avgConfidence * 100).toStringAsFixed(0)}%',
                            ),
                            const SizedBox(height: 4),
                            Divider(
                              height: 16,
                              color: AppTheme.getBorderColor().withOpacity(0.3),
                            ),
                            HotspotDetailRow(
                              label: 'Last Updated',
                              value: hotspot.timeSinceUpdate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Advisory section
                      _sectionLabel(Icons.warning_amber_rounded, 'Advisory'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: hotspot.riskColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hotspot.riskColor.withOpacity(0.2),
                            width: 0.75,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: hotspot.riskColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomText(
                                text: hotspot.smartWarningMessage,
                                size: 12,
                                color: AppTheme.getPrimaryTextColor(),
                                weight: FontWeight.w500,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
