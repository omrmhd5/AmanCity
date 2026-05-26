import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class LocationContextCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool isLoading;
  final String? addressText;
  final String? city;

  const LocationContextCard({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.isLoading = false,
    this.addressText,
    this.city,
  }) : super(key: key);

  @override
  State<LocationContextCard> createState() => _LocationContextCardState();
}

class _LocationContextCardState extends State<LocationContextCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getLocationName() {
    if (widget.addressText != null && widget.addressText!.isNotEmpty) {
      return widget.addressText!;
    }
    if (widget.city != null && widget.city!.isNotEmpty) {
      return widget.city!;
    }
    return 'Current Location';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        border: Border.all(color: AppTheme.getBorderColor(), width: 0.75),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Location icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.2),
                width: 0.75,
              ),
            ),
            child: Icon(
              Icons.my_location_rounded,
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 1.0,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Auto-detected',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Mini map preview with animated pulse
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.currentMode == AppThemeMode.dark
                    ? [const Color(0xFF1E3A5F), const Color(0xFF162B47)]
                    : [const Color(0xFFD6E4FF), const Color(0xFFCDD6F4)],
              ),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.2),
                width: 0.75,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Inner dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
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
