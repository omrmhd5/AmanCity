import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/emergency_poi.dart';
import '../../config/app_config.dart';

/// Service for fetching nearby places (hospitals, police stations, fire stations)
/// from backend which proxies Google Places API
class PlacesApiService {
  static final String _baseUrl = '${AppConfig.backendUrl}/places';

  /// Fetch nearby places around a location
  /// type: 'hospital', 'police', 'fire', or 'all'
  /// radiusKm: search radius in kilometers (default 5 km)
  /// returns: List<EmergencyPOI>
  static Future<List<EmergencyPOI>> getNearbyPlaces(
    LatLng location, {
    String type = 'all',
    double radiusKm = 5.0,
  }) async {
    try {
      // Convert radius to meters
      final radiusMeters = (radiusKm * 1000).toInt();

      final url = Uri.parse(
        '$_baseUrl/nearby?lat=${location.latitude}&lng=${location.longitude}&type=$type&radius=$radiusMeters',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Places API request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List<dynamic>? ?? [];

        // Convert to EmergencyPOI objects
        return places.map((place) {
          return EmergencyPOI(
            id: place['id'] ?? 'unknown_${place['name']}',
            type: _mapPlaceType(place['type']),
            position: LatLng(place['lat'], place['lng']),
            name: place['name'] ?? 'Unknown Place',
            address: place['address'] ?? '',
            phoneNumber: place['phoneNumber'],
          );
        }).toList();
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid search parameters');
      } else {
        // Try to extract error message from JSON response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ?? 'Unable to find locations';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Unable to find nearby locations. Please try again.');
        }
      }
    } on SocketException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Map backend type string to POIType
  static POIType _mapPlaceType(dynamic typeValue) {
    final typeStr = typeValue.toString().toLowerCase();
    switch (typeStr) {
      case 'hospital':
        return POIType.hospital;
      case 'police':
        return POIType.policeStation;
      case 'fire':
        return POIType.fireStation;
      default:
        return POIType.hospital;
    }
  }

  /// Search for any places (POIs, streets, buildings, etc.) by query text
  /// query: search string
  /// location: center point for the search
  /// radiusKm: search radius in kilometers (default 5 km)
  /// returns: List<Map> with place data including type classification
  static Future<List<Map<String, dynamic>>> searchPlaces(
    String query,
    LatLng location, {
    double radiusKm = 5.0,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Convert radius to meters
      final radiusMeters = (radiusKm * 1000).toInt();

      final url = Uri.parse(
        '$_baseUrl/search?query=${Uri.encodeComponent(query)}&lat=${location.latitude}&lng=${location.longitude}&radius=$radiusMeters',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Search API request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List<dynamic>? ?? [];

        // Return raw place data - will be handled by UI for rendering
        return places.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid search parameters');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Search failed';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Unable to search places. Please try again.');
        }
      }
    } on SocketException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
