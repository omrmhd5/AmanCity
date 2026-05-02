import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/incident_types_config.dart';
import 'map_incident.dart';

/// A sub-incident report belonging to a BulkIncident.
/// Mirrors the populated Incident document returned by the backend.
class BulkSubIncident {
  final String id;
  final String? title;
  final String? description;
  final String source; // "Human" or "OSINT_Twitter"
  final DateTime timestamp;
  final List<MediaItem> media;
  final List<String> sourceUrls;
  final double confidence;
  final String? reportedByName;

  BulkSubIncident({
    required this.id,
    this.title,
    this.description,
    this.source = 'Human',
    required this.timestamp,
    this.media = const [],
    this.sourceUrls = const [],
    this.confidence = 0.0,
    this.reportedByName,
  });

  bool get isOsint => source == 'OSINT_Twitter';

  factory BulkSubIncident.fromJson(Map<String, dynamic> json) {
    List<MediaItem> mediaList = [];
    if (json['media'] is List) {
      for (final m in (json['media'] as List)) {
        if (m is Map<String, dynamic>) {
          final url = m['url'] as String? ?? '';
          if (url.isNotEmpty) {
            mediaList.add(
              MediaItem(
                mediaType: m['mediaType'] as String? ?? 'IMAGE',
                url: url,
              ),
            );
          }
        }
      }
    }

    // OSINT incidents store their score in osintConfidence; fall back to confidence
    double confidence = 0.0;
    final osintConf = json['osintConfidence'];
    final conf = json['confidence'];
    if (osintConf is num) {
      confidence = osintConf.toDouble();
    } else if (conf is num) {
      confidence = conf.toDouble();
    }

    // reportedBy may be populated as object with name/username
    String? reportedByName;
    final rb = json['reportedBy'];
    if (rb is Map<String, dynamic>) {
      reportedByName = rb['name'] as String? ?? rb['username'] as String?;
    }

    return BulkSubIncident(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      source: json['source'] as String? ?? 'Human',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      media: mediaList,
      sourceUrls: List<String>.from(json['sourceUrls'] ?? []),
      confidence: confidence,
      reportedByName: reportedByName,
    );
  }
}

/// Aggregated group of related incidents reported in the same area.
class BulkIncident {
  final String id;
  final String type;
  final int count;
  final LatLng center;
  final String? locationText;
  final String? city;
  final DateTime firstReportedAt;
  final DateTime lastUpdatedAt;
  final List<String> mediaUrls;
  final List<String> sourceUrls;
  final List<String> confirmedSources;
  final double avgConfidence;

  /// Populated sub-incidents (only present when fetched via GET /bulk-incidents/:id)
  final List<BulkSubIncident> subIncidents;

  BulkIncident({
    required this.id,
    required this.type,
    required this.count,
    required this.center,
    this.locationText,
    this.city,
    required this.firstReportedAt,
    required this.lastUpdatedAt,
    this.mediaUrls = const [],
    this.sourceUrls = const [],
    this.confirmedSources = const [],
    this.avgConfidence = 0.0,
    this.subIncidents = const [],
  });

  Color get typeColor => IncidentTypesConfig.getByKey(type).color;
  IconData get typeIcon => IncidentTypesConfig.getByKey(type).icon;

  bool get hasHumanReports => confirmedSources.contains('Human');
  bool get hasOsintReports => confirmedSources.contains('OSINT_Twitter');

  factory BulkIncident.fromJson(Map<String, dynamic> json) {
    // Parse type name from populated object or string
    String typeName = '';
    if (json['type'] is Map) {
      final typeObj = json['type'] as Map<String, dynamic>;
      typeName = typeObj['nameEn'] ?? typeObj['type'] ?? '';
    } else if (json['type'] is String) {
      typeName = json['type'] as String;
    }

    final centerData = json['center'] as Map<String, dynamic>? ?? {};
    final center = LatLng(
      (centerData['latitude'] as num?)?.toDouble() ?? 0.0,
      (centerData['longitude'] as num?)?.toDouble() ?? 0.0,
    );

    // Parse sub-incidents if populated
    List<BulkSubIncident> subIncidents = [];
    if (json['incidentIds'] is List) {
      for (final item in (json['incidentIds'] as List)) {
        if (item is Map<String, dynamic> && item.containsKey('_id')) {
          try {
            subIncidents.add(BulkSubIncident.fromJson(item));
          } catch (_) {}
        }
      }
    }

    double avgConf = 0.0;
    final confVal = json['avgConfidence'];
    if (confVal is num) avgConf = confVal.toDouble();

    return BulkIncident(
      id: json['_id'] as String? ?? '',
      type: typeName,
      count: (json['count'] as num?)?.toInt() ?? 1,
      center: center,
      locationText: json['locationText'] as String?,
      city: json['city'] as String?,
      firstReportedAt:
          DateTime.tryParse(json['firstReportedAt'] as String? ?? '') ??
          DateTime.now(),
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt'] as String? ?? '') ??
          DateTime.now(),
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      sourceUrls: List<String>.from(json['sourceUrls'] ?? []),
      confirmedSources: List<String>.from(json['confirmedSources'] ?? []),
      avgConfidence: avgConf,
      subIncidents: subIncidents,
    );
  }
}
