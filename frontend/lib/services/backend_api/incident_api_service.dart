import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_config.dart';
import '../../models/map_incident.dart';

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

  /// Get all incidents from backend
  /// Returns list of MapIncident for map display
  static Future<List<MapIncident>> getIncidents() async {
    final incidentsUrl = '${AppConfig.backendUrl}/incidents';

    try {
      print('📍 Fetching incidents from: $incidentsUrl');

      final response = await http
          .get(Uri.parse(incidentsUrl))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw SocketException('Request timeout'),
          );

      print('📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final incidents = jsonData['data'] as List<dynamic>? ?? [];

        List<MapIncident> mapIncidents = [];
        for (var incident in incidents) {
          try {
            final mapIncident = _parseIncident(incident);
            mapIncidents.add(mapIncident);
          } catch (e) {
            print('⚠️ Skipping invalid incident: $e');
          }
        }

        print('✅ Loaded ${mapIncidents.length} incidents');
        return mapIncidents;
      } else {
        throw Exception('Failed to load incidents: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('❌ Network Error: $e');
      throw Exception('Network error: Unable to connect to backend\nError: $e');
    } catch (e) {
      print('❌ Error loading incidents: $e');
      throw Exception('Failed to load incidents: $e');
    }
  }

  /// Parse backend incident to MapIncident
  static MapIncident _parseIncident(Map<String, dynamic> data) {
    final id = data['_id'] ?? '';
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final confidence = (data['confidence'] ?? 0).toDouble();
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

    final severity = _mapConfidenceToSeverity(confidence);

    return MapIncident(
      id: id,
      type: type,
      severity: severity,
      position: position,
      title: title,
      description: description,
      timestamp: timestamp,
      media: mediaList,
    );
  }

  /// Map YOLO confidence score to severity level
  static SeverityLevel _mapConfidenceToSeverity(double confidence) {
    if (confidence >= 0.9) return SeverityLevel.critical;
    if (confidence >= 0.75) return SeverityLevel.high;
    if (confidence >= 0.5) return SeverityLevel.medium;
    return SeverityLevel.low;
  }
}
