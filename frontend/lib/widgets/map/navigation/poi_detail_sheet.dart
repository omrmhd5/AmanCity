import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../models/map/emergency_poi.dart';
import '../../shared/custom_text.dart';

class POIDetailSheet extends StatefulWidget {
  final EmergencyPOI poi;
  final Future<void> Function(EmergencyPOI)? onNavigate;

  const POIDetailSheet({Key? key, required this.poi, this.onNavigate})
    : super(key: key);

  @override
  State<POIDetailSheet> createState() => _POIDetailSheetState();
}

class _POIDetailSheetState extends State<POIDetailSheet>
    with SingleTickerProviderStateMixin {
  bool _navigatePressed = false;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.getBorderColor(),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                start: 0.0,
                end: 0.4,
              ),
              const SizedBox(height: 10),
              // Header row
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          CustomText(
                            text: 'map.location_details'.tr(),
                            size: 16,
                            weight: FontWeight.w800,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                ),
                start: 0.05,
                end: 0.5,
              ),
              // Teal gradient divider
              _animated(
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.0),
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                start: 0.1,
                end: 0.5,
              ),
              // Content
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Card with icon
                      Container(
                        decoration: BoxDecoration(
                          color: poi.markerColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: poi.markerColor.withOpacity(0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: poi.markerColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: poi.markerColor.withOpacity(0.15),
                                  width: 0.75,
                                ),
                              ),
                              child: Icon(
                                poi.icon,
                                color: poi.markerColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: poi.name,
                                    size: 15,
                                    weight: FontWeight.w700,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: poi.markerColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: poi.markerColor.withOpacity(
                                          0.15,
                                        ),
                                        width: 0.75,
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Address Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.getBackgroundColor().withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.getBorderColor().withOpacity(0.15),
                            width: 0.75,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                CustomText(
                                  text: 'map.address'.tr(),
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: AppTheme.getPrimaryTextColor(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                      // Phone Card (if present)
                      if (poi.phoneNumber != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getBackgroundColor().withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.getBorderColor().withOpacity(
                                0.15,
                              ),
                              width: 0.75,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: poi.markerColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: poi.markerColor.withOpacity(0.15),
                                    width: 0.75,
                                  ),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  size: 17,
                                  color: poi.markerColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'map.phone'.tr(),
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                    const SizedBox(height: 3),
                                    CustomText(
                                      text: poi.phoneNumber!,
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: poi.markerColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Navigate Button
                      _animated(
                        GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _navigatePressed = true),
                          onTapUp: (_) async {
                            setState(() => _navigatePressed = false);
                            if (widget.onNavigate != null) {
                              await widget.onNavigate!(poi);
                              if (context.mounted &&
                                  Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            } else {
                              final lat = poi.position.latitude;
                              final lng = poi.position.longitude;
                              final String googleMapsUrl =
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                              if (await canLaunchUrl(
                                Uri.parse(googleMapsUrl),
                              )) {
                                await launchUrl(
                                  Uri.parse(googleMapsUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          onTapCancel: () =>
                              setState(() => _navigatePressed = false),
                          child: AnimatedScale(
                            scale: _navigatePressed ? 0.96 : 1.0,
                            duration: _navigatePressed
                                ? const Duration(milliseconds: 80)
                                : const Duration(milliseconds: 300),
                            curve: _navigatePressed
                                ? Curves.easeIn
                                : Curves.easeOutBack,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    poi.markerColor,
                                    poi.markerColor.withOpacity(0.72),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
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
                                  const Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  CustomText(
                                    text: 'map.navigate_to_location'.tr(),
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        start: 0.3,
                        end: 0.85,
                      ),
                    ],
                  ),
                ),
                start: 0.15,
                end: 0.8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
