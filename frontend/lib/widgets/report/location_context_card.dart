import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class LocationContextCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isLoading;

  const LocationContextCard({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.isLoading = false,
  }) : super(key: key);

  String _getLocationName() {
    // Simple mock location name based on coordinates
    // In a real app, this would use reverse geocoding
    if (latitude > 29.9 &&
        latitude < 30.1 &&
        longitude > 31.1 &&
        longitude < 31.4) {
      return 'Near Street 9, Maadi, Cairo';
    }
    return 'Current Location, Cairo';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.currentMode == AppThemeMode.dark
            ? AppColors.primary
            : AppColors.white,
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Location icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.my_location,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Location info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getSecondaryTextColor(),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getLocationName(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} PM • Auto-detected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Mini map preview
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.neutral800
                  : AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Map background (gradient to simulate map)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.currentMode == AppThemeMode.dark
                            ? const Color(0xFF2A3F5F)
                            : const Color(0xFFE0E7FF),
                        AppTheme.currentMode == AppThemeMode.dark
                            ? const Color(0xFF1A2F4F)
                            : const Color(0xFFDDD6FE),
                      ],
                    ),
                  ),
                ),
                // Location pulse
                ScaleTransition(
                  scale: AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
