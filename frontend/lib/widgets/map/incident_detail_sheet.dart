import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../models/map_incident.dart';
import '../custom_text.dart';

class IncidentDetailSheet extends StatelessWidget {
  final MapIncident incident;
  final String timeAgo;

  const IncidentDetailSheet({
    Key? key,
    required this.incident,
    required this.timeAgo,
  }) : super(key: key);

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
                      text: 'Incident Details',
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
          // Content - Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Card with icon
                  Container(
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        incident.severityColor.withOpacity(0.04),
                        AppTheme.getCardBackgroundColor(),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: incident.severityColor.withOpacity(0.15),
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
                            color: incident.severityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            incident.typeIcon,
                            color: incident.severityColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: incident.title,
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
                                      color: incident.severityColor.withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: incident.severityColor
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: CustomText(
                                      text: incident.typeLabel,
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: incident.severityColor,
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
                  // Description Card
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
                              Icons.description,
                              size: 16,
                              color: incident.severityColor,
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: 'Description',
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomText(
                          text: incident.description,
                          size: 12,
                          weight: FontWeight.w400,
                          color: AppTheme.getSecondaryTextColor(),
                          height: 1.6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info Cards (Location + Time)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getCardBackgroundColor(),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getBorderColor(),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: incident.severityColor,
                                  ),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    text: 'Location',
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                text:
                                    '${incident.position.latitude.toStringAsFixed(4)}',
                                size: 10,
                                weight: FontWeight.w400,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                              CustomText(
                                text:
                                    '${incident.position.longitude.toStringAsFixed(4)}',
                                size: 10,
                                weight: FontWeight.w400,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getCardBackgroundColor(),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getBorderColor(),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: incident.severityColor,
                                  ),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    text: 'Time',
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                text: timeAgo,
                                size: 11,
                                weight: FontWeight.w600,
                                color: incident.severityColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // View Details Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to detailed incident view or open web link
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('View Details coming soon'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondary, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      text: 'View Details',
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Navigate Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () async {
                final lat = incident.position.latitude;
                final lng = incident.position.longitude;
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
                  color: incident.severityColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: incident.severityColor.withOpacity(0.3),
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
