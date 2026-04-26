import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hotspot_zone.dart';
import 'backend_api/directions_service.dart';
import '../utils/safe_route_scorer.dart';

class SafeRouteHomeResult {
  final bool routeFound;
  final String? googleMapsUrl;
  final double? dangerScore;
  final String? distance;
  final String? duration;
  final String? homeAddress;
  final String? errorMessage;

  SafeRouteHomeResult({
    this.routeFound = false,
    this.googleMapsUrl,
    this.dangerScore,
    this.distance,
    this.duration,
    this.homeAddress,
    this.errorMessage,
  });
}

class SafeRouteHomeService {
  /// Keywords that trigger route home detection
  static const List<String> homeKeywords = [
    'safest route home',
    'route home',
    'get home safe',
    'home safely',
    'go home safe',
    'get me home',
    'navigate home',
    'البيت',
    'أعود للبيت',
    'أعود إلى البيت',
    'طريق آمن للبيت',
    'طريقة آمنة للبيت',
  ];

  /// Detect if message is asking for route home
  static bool _detectRouteHomeRequest(String message) {
    final lowerMessage = message.toLowerCase();
    return homeKeywords.any(
      (keyword) => lowerMessage.contains(keyword.toLowerCase()),
    );
  }

  /// Load home location from SharedPreferences
  static Future<LatLng?> _getHomeLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('home_location_lat');
      final lng = prefs.getDouble('home_location_lng');

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('Error loading home location: $e');
    }
    return null;
  }

  /// Get home address from SharedPreferences
  static Future<String?> _getHomeAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('home_location_address');
    } catch (e) {
      return null;
    }
  }

  /// Sample waypoints from polyline (max 8 intermediate points)
  static List<String> _sampleWaypoints(List<LatLng> points) {
    if (points.length <= 2) return [];

    final waypointCount = 8;
    final sampleRate = (points.length / (waypointCount + 1)).ceil();
    final waypoints = <String>[];

    for (int i = sampleRate; i < points.length - 1; i += sampleRate) {
      if (waypoints.length < waypointCount) {
        waypoints.add('${points[i].latitude},${points[i].longitude}');
      }
    }

    return waypoints;
  }

  /// Detect route home request and calculate safe route
  static Future<SafeRouteHomeResult> detectAndCalculateRouteHome(
    String message,
    LatLng userLocation,
    List<HotspotZone> hotspots,
  ) async {
    try {
      // Check if message is asking for route home
      if (!_detectRouteHomeRequest(message)) {
        return SafeRouteHomeResult(routeFound: false);
      }

      // Load saved home location
      final homeLocation = await _getHomeLocation();
      if (homeLocation == null) {
        return SafeRouteHomeResult(
          routeFound: false,
          errorMessage: 'No home location saved. Please set it in Settings.',
        );
      }

      // Get home address
      final homeAddress = await _getHomeAddress();

      // Calculate safe route
      final routeData = await DirectionsService.getSafeRoute(
        userLocation,
        homeLocation,
        hotspots,
      );

      final points = routeData['points'] as List<LatLng>;
      final dangerScore = routeData['dangerScore'] as double;
      final distance = routeData['distance'] as String?;
      final duration = routeData['duration'] as String?;

      // Sample waypoints from polyline
      final waypoints = _sampleWaypoints(points);

      // Build Google Maps URL
      String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&origin=${userLocation.latitude},${userLocation.longitude}&destination=${homeLocation.latitude},${homeLocation.longitude}&travelmode=driving';

      if (waypoints.isNotEmpty) {
        googleMapsUrl += '&waypoints=${waypoints.join('|')}';
      }

      return SafeRouteHomeResult(
        routeFound: true,
        googleMapsUrl: googleMapsUrl,
        dangerScore: dangerScore,
        distance: distance,
        duration: duration,
        homeAddress: homeAddress ?? 'Home',
      );
    } catch (e) {
      print('Error calculating route home: $e');
      return SafeRouteHomeResult(
        routeFound: false,
        errorMessage: 'Error calculating route: ${e.toString()}',
      );
    }
  }
}
