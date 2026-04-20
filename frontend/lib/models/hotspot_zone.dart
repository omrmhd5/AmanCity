import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

/// Model representing a predicted hotspot zone
/// Hotspots are high-risk areas predicted based on incident clustering
class HotspotZone {
  final String id;
  final LatLng center;
  final double radiusKm;
  final double radiusMeters;
  final double riskScore; // 0-1, where 1 is highest risk
  final int incidentCount;
  final double avgConfidence;
  final DateTime updatedAt;
  final List<String> incidentTypes; // Types of incidents in this hotspot

  HotspotZone({
    required this.id,
    required this.center,
    required this.radiusKm,
    required this.radiusMeters,
    required this.riskScore,
    required this.incidentCount,
    required this.avgConfidence,
    required this.updatedAt,
    this.incidentTypes = const [],
  });

  /// Factory constructor to create from JSON
  factory HotspotZone.fromJson(Map<String, dynamic> json) {
    return HotspotZone(
      id: json['id'] as String? ?? 'unknown',
      center: LatLng(
        (json['center']['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['center']['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 1.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 1000.0,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.5,
      incidentCount: (json['incidentCount'] as num?)?.toInt() ?? 0,
      avgConfidence: (json['avgConfidence'] as num?)?.toDouble() ?? 0.5,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      incidentTypes: json['incidentTypes'] != null
          ? List<String>.from(json['incidentTypes'] as List)
          : [],
    );
  }

  /// Get risk level label
  String get riskLevel {
    if (riskScore >= 0.7) return 'Critical';
    if (riskScore >= 0.5) return 'High';
    if (riskScore >= 0.3) return 'Medium';
    return 'Low';
  }

  /// Get risk color (green -> yellow -> red)
  Color get riskColor {
    if (riskScore >= 0.7) {
      return Colors.red;
    } else if (riskScore >= 0.5) {
      return Colors.orange;
    } else if (riskScore >= 0.3) {
      return Colors.amber;
    }
    return Colors.green;
  }

  /// Get fill color with opacity for map display
  Color get fillColor {
    return riskColor.withOpacity(0.25);
  }

  /// Get stroke color (darker version of fill)
  Color get strokeColor {
    return riskColor.withOpacity(0.7);
  }

  /// Time since last update
  String get timeSinceUpdate {
    final difference = DateTime.now().difference(updatedAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Generate smart warning message based on incident types
  String get smartWarningMessage {
    // Filter out "Unknown" and empty types
    final validTypes = incidentTypes
        .where((type) => type.isNotEmpty && type.toLowerCase() != 'unknown')
        .toList();

    if (validTypes.isEmpty) {
      return 'High predicted risk based on recent incident patterns.';
    }

    final typeList = validTypes.join(', ');
    final typeCount = validTypes.length;

    if (typeCount == 1) {
      return 'Recent $typeList reports in this area have elevated risk.';
    } else {
      return 'Multiple incident types: $typeList.';
    }
  }
}
