import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;
import '../../../../utils/app_theme.dart';
import '../../../../utils/localization_formatter.dart';

class IncomingSosIdentity extends StatelessWidget {
  final Animation<double> animation;
  final String triggerUserName;
  final bool locationLoading;
  final String? locationText;
  final int? distanceMeters;
  final double resolvedLat;
  final double resolvedLng;

  const IncomingSosIdentity({
    Key? key,
    required this.animation,
    required this.triggerUserName,
    required this.locationLoading,
    this.locationText,
    this.distanceMeters,
    required this.resolvedLat,
    required this.resolvedLng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final offsetY = math.sin(animation.value * 2 * math.pi) * 4;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Column(
            children: [
              _buildNameRow(),
              const SizedBox(height: 8),
              _buildLocationLine(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameRow() {
    return Text(
      triggerUserName.isEmpty
          ? 'sos.unknown_contact'.tr()
          : triggerUserName,
      style: TextStyle(
        color: AppTheme.getPrimaryTextColor(),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLocationLine(BuildContext context) {
    if (locationLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
            const SizedBox(width: 8),
            Text(
              'sos.loading_location'.tr(),
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor().withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final hasLocation = locationText?.trim().isNotEmpty == true;
    final title = hasLocation ? locationText! : 'sos.coordinates'.tr();
    final distanceSuffix = distanceMeters != null
        ? ' (${'map.away_suffix'.tr(namedArgs: {
            'distance': LocalizationFormatter.formatDistance(context, '${distanceMeters}m'),
          })})'
        : '';
    final coordsText =
        '${resolvedLat.toStringAsFixed(5)}\n${resolvedLng.toStringAsFixed(5)}';
    final displayText = hasLocation
        ? '$title$distanceSuffix'
        : '$title$distanceSuffix\n$coordsText';
    final maxLines = hasLocation ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.place_rounded, color: Color(0xFFFF3B3B), size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor().withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
