import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/incident_types_config.dart';

class MediaItem {
  final String mediaType; // "IMAGE", "VIDEO", etc.
  final String url;

  MediaItem({required this.mediaType, required this.url});
}

class MapIncident {
  final String id;
  final String type;
  final LatLng position;
  final String title;
  final String description;
  final DateTime timestamp;
  final List<MediaItem> media;
  final String? addressText;
  final String? city;

  MapIncident({
    required this.id,
    required this.type,
    required this.position,
    required this.title,
    required this.description,
    required this.timestamp,
    this.media = const [],
    this.addressText,
    this.city,
  });

  // Get color based on incident type
  Color get typeColor {
    return IncidentTypesConfig.getByKey(type).color;
  }

  // Get icon based on type
  IconData get typeIcon {
    return IncidentTypesConfig.getByKey(type).icon;
  }

  String get typeLabel {
    return type;
  }
}
