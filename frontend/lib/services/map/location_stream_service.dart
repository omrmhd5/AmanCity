import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reusable location stream service for real-time GPS tracking.
/// Used by MapScreen, ReportIncidentScreen, and LocationPickerMap.
class LocationStreamService {
  /// Start real-time location tracking stream.
  ///
  /// Parameters:
  ///   - onLocationUpdate: Callback fired on each new position
  ///   - distanceFilter: Only update if moved this many meters (default: 10m)
  ///
  /// Returns: StreamSubscription that caller must cancel in dispose()
  static StreamSubscription<Position> startLocationTracking({
    required Function(LatLng) onLocationUpdate,
    int distanceFilterMeters = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      onLocationUpdate(newLocation);
    });
  }
}
