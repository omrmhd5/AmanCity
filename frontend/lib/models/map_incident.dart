import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/incident_types_config.dart';

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
  final double confidence;
  final String source; // "Human" or "OSINT_Twitter"
  final List<String> sourceUrls; // Twitter URLs for OSINT incidents
  final bool isMerged; // true if absorbed into a BulkIncident
  final String? bulkIncidentId; // ref to BulkIncident if isMerged
  final String? reportedByName; // Name of the reporter (if populated)

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
    this.confidence = 0.0,
    this.source = 'Human',
    this.sourceUrls = const [],
    this.isMerged = false,
    this.bulkIncidentId,
    this.reportedByName,
  });

  bool get isOsint => source == 'OSINT_Twitter';

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
