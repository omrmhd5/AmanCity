import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/map_incident.dart';
import '../custom_text.dart';

class LocationSection extends StatelessWidget {
  final MapIncident incident;

  const LocationSection({Key? key, required this.incident}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Preview
          Container(
            height: 240,
            color: AppTheme.getBackgroundColor(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAYlsWPun-Cu_C3AzuVJPP0Vpo12EaHRCfaWOWBOJ81Qll30bOP2iXiBYGDGoeF51pqPuYS9d1yyRHOkEbnpQW4gAIc3mIVKfikgtxcxkeE9wqkeKI6QaeN_bS-xn9b_gRInJsbDExKi46g_wIMXAX5g_Nfp7bpdJoOsHR6jl70tOp4VW_Kn4Ph5GfWxh1IiW-qsbkJm4c5x9nYzWz8mj9Nb7U3Rsm-N-MWT5Ni3QPGc58Oj38RPTVuZBLLs6CrywdeSE-8YEaWyX0X',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  color: AppTheme.getBackgroundColor().withOpacity(0.2),
                ),
                // Map pin with glow
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: incident.severityColor,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: incident.severityColor.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Coordinates badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getBackgroundColor().withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.getBorderColor(),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(
                          text: 'Coordinates',
                          size: 9,
                          weight: FontWeight.w500,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          text:
                              '${incident.position.latitude.toStringAsFixed(4)}°, ${incident.position.longitude.toStringAsFixed(4)}°',
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Location Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'LOCATION',
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: incident.severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 20,
                        color: incident.severityColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: 'Maadi Sector, Cairo',
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            text: incident.type.name.toUpperCase(),
                            size: 11,
                            weight: FontWeight.w400,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
