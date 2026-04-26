import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_config.dart';
import '../../utils/polyline_decoder.dart';
import '../../utils/safe_route_scorer.dart';
import '../../models/hotspot_zone.dart';

/// Service for getting directions and route polylines
class DirectionsService {
  static final String _baseUrl = '${AppConfig.backendUrl}/directions';

  /// Get route from origin to destination
  /// Returns: {polyline, distance, duration, startAddress, endAddress}
  static Future<Map<String, dynamic>> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin_lat=${origin.latitude}&origin_lng=${origin.longitude}&dest_lat=${destination.latitude}&dest_lng=${destination.longitude}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Directions request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Decode the polyline string to list of LatLng
          final polylineString = data['polyline'] as String;
          final points = PolylineDecoder.decode(polylineString);

          return {
            'points': points,
            'distance': data['distance']['text'] ?? 'Unknown',
            'distance_m': data['distance']['value'] ?? 0,
            'duration': data['duration']['text'] ?? 'Unknown',
            'duration_s': data['duration']['value'] ?? 0,
            'startAddress': data['startAddress'] ?? '',
            'endAddress': data['endAddress'] ?? '',
          };
        } else {
          throw Exception(data['message'] ?? 'Unable to get route');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Unable to get route');
      }
    } on SocketException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Get the safest route avoiding danger zones
  /// Fetches up to 3 alternatives and scores them against hotspots
  /// Returns: {points, distance, duration, dangerScore, startAddress, endAddress, alternativeCount}
  static Future<Map<String, dynamic>> getSafeRoute(
    LatLng origin,
    LatLng destination,
    List<HotspotZone> hotspots,
  ) async {
    try {
      // Fetch routes (includes alternatives)
      final response = await http
          .get(
            Uri.parse(
              '${_baseUrl}?origin_lat=${origin.latitude}&origin_lng=${origin.longitude}&dest_lat=${destination.latitude}&dest_lng=${destination.longitude}',
            ),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Directions request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Decode all available routes
          final routes = data['routes'] as List? ?? [];
          final decodedRoutes = <List<LatLng>>[];

          for (final route in routes) {
            final polylineString = route['polyline'] as String;
            final points = PolylineDecoder.decode(polylineString);
            decodedRoutes.add(points);
          }

          // Find safest route based on hotspot avoidance
          final result = SafeRouteScorer.pickSafestRoute(
            decodedRoutes,
            hotspots,
          );

          final safestIndex = result['index'] as int;
          final dangerScore = result['dangerScore'] as double;

          // Use the safest route data
          final safestRouteData = routes[safestIndex];

          return {
            'points': decodedRoutes[safestIndex],
            'distance': safestRouteData['distance']['text'] ?? 'Unknown',
            'distance_m': safestRouteData['distance']['value'] ?? 0,
            'duration': safestRouteData['duration']['text'] ?? 'Unknown',
            'duration_s': safestRouteData['duration']['value'] ?? 0,
            'dangerScore': dangerScore,
            'startAddress': safestRouteData['startAddress'] ?? '',
            'endAddress': safestRouteData['endAddress'] ?? '',
            'alternativeCount': routes.length,
          };
        } else {
          throw Exception(data['message'] ?? 'Unable to get route');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Unable to get route');
      }
    } on SocketException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
