import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/hotspot_zone.dart';
import '../config/app_config.dart';

/// API service for hotspot predictions
class HotspotApiService {
  static const String _endpoint = '/hotspots';

  /// Get current predicted hotspots
  /// Returns list of HotspotZone objects representing high-risk areas
  static Future<List<HotspotZone>> getHotspots() async {
    try {
      final url = Uri.parse('${AppConfig.backendUrl}$_endpoint');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Hotspot request timed out');
            },
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          final data = jsonData['data'] as List?;

          if (data == null) {
            return [];
          }

          final hotspots = data
              .map((item) => HotspotZone.fromJson(item as Map<String, dynamic>))
              .toList();

          return hotspots;
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch hotspots');
        }
      } else if (response.statusCode == 404) {
        return []; // No hotspots yet
      } else {
        throw Exception('Failed to fetch hotspots: ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    }
  }

  /// Manually trigger hotspot recalculation
  /// Useful for manual refresh or testing
  static Future<void> recalculateHotspots() async {
    try {
      final url = Uri.parse('${AppConfig.backendUrl}$_endpoint/recalculate');

      final response = await http
          .post(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Hotspot recalculation request timed out');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to trigger recalculation: ${response.statusCode}',
        );
      }
    } on Exception {
      rethrow;
    }
  }
}
