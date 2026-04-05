import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

/// Service for reverse geocoding coordinates to address + city
class GeocodingService {
  static final String _baseUrl = '${AppConfig.backendUrl}/geocode';

  /// Convert coordinates to address and city
  /// returns: {text: formatted_address, city: city_name}
  static Future<Map<String, String?>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl?lat=$latitude&lng=$longitude');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Geocoding request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'] as String?;
        final city = data['city'] as String?;

        return {
          'text': text,
          'city': city,
        };
      } else {
        throw Exception('Geocoding API error: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      return {'text': null, 'city': null};
    } catch (e) {
      return {'text': null, 'city': null};
    }
  }
}
