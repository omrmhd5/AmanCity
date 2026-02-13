import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/emergency_poi.dart';
import '../custom_text.dart';

class POIDetailSheet extends StatelessWidget {
  final EmergencyPOI poi;

  const POIDetailSheet({Key? key, required this.poi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: poi.markerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(poi.icon, color: poi.markerColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: poi.name,
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    CustomText(
                      text: poi.typeLabel,
                      size: 12,
                      weight: FontWeight.w400,
                      color: poi.markerColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Address
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                  text: poi.address,
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ],
          ),
          // Phone number (if available)
          if (poi.phoneNumber != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                const SizedBox(width: 6),
                CustomText(
                  text: poi.phoneNumber!,
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
