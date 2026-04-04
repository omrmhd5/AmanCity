import 'package:flutter/material.dart';

/// Centralized configuration for all POI (Point of Interest) types
/// Ensures consistency across map markers and detail sheets
class POITypesConfig {
  static const List<POITypeConfig> allTypes = [
    POITypeConfig(
      key: 'hospital',
      displayName: 'Hospital',
      icon: Icons.local_hospital,
      color: Color(0xFFEF4444), // Red
    ),
    POITypeConfig(
      key: 'policeStation',
      displayName: 'Police Station',
      icon: Icons.local_police,
      color: Color(0xFF3B82F6), // Blue
    ),
    POITypeConfig(
      key: 'fireStation',
      displayName: 'Fire Station',
      icon: Icons.fire_truck,
      color: Color(0xFFF59E0B), // Orange
    ),
    POITypeConfig(
      key: 'safeCafe',
      displayName: 'Safe Café',
      icon: Icons.local_cafe,
      color: Color(0xFF10B981), // Green
    ),
    POITypeConfig(
      key: 'safeZone',
      displayName: 'Safe Zone',
      icon: Icons.verified_user,
      color: Color(0xFF00B3A4), // Teal
    ),
  ];

  /// Get config by POI type key
  static POITypeConfig getByKey(String key) {
    try {
      return allTypes.firstWhere(
        (type) => type.key == key,
        orElse: () => allTypes.first,
      );
    } catch (e) {
      return allTypes.first;
    }
  }

  /// Get all POI types as options
  static List<Map<String, dynamic>> getFilterOptions() {
    return allTypes
        .map(
          (type) => {
            'title': type.displayName,
            'icon': type.icon,
            'color': type.color,
            'key': type.key,
          },
        )
        .toList();
  }
}

/// Individual POI type configuration
class POITypeConfig {
  final String key;
  final String displayName;
  final IconData icon;
  final Color color;

  const POITypeConfig({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}
