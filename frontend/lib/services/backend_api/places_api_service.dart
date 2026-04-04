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
  /// returns: List<EmergencyPOI>
  static Future<List<EmergencyPOI>> getNearbyPlaces(
    LatLng location, {
    String type = 'all',
  }) async {
    try {
      print(
        '📍 Fetching nearby places: lat=${location.latitude}, lng=${location.longitude}, type=$type',
      );

      final url = Uri.parse(
        '$_baseUrl/nearby?lat=${location.latitude}&lng=${location.longitude}&type=$type',
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

        print('✅ Fetched ${places.length} places');

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
        throw Exception('Invalid parameters: ${errorData['message']}');
      } else {
        throw Exception('Failed to fetch places: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      rethrow;
    } catch (e) {
      print('❌ Error fetching places: $e');
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
}
