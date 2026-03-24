import 'package:flutter/material.dart';

/// Centralized configuration for all incident types
/// Ensures consistency across map, filters, alerts, and details screens
class IncidentTypesConfig {
  static const List<IncidentTypeConfig> allTypes = [
    IncidentTypeConfig(
      key: 'Fire',
      displayName: 'Fire',
      icon: Icons.local_fire_department,
      color: Colors.red,
    ),
    IncidentTypeConfig(
      key: 'Accident',
      displayName: 'Accident',
      icon: Icons.directions_car,
      color: Colors.orange,
    ),
    IncidentTypeConfig(
      key: 'Flood',
      displayName: 'Flood',
      icon: Icons.water,
      color: Colors.blue,
    ),
    IncidentTypeConfig(
      key: 'Public_Issue',
      displayName: 'Public Issue',
      icon: Icons.block,
      color: Colors.amber,
    ),
    IncidentTypeConfig(
      key: 'Road_Damage',
      displayName: 'Road Damage',
      icon: Icons.construction,
      color: Colors.brown,
    ),
    IncidentTypeConfig(
      key: 'Damaged_Building',
      displayName: 'Damaged Building',
      icon: Icons.domain_disabled,
      color: Colors.grey,
    ),
    IncidentTypeConfig(
      key: 'Normal',
      displayName: 'Normal',
      icon: Icons.warning,
      color: Colors.deepPurple,
    ),
  ];

  /// Get config by incident type key
  static IncidentTypeConfig getByKey(String key) {
    try {
      return allTypes.firstWhere(
        (type) => type.key.replaceAll(' ', '_') == key.replaceAll(' ', '_'),
        orElse: () => allTypes.last, // Default to last item
      );
    } catch (e) {
      return allTypes.last;
    }
  }

  /// Get all incident types as filter options
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

/// Individual incident type configuration
class IncidentTypeConfig {
  final String key; // Storage key (snake_case)
  final String displayName; // Display name
  final IconData icon; // Icon
  final Color color; // Type color

  const IncidentTypeConfig({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}
