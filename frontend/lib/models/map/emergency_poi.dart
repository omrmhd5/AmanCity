import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/poi_types_config.dart';

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
    return POITypesConfig.getByKey(typeKey).localizedName;
  }

  /// Helper to convert POIType enum to config key
  String _getTypeKey() {
    switch (type) {
      case POIType.hospital:
        return 'hospital';
      case POIType.policeStation:
        return 'police_station';
      case POIType.fireStation:
        return 'fire_station';
      case POIType.safeCafe:
        return 'safe_cafe';
      case POIType.safeZone:
        return 'safe_zone';
    }
  }

  /// Convert POI to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(), // Serialize enum as string
      'latitude': position.latitude,
      'longitude': position.longitude,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
    };
  }

  /// Create POI from JSON (for SharedPreferences restoration)
  factory EmergencyPOI.fromJson(Map<String, dynamic> json) {
    // Parse type string back to enum
    final typeStr = (json['type'] as String)
        .split('.')
        .last; // Remove "POIType." prefix
    POIType type;
    switch (typeStr) {
      case 'hospital':
        type = POIType.hospital;
        break;
      case 'policeStation':
        type = POIType.policeStation;
        break;
      case 'fireStation':
        type = POIType.fireStation;
        break;
      case 'safeCafe':
        type = POIType.safeCafe;
        break;
      case 'safeZone':
        type = POIType.safeZone;
        break;
      default:
        type = POIType.hospital;
    }

    return EmergencyPOI(
      id: json['id'] as String,
      type: type,
      position: LatLng(json['latitude'] as double, json['longitude'] as double),
      name: json['name'] as String,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}
