import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum SeverityLevel { low, medium, high, critical }

class MediaItem {
  final String mediaType; // "IMAGE", "VIDEO", etc.
  final String url;

  MediaItem({required this.mediaType, required this.url});
}

class MapIncident {
  final String id;
  final String type;
  final SeverityLevel severity;
  final LatLng position;
  final String title;
  final String description;
  final DateTime timestamp;
  final List<MediaItem> media;

  MapIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.position,
    required this.title,
    required this.description,
    required this.timestamp,
    this.media = const [],
  });

  // Get color based on severity
  Color get severityColor {
    switch (severity) {
      case SeverityLevel.low:
        return Colors.amber;
      case SeverityLevel.medium:
        return Colors.orange;
      case SeverityLevel.high:
        return const Color(0xFFEF4444);
      case SeverityLevel.critical:
        return const Color(0xFFB91C1C);
    }
  }

  // Get icon based on type
  IconData get typeIcon {
    switch (type) {
      case 'Accident':
        return Icons.car_crash;
      case 'Damaged_Building':
        return Icons.apartment;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Flood':
        return Icons.water_damage;
      case 'Normal':
        return Icons.info_outline;
      case 'Public_Issue':
        return Icons.people;
      case 'Road_Damage':
        return Icons.warning_amber;
      default:
        return Icons.location_on;
    }
  }

  String get typeLabel {
    return type;
  }
}
