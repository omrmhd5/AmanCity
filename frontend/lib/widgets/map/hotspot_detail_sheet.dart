import 'package:flutter/material.dart';
import '../../models/hotspot_zone.dart';
import 'hotspot_detail_row.dart';

class HotspotDetailSheet extends StatelessWidget {
  final HotspotZone hotspot;

  const HotspotDetailSheet({Key? key, required this.hotspot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                        Text(
                          'Predicted Risk Zone',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hotspot.riskLevel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Risk score progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Score',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: hotspot.riskScore,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hotspot.riskColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(hotspot.riskScore * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
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
                  border: Border.all(color: hotspot.riskColor),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: hotspot.riskColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This zone has high predicted risk based on recent incident patterns.',
                        style: Theme.of(context).textTheme.bodySmall,
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
