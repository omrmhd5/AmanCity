import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map/hotspot_zone.dart';
import '../models/incidents/map_incident.dart';
import '../models/incidents/bulk_incident.dart';
import 'dart:math' as math;

/// Utility to score routes based on danger zone overlap
/// Lower score = safer route
class SafeRouteScorer {
  // Danger zone radii for individual data sources
  static const double _singleIncidentRadiusM = 200.0;
  static const double _bulkIncidentRadiusM = 500.0;

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
    List<HotspotZone> hotspots, {
    List<MapIncident> incidents = const [],
    List<BulkIncident> bulkIncidents = const [],
  }) {
    if (polylinePoints.isEmpty) {
      return 0.0;
    }

    double maxDangerOnRoute = 0.0;

    for (final point in polylinePoints) {
      double maxDangerAtPoint = 0.0;

      for (final hotspot in hotspots) {
        final distanceToCenter = _haversineDistance(point, hotspot.center);
        if (distanceToCenter <= hotspot.radiusMeters) {
          final dangerAtPoint =
              hotspot.riskScore *
              (1.0 - (distanceToCenter / hotspot.radiusMeters));
          maxDangerAtPoint = math.max(maxDangerAtPoint, dangerAtPoint);
        }
      }

      for (final incident in incidents) {
        if (incident.isMerged) continue;
        final dist = _haversineDistance(point, incident.position);
        if (dist <= _singleIncidentRadiusM) {
          final danger =
              incident.confidence *
              0.45 *
              (1.0 - (dist / _singleIncidentRadiusM));
          maxDangerAtPoint = math.max(maxDangerAtPoint, danger);
        }
      }

      for (final bulk in bulkIncidents) {
        final dist = _haversineDistance(point, bulk.center);
        if (dist <= _bulkIncidentRadiusM) {
          final danger =
              bulk.avgConfidence * 0.65 * (1.0 - (dist / _bulkIncidentRadiusM));
          maxDangerAtPoint = math.max(maxDangerAtPoint, danger);
        }
      }

      maxDangerOnRoute = math.max(maxDangerOnRoute, maxDangerAtPoint);
    }

    return maxDangerOnRoute;
  }

  /// Pick the safest route from multiple alternatives
  /// Returns: {index, dangerScore} where index is the safest route
  static Map<String, dynamic> pickSafestRoute(
    List<List<LatLng>> decodedRoutes,
    List<HotspotZone> hotspots, {
    List<MapIncident> incidents = const [],
    List<BulkIncident> bulkIncidents = const [],
  }) {
    if (decodedRoutes.isEmpty) {
      return {'index': 0, 'dangerScore': 0.0};
    }

    double minDangerScore = double.infinity;
    int safestIndex = 0;

    for (int i = 0; i < decodedRoutes.length; i++) {
      final score = scoreRoute(
        decodedRoutes[i],
        hotspots,
        incidents: incidents,
        bulkIncidents: bulkIncidents,
      );
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
