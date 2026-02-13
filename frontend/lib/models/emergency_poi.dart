import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    switch (type) {
      case POIType.hospital:
        return const Color(0xFFEF4444); // Red
      case POIType.policeStation:
        return const Color(0xFF3B82F6); // Blue
      case POIType.fireStation:
        return const Color(0xFFF59E0B); // Orange
      case POIType.safeCafe:
        return const Color(0xFF10B981); // Green
      case POIType.safeZone:
        return const Color(0xFF00B3A4); // Teal
    }
  }

  // Get icon based on POI type
  IconData get icon {
    switch (type) {
      case POIType.hospital:
        return Icons.local_hospital;
      case POIType.policeStation:
        return Icons.local_police;
      case POIType.fireStation:
        return Icons.fire_truck;
      case POIType.safeCafe:
        return Icons.local_cafe;
      case POIType.safeZone:
        return Icons.verified_user;
    }
  }

  String get typeLabel {
    switch (type) {
      case POIType.hospital:
        return 'Hospital';
      case POIType.policeStation:
        return 'Police Station';
      case POIType.fireStation:
        return 'Fire Station';
      case POIType.safeCafe:
        return 'Safe Café';
      case POIType.safeZone:
        return 'Safe Zone';
    }
  }
}
