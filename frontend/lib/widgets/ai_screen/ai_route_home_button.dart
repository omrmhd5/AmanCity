import 'package:easy_localization/easy_localization.dart';
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

class AiRouteHomeButton extends StatefulWidget {
  final SafeRouteHomeData data;

  const AiRouteHomeButton({Key? key, required this.data}) : super(key: key);

  @override
  State<AiRouteHomeButton> createState() => _AiRouteHomeButtonState();
}

class _AiRouteHomeButtonState extends State<AiRouteHomeButton> {
  bool _pressed = false;

  Future<void> _openGoogleMaps() async {
    try {
      if (await canLaunchUrl(Uri.parse(widget.data.googleMapsUrl))) {
        await launchUrl(
          Uri.parse(widget.data.googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dangerLevelInfo = SafeRouteScorer.getDangerLevelInfo(
      widget.data.dangerScore,
    );
    final dangerColor = dangerLevelInfo['color'] as Color;
    final dangerIcon = dangerLevelInfo['icon'] as String;
    final dangerLabel = dangerLevelInfo['label'] as String;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        border: Border.all(color: dangerColor.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
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
                    if (widget.data.distance != null)
                      Text(
                        widget.data.distance!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                    if (widget.data.duration != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.data.duration!,
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
                  widget.data.homeAddress,
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
          // Navigate Button with press feedback
          AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: _pressed
                ? const Duration(milliseconds: 80)
                : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: GestureDetector(
              onTap: _openGoogleMaps,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _pressed
                      ? AppColors.secondary.withOpacity(0.85)
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ai.navigate_home_safely'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
