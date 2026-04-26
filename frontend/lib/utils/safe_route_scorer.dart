import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/hotspot_zone.dart';
import 'dart:math' as math;

/// Utility to score routes based on danger zone overlap
/// Lower score = safer route
class SafeRouteScorer {
  /// Calculate Haversine distance between two coordinates in meters
  static double _haversineDistance(LatLng point1, LatLng point2) {
    const earthRadiusM = 6371000; // Earth radius in meters
    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  /// Score a route (0.0 = safe, 1.0 = maximum danger)
  /// Considers overlap with hotspot zones weighted by risk score
  static double scoreRoute(
    List<LatLng> polylinePoints,
    List<HotspotZone> hotspots,
  ) {
    if (polylinePoints.isEmpty || hotspots.isEmpty) {
      return 0.0;
    }

    double totalDanger = 0.0;
    int pointsInDanger = 0;

    // For each point on the route, check if it's in any hotspot
    for (final point in polylinePoints) {
      double maxDangerAtPoint = 0.0;

      // Check against each hotspot zone
      for (final hotspot in hotspots) {
        final distanceToCenter = _haversineDistance(point, hotspot.center);

        // If point is within the hotspot radius, calculate danger contribution
        if (distanceToCenter <= hotspot.radiusMeters) {
          // Danger increases closer to the center
          // Formula: riskScore * (1 - (distance / radius))
          // At center: riskScore * 1.0
          // At edge: riskScore * 0.0
          final dangerAtPoint =
              hotspot.riskScore *
              (1.0 - (distanceToCenter / hotspot.radiusMeters));
          maxDangerAtPoint = math.max(maxDangerAtPoint, dangerAtPoint);
        }
      }

      if (maxDangerAtPoint > 0.0) {
        totalDanger += maxDangerAtPoint;
        pointsInDanger++;
      }
    }

    // Average danger score: total danger / total points
    // This normalizes to 0.0-1.0 range
    if (pointsInDanger == 0) {
      return 0.0; // Route avoids all hotspots
    }

    final averageDanger = totalDanger / polylinePoints.length;
    return math.min(averageDanger, 1.0); // Clamp to max 1.0
  }

  /// Pick the safest route from multiple alternatives
  /// Returns: {index, dangerScore} where index is the safest route
  static Map<String, dynamic> pickSafestRoute(
    List<List<LatLng>> decodedRoutes,
    List<HotspotZone> hotspots,
  ) {
    if (decodedRoutes.isEmpty) {
      return {'index': 0, 'dangerScore': 0.0};
    }

    double minDangerScore = double.infinity;
    int safestIndex = 0;

    for (int i = 0; i < decodedRoutes.length; i++) {
      final score = scoreRoute(decodedRoutes[i], hotspots);
      if (score < minDangerScore) {
        minDangerScore = score;
        safestIndex = i;
      }
    }

    return {
      'index': safestIndex,
      'dangerScore': minDangerScore == double.infinity ? 0.0 : minDangerScore,
    };
  }

  /// Get danger level label and color for UI display
  static Map<String, dynamic> getDangerLevelInfo(double dangerScore) {
    if (dangerScore < 0.2) {
      return {
        'label': 'Safe Route',
        'icon': '🟢',
        'color': Color(0xFF22C55E), // green
      };
    } else if (dangerScore < 0.3) {
      return {
        'label': 'Moderate Risk',
        'icon': '🟡',
        'color': Color(0xFFD97706), // orange
      };
    } else {
      return {
        'label': 'High Danger',
        'icon': '🔴',
        'color': Color(0xFFDC2626), // red
      };
    }
  }
}
