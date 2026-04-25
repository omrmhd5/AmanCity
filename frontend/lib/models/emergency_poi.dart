import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/poi_types_config.dart';

enum POIType { hospital, policeStation, fireStation, safeCafe, safeZone }

class EmergencyPOI {
  final String id;
  final POIType type;
  final LatLng position;
  final String name;
  final String address;
  final String? phoneNumber;

  EmergencyPOI({
    required this.id,
    required this.type,
    required this.position,
    required this.name,
    required this.address,
    this.phoneNumber,
  });

  // Get color based on POI type
  Color get markerColor {
    final typeKey = _getTypeKey();
    return POITypesConfig.getByKey(typeKey).color;
  }

  // Get icon based on POI type
  IconData get icon {
    final typeKey = _getTypeKey();
    return POITypesConfig.getByKey(typeKey).icon;
  }

  String get typeLabel {
    final typeKey = _getTypeKey();
    return POITypesConfig.getByKey(typeKey).displayName;
  }

  /// Helper to convert POIType enum to config key
  String _getTypeKey() {
    switch (type) {
      case POIType.hospital:
        return 'hospital';
      case POIType.policeStation:
        return 'policeStation';
      case POIType.fireStation:
        return 'fireStation';
      case POIType.safeCafe:
        return 'safeCafe';
      case POIType.safeZone:
        return 'safeZone';
    }
  }
}
