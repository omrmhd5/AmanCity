import 'dart:ui';
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

class _POIDetailSheetState extends State<POIDetailSheet> {
  bool _navigatePressed = false;

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
              const SizedBox(height: 10),
              // Header row
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
                          text: 'Location Details',
                          size: 16,
                          weight: FontWeight.w800,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ],
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
              ),
              // Teal gradient divider
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
              // Content
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
                                      color: poi.markerColor.withOpacity(0.15),
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
                                text: 'Address',
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
                          color: AppTheme.getBackgroundColor().withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.getBorderColor().withOpacity(0.15),
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
                                    text: 'Phone',
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
                    GestureDetector(
                      onTapDown: (_) => setState(() => _navigatePressed = true),
                      onTapUp: (_) async {
                        setState(() => _navigatePressed = false);
                        if (widget.onNavigate != null) {
                          await widget.onNavigate!(poi);
                          if (context.mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        } else {
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
