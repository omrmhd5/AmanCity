import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../models/emergency_poi.dart';
import '../custom_text.dart';

class POIDetailSheet extends StatelessWidget {
  final EmergencyPOI poi;

  const POIDetailSheet({Key? key, required this.poi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Location Details',
                      size: 16,
                      weight: FontWeight.w800,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppTheme.getSecondaryTextColor(),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0.5),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Card with icon
                Container(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      poi.markerColor.withOpacity(0.04),
                      AppTheme.getCardBackgroundColor(),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: poi.markerColor.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: poi.markerColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(poi.icon, color: poi.markerColor, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: poi.name,
                              size: 16,
                              weight: FontWeight.w700,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: poi.markerColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: poi.markerColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: CustomText(
                                    text: poi.typeLabel,
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: poi.markerColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Address Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getCardBackgroundColor(),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.getBorderColor(),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: poi.markerColor,
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            text: 'Address',
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomText(
                        text: poi.address,
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppTheme.getSecondaryTextColor(),
                        height: 1.6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Info Cards (Phone + Contact)
                if (poi.phoneNumber != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getCardBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getBorderColor(),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 18, color: poi.markerColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: 'Phone',
                                size: 11,
                                weight: FontWeight.w600,
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                              const SizedBox(height: 4),
                              CustomText(
                                text: poi.phoneNumber!,
                                size: 12,
                                weight: FontWeight.w600,
                                color: poi.markerColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ), // Navigate Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () async {
                final lat = poi.position.latitude;
                final lng = poi.position.longitude;
                final String googleMapsUrl =
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                  await launchUrl(
                    Uri.parse(googleMapsUrl),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: poi.markerColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: poi.markerColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const CustomText(
                      text: 'Navigate To Location',
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
