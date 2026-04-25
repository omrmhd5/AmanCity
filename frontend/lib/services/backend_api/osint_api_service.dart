import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/osint_incident.dart';

class OsintApiService {
  static const String _baseUrl = '${AppConfig.backendUrl}/osint';

  /// Trigger a Grok OSINT scan
  /// Returns summary with scanned, saved, skipped counts
  static Future<Map<String, dynamic>> triggerScan() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/scan'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'scanned': data['scanned'] ?? 0,
          'saved': data['saved'] ?? 0,
          'skipped_vague': data['skipped_vague'] ?? 0,
          'skipped_duplicate': data['skipped_duplicate'] ?? 0,
          'skipped_geocode_fail': data['skipped_geocode_fail'] ?? 0,
          'skipped_unknown_type': data['skipped_unknown_type'] ?? 0,
        };
      } else if (response.statusCode == 429) {
        throw Exception(
          'Too many scan requests. You can trigger a maximum of 5 scans per hour.',
        );
      } else if (response.statusCode == 502) {
        throw Exception('Grok scan failed. Please try again later.');
      } else {
        throw Exception('Failed to trigger scan: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Fetch all OSINT_Twitter incidents
  /// Returns list of OsintIncident objects
  static Future<List<OsintIncident>> fetchIncidents() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/incidents'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final incidents = data['incidents'] as List? ?? [];

        return incidents.map((json) => OsintIncident.fromJson(json)).toList();
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to fetch incidents: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
