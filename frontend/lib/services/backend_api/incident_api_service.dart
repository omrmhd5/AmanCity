import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../../config/app_config.dart';

/// Model for incident creation response
class IncidentResponse {
  final String id;
  final String title;
  final String className;
  final double lat;
  final double lng;
  final double confidence;

  IncidentResponse({
    required this.id,
    required this.title,
    required this.className,
    required this.lat,
    required this.lng,
    required this.confidence,
  });

  factory IncidentResponse.fromJson(Map<String, dynamic> json) {
    // Handle type being either a string or a populated object
    String className = '';
    if (json['type'] is String) {
      className = json['type'];
    } else if (json['type'] is Map) {
      className = json['type']['type'] ?? '';
    }

    return IncidentResponse(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      className: className,
      lat: (json['location']?['latitude'] ?? 0).toDouble(),
      lng: (json['location']?['longitude'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// API service for incident-related requests
class IncidentApiService {
  /// Create incident with photo
  /// Returns IncidentResponse with created incident data
  static Future<IncidentResponse> createIncident({
    required File photo,
    required String title,
    required String className,
    required String description,
    required double latitude,
    required double longitude,
    required double confidence,
  }) async {
    final incidentsUrl = '${AppConfig.backendUrl}/incidents';
    final filename = photo.path.split(Platform.isWindows ? '\\' : '/').last;

    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(incidentsUrl));

      // Add file
      final bytes = await photo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      // Add form fields
      request.fields['title'] = title;
      request.fields['className'] = className; // e.g., "Accident"
      request.fields['description'] = description;
      request.fields['confidence'] = confidence.toString();
      request.fields['location'] = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      });

      print('📤 Creating incident: $title ($className)');
      print('📁 File: $filename');
      print('📍 Location: $latitude, $longitude');
      print('📨 Sending to: $incidentsUrl');

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw SocketException('Request timeout'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Response status: ${response.statusCode}');
      print('📨 Response: ${response.body}');

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        final incidentData = jsonData['data'];

        if (incidentData != null) {
          return IncidentResponse.fromJson(incidentData);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
          'Failed to create incident: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException catch (e) {
      print('❌ Network Error: $e');
      throw Exception(
        'Network error: Unable to connect to backend\n'
        'URL: $incidentsUrl\n'
        'Error: $e',
      );
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Failed to create incident: $e');
    }
  }
}
