import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum IncidentType { harassment, theft, assault, suspicious, other }

enum SeverityLevel { low, medium, high, critical }

class MapIncident {
  final String id;
  final IncidentType type;
  final SeverityLevel severity;
  final LatLng position;
  final String title;
  final String description;
  final DateTime timestamp;

  MapIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.position,
    required this.title,
    required this.description,
    required this.timestamp,
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
      case IncidentType.harassment:
        return Icons.record_voice_over;
      case IncidentType.theft:
        return Icons.warning;
      case IncidentType.assault:
        return Icons.dangerous;
      case IncidentType.suspicious:
        return Icons.remove_red_eye;
      case IncidentType.other:
        return Icons.info_outline;
    }
  }

  String get typeLabel {
    switch (type) {
      case IncidentType.harassment:
        return 'Harassment';
      case IncidentType.theft:
        return 'Theft';
      case IncidentType.assault:
        return 'Assault';
      case IncidentType.suspicious:
        return 'Suspicious Activity';
      case IncidentType.other:
        return 'Other';
    }
  }
}
