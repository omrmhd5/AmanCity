import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class RouteInfoCard extends StatelessWidget {
  final String? destinationName;
  final String? distance;
  final String? duration;
  final bool isLoading;
  final Color? routeColor;
  final VoidCallback onNavigate;
  final VoidCallback onClose;
  final String? incidentType;
  final String? locationText;
  final bool isIncident;

  const RouteInfoCard({
    Key? key,
    required this.destinationName,
    required this.distance,
    required this.duration,
    required this.isLoading,
    this.routeColor,
    required this.onNavigate,
    required this.onClose,
    this.incidentType,
    this.locationText,
    this.isIncident = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.currentMode == AppThemeMode.dark
              ? AppColors.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: routeColor ?? AppColors.secondary,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route destination name or incident title
            Row(
              children: [
                Icon(
                  Icons.pin_drop,
                  color: routeColor ?? AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destinationName ?? 'Destination',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (incidentType != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (routeColor ?? AppColors.secondary)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (routeColor ?? AppColors.secondary)
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isIncident
                                ? '$incidentType Incident'
                                : incidentType!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: routeColor ?? AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                      if (locationText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          locationText!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Distance and duration
            Row(
              children: [
                Icon(
                  Icons.straight,
                  color: AppTheme.getSecondaryTextColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  distance ?? 'Calculating...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.timer,
                  color: AppTheme.getSecondaryTextColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  duration ?? 'Calculating...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Navigation button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onNavigate,
                icon: const Icon(Icons.navigation, size: 18),
                label: Text(
                  isLoading ? 'Loading route...' : 'Navigate in Google Maps',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: routeColor ?? AppColors.secondary,
                  disabledBackgroundColor: (routeColor ?? AppColors.secondary)
                      .withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
