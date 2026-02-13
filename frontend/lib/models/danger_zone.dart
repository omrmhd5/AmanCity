import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum DangerLevel { low, medium, high }

class DangerZone {
  final String id;
  final LatLng center;
  final double radiusMeters;
  final DangerLevel level;
  final String description;
  final DateTime lastUpdated;

  DangerZone({
    required this.id,
    required this.center,
    required this.radiusMeters,
    required this.level,
    required this.description,
    required this.lastUpdated,
  });

  // Get color based on danger level
  Color get zoneColor {
    switch (level) {
      case DangerLevel.low:
        return Colors.amber.withOpacity(0.3);
      case DangerLevel.medium:
        return Colors.orange.withOpacity(0.4);
      case DangerLevel.high:
        return const Color(0xFFEF4444).withOpacity(0.5);
    }
  }

  // Get stroke color
  Color get strokeColor {
    switch (level) {
      case DangerLevel.low:
        return Colors.amber;
      case DangerLevel.medium:
        return Colors.orange;
      case DangerLevel.high:
        return const Color(0xFFEF4444);
    }
  }

  String get levelLabel {
    switch (level) {
      case DangerLevel.low:
        return 'Low Risk';
      case DangerLevel.medium:
        return 'Medium Risk';
      case DangerLevel.high:
        return 'High Risk';
    }
  }
}
