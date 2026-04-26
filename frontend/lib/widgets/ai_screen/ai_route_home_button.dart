import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/safe_route_scorer.dart';

class SafeRouteHomeData {
  final String googleMapsUrl;
  final double dangerScore;
  final String? distance;
  final String? duration;
  final String homeAddress;

  SafeRouteHomeData({
    required this.googleMapsUrl,
    required this.dangerScore,
    this.distance,
    this.duration,
    required this.homeAddress,
  });
}

class AiRouteHomeButton extends StatelessWidget {
  final SafeRouteHomeData data;

  const AiRouteHomeButton({Key? key, required this.data}) : super(key: key);

  void _openGoogleMaps() async {
    try {
      if (await canLaunchUrl(Uri.parse(data.googleMapsUrl))) {
        await launchUrl(
          Uri.parse(data.googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dangerLevelInfo = SafeRouteScorer.getDangerLevelInfo(
      data.dangerScore,
    );
    final dangerColor = dangerLevelInfo['color'] as Color;
    final dangerIcon = dangerLevelInfo['icon'] as String;
    final dangerLabel = dangerLevelInfo['label'] as String;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        border: Border.all(color: dangerColor.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Danger Badge + Distance + Duration
          Row(
            children: [
              // Danger Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dangerColor.withOpacity(0.1),
                  border: Border.all(color: dangerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(dangerIcon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      dangerLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dangerColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Distance + Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.distance != null)
                      Text(
                        data.distance!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                    if (data.duration != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.duration!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Home Address
          Row(
            children: [
              Icon(Icons.home, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.homeAddress,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Navigate Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _openGoogleMaps,
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text('Navigate Home Safely'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
