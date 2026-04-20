import 'package:flutter/material.dart';
import '../../models/hotspot_zone.dart';
import '../../utils/app_theme.dart';
import '../shared/custom_text.dart';
import 'hotspot_detail_row.dart';

class HotspotDetailSheet extends StatelessWidget {
  final HotspotZone hotspot;

  const HotspotDetailSheet({Key? key, required this.hotspot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with risk indicator
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: hotspot.riskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'Predicted Risk Zone',
                          size: 12,
                          color: AppTheme.getSecondaryTextColor(),
                          weight: FontWeight.w500,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text: hotspot.riskLevel,
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ],
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
              const SizedBox(height: 24),

              // Risk score progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Risk Score',
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: hotspot.riskScore,
                      minHeight: 8,
                      backgroundColor: AppTheme.getCardBackgroundColor(),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hotspot.riskColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    text: '${(hotspot.riskScore * 100).toStringAsFixed(0)}%',
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    HotspotDetailRow(
                      label: 'Incidents in Zone',
                      value: '${hotspot.incidentCount}',
                    ),
                    const SizedBox(height: 12),
                    HotspotDetailRow(
                      label: 'Zone Radius',
                      value: '${hotspot.radiusKm.toStringAsFixed(2)} km',
                    ),
                    const SizedBox(height: 12),
                    HotspotDetailRow(
                      label: 'Avg Confidence',
                      value:
                          '${(hotspot.avgConfidence * 100).toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 12),
                    HotspotDetailRow(
                      label: 'Last Updated',
                      value: hotspot.timeSinceUpdate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Warning text
              Container(
                decoration: BoxDecoration(
                  color: hotspot.riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hotspot.riskColor.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: hotspot.riskColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        text: hotspot.smartWarningMessage,
                        size: 12,
                        color: AppTheme.getPrimaryTextColor(),
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
