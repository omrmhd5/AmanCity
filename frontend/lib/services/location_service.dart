import 'package:geolocator/geolocator.dart';
import 'dart:math';

/// Utility service for location-related calculations
/// All distances returned in kilometers
class LocationService {
  /// Calculate distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    try {
      // Use Geolocator's built-in distanceBetween (returns meters)
      final distanceInMeters = Geolocator.distanceBetween(
        lat1,
        lng1,
        lat2,
        lng2,
      );
      // Convert to kilometers
      return distanceInMeters / 1000;
    } catch (e) {
      print('❌ Error calculating distance: $e');
      // Fallback to manual haversine calculation
      return _haversineDistance(lat1, lng1, lat2, lng2);
    }
  }

  /// Manual haversine formula implementation
  /// Returns distance in kilometers
  static double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const int earthRadiusKm = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusKm * c;

    return distance;
  }

  /// Convert degrees to radians
  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).toStringAsFixed(0);
      return '${meters}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  /// Check if location is within radius (in km)
  static bool isWithinRadius({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    required double radiusKm,
  }) {
    final distance = calculateDistance(
      lat1: userLat,
      lng1: userLng,
      lat2: targetLat,
      lng2: targetLng,
    );
    return distance <= radiusKm;
  }
}
