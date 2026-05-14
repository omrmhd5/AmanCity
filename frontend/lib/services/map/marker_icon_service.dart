import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/app_colors.dart';
import '../../models/incidents/map_incident.dart';
import '../../models/map/emergency_poi.dart';
import '../../models/map/hotspot_zone.dart';
import '../../models/incidents/bulk_incident.dart';

/// Handles creation and caching of all custom map marker icons.
/// Async canvas-rendering is done internally; [onIconReady] is invoked
/// after each icon is rendered so the caller can trigger a map refresh.
class MarkerIconService {
  final VoidCallback onIconReady;
  final Map<String, BitmapDescriptor> _cache = {};

  MarkerIconService({required this.onIconReady});

  // ─── Public getters ────────────────────────────────────────────────────────

  BitmapDescriptor getIncidentMarker(MapIncident incident) {
    final cacheKey = '${incident.type}_${incident.typeColor.value}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    _renderAndCache(
      cacheKey,
      incident.typeIcon,
      Colors.white,
      incident.typeColor,
      markerSize: 110.0,
    );
    return BitmapDescriptor.defaultMarkerWithHue(
      _hueFromColor(incident.typeColor),
    );
  }

  BitmapDescriptor getPOIMarker(EmergencyPOI poi) {
    final cacheKey = 'poi_${poi.type}_${poi.markerColor.value}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    _renderAndCache(
      cacheKey,
      poi.icon,
      Colors.white,
      poi.markerColor,
      markerSize: 80.0,
    );
    return BitmapDescriptor.defaultMarkerWithHue(
      _hueFromColor(poi.markerColor),
    );
  }

  BitmapDescriptor getBulkMarker(BulkIncident bulk) {
    final cacheKey = 'bulk_${bulk.type}_${bulk.count}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    _renderAndCacheBulk(cacheKey, bulk);
    return BitmapDescriptor.defaultMarkerWithHue(_hueFromColor(bulk.typeColor));
  }

  BitmapDescriptor getHotspotMarker(HotspotZone hotspot) {
    final cacheKey = 'hotspot_${hotspot.riskScore.toStringAsFixed(2)}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    _renderAndCache(
      cacheKey,
      Icons.warning_amber,
      Colors.white,
      hotspot.riskColor,
      markerSize: 90.0,
    );
    return BitmapDescriptor.defaultMarkerWithHue(
      _hueFromColor(hotspot.riskColor),
    );
  }

  BitmapDescriptor getUserLocationMarker() {
    const cacheKey = 'user_location';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    _renderAndCache(
      cacheKey,
      Icons.my_location,
      Colors.white,
      const Color(0xFF06B6D4),
    );
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
  }

  BitmapDescriptor getTappedDestinationMarker() {
    const cacheKey = 'tapped_destination';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    _renderAndCache(
      cacheKey,
      Icons.location_pin,
      Colors.white,
      AppColors.secondary,
      markerSize: 100.0,
    );
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
  }

  // ─── Private rendering ─────────────────────────────────────────────────────

  Future<void> _renderAndCache(
    String cacheKey,
    IconData iconData,
    Color iconColor,
    Color backgroundColor, {
    double markerSize = 120.0,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = markerSize;

      canvas.drawCircle(
        Offset(size / 2, size / 2 + 2),
        size / 2,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill,
      );

      final tp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            color: iconColor,
            fontSize: size * 0.45,
            fontFamily: iconData.fontFamily,
          ),
        )
        ..layout();
      tp.paint(
        canvas,
        Offset((size / 2) - (tp.width / 2), (size / 2) - (tp.height / 2)),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      _cache[cacheKey] = BitmapDescriptor.fromBytes(
        bytes!.buffer.asUint8List(),
      );
      onIconReady();
    } catch (_) {}
  }

  Future<void> _renderAndCacheBulk(String cacheKey, BulkIncident bulk) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 130.0;
      final color = bulk.typeColor;

      // Shadow
      canvas.drawCircle(
        const Offset(size / 2, size / 2 + 2),
        size / 2,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
      // Background
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Type icon
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(bulk.typeIcon.codePoint),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.48,
            fontFamily: bulk.typeIcon.fontFamily,
          ),
        )
        ..layout();
      iconPainter.paint(
        canvas,
        Offset(
          (size / 2) - (iconPainter.width / 2),
          (size / 2) - (iconPainter.height / 2),
        ),
      );

      // Count badge
      const badgeRadius = 30.0;
      const badgeCx = size - badgeRadius * 0.8;
      const badgeCy = size - badgeRadius * 0.8;
      canvas.drawCircle(
        const Offset(badgeCx, badgeCy),
        badgeRadius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        const Offset(badgeCx, badgeCy),
        badgeRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final badgePainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: '×${bulk.count}',
          style: TextStyle(
            color: color,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        )
        ..layout();
      badgePainter.paint(
        canvas,
        Offset(
          badgeCx - badgePainter.width / 2,
          badgeCy - badgePainter.height / 2,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      _cache[cacheKey] = BitmapDescriptor.fromBytes(
        bytes!.buffer.asUint8List(),
      );
      onIconReady();
    } catch (_) {}
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  double _hueFromColor(Color color) {
    if (color == AppColors.danger || color.value == Colors.red.value) {
      return BitmapDescriptor.hueRed;
    } else if (color.value == Colors.amber.value ||
        color.value == Colors.orange.value) {
      return BitmapDescriptor.hueOrange;
    } else if (color.value == Colors.green.value) {
      return BitmapDescriptor.hueGreen;
    } else if (color == AppColors.secondary) {
      return BitmapDescriptor.hueCyan;
    } else if (color.value == Colors.blue.value) {
      return BitmapDescriptor.hueBlue;
    }
    return BitmapDescriptor.hueRed;
  }
}
