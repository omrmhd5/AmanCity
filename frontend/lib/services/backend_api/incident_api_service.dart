import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_config.dart';
import '../../models/map_incident.dart';
import '../../utils/incident_types_config.dart';

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

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw SocketException('Request timeout'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        final incidentData = jsonData['data'];

        if (incidentData != null) {
          return IncidentResponse.fromJson(incidentData);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        // Try to extract error message from JSON response
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage =
              errorJson['message'] ?? 'Unable to save your report';
          throw Exception(errorMessage);
        } catch (e) {
          // If JSON parsing fails, show generic message
          throw Exception('Unable to save your report. Please try again.');
        }
      }
    } on SocketException catch (e) {
      // Network Error
      throw Exception(
        'Unable to connect to the server. Please check your connection and try again.',
      );
    } catch (e) {
      // Error saving incident
      throw Exception('Unable to save your report. Please try again.');
    }
  }

  /// Get all incidents from backend
  /// Returns list of MapIncident for map display
  static Future<List<MapIncident>> getIncidents() async {
    final incidentsUrl = '${AppConfig.backendUrl}/incidents';

    try {
      final response = await http
          .get(Uri.parse(incidentsUrl))
          .timeout(
            const Duration(minutes: 3),
            onTimeout: () => throw SocketException('Request timeout'),
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final incidents = jsonData['data'] as List<dynamic>? ?? [];

        List<MapIncident> mapIncidents = [];
        for (var incident in incidents) {
          try {
            final mapIncident = _parseIncident(incident);
            mapIncidents.add(mapIncident);
          } catch (e) {
            // Skipping invalid incident
          }
        }

        return mapIncidents;
      } else {
        throw Exception('Unable to retrieve reports. Please try again.');
      }
    } on SocketException catch (e) {
      // Network Error
      throw Exception(
        'Unable to connect to the server. Please check your connection and try again.',
      );
    } catch (e) {
      // Error loading incidents
      throw Exception('Unable to retrieve reports. Please try again.');
    }
  }

  /// Parse backend incident to MapIncident
  /// Handles both legacy responses and new three-model system responses
  static MapIncident _parseIncident(Map<String, dynamic> data) {
    final id = data['_id'] ?? '';
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final timestamp =
        DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();

    // Parse location
    final lat = (data['location']?['latitude'] ?? 0).toDouble();
    final lng = (data['location']?['longitude'] ?? 0).toDouble();
    final position = LatLng(lat, lng);

    // Get type name from populated backend type object
    String type = '';
    if (data['type'] is Map) {
      final typeObj = data['type'] as Map<String, dynamic>;
      type = typeObj['nameEn'] ?? typeObj['type'] ?? '';
    } else if (data['type'] is String) {
      // Direct string reference (legacy)
      type = data['type'];
    }

    // Validate type exists in IncidentTypesConfig
    // If invalid, mark as unknown
    try {
      IncidentTypesConfig.getByKey(type);
    } catch (e) {
      // Type not found in config, keep as-is
    }

    // Parse media
    List<MediaItem> mediaList = [];
    if (data['media'] is List) {
      final mediaArray = data['media'] as List<dynamic>;
      for (var mediaItem in mediaArray) {
        if (mediaItem is Map<String, dynamic>) {
          final mediaType = mediaItem['mediaType'] as String? ?? 'IMAGE';
          final url = mediaItem['url'] as String? ?? '';
          if (url.isNotEmpty) {
            mediaList.add(MediaItem(mediaType: mediaType, url: url));
          }
        }
      }
    }

    // Parse confidence (handle various numeric types from API)
    double confidence = 0.0;
    if (data['confidence'] != null) {
      final confValue = data['confidence'];
      if (confValue is double) {
        confidence = confValue;
      } else if (confValue is int) {
        confidence = confValue.toDouble();
      } else if (confValue is num) {
        confidence = confValue.toDouble();
      }
    }

    return MapIncident(
      id: id,
      type: type,
      position: position,
      title: title,
      description: description,
      timestamp: timestamp,
      media: mediaList,
      addressText: data['location']?['text'] as String?,
      city: data['location']?['city'] as String?,
      confidence: confidence,
    );
  }
}
