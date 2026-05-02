import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/bulk_incident.dart';

class BulkIncidentApiService {
  static const String _endpoint = '/bulk-incidents';

  /// Fetch all bulk incidents (unmerged aggregation groups)
  static Future<List<BulkIncident>> getBulkIncidents() async {
    try {
      final url = Uri.parse('${AppConfig.backendUrl}$_endpoint');
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw SocketException('Request timeout'),
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final list = jsonData['data'] as List<dynamic>? ?? [];
        final result = <BulkIncident>[];
        for (final item in list) {
          try {
            result.add(BulkIncident.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
        return result;
      }
      throw Exception('Failed to fetch bulk incidents');
    } on SocketException {
      throw Exception('Unable to connect to server. Check your connection.');
    } catch (e) {
      throw Exception('Unable to retrieve bulk incidents. Please try again.');
    }
  }

  /// Fetch a single BulkIncident with all sub-incidents populated
  static Future<BulkIncident> getBulkIncidentById(String id) async {
    try {
      final url = Uri.parse('${AppConfig.backendUrl}$_endpoint/$id');
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw SocketException('Request timeout'),
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return BulkIncident.fromJson(jsonData['data'] as Map<String, dynamic>);
      }
      throw Exception('Bulk incident not found');
    } on SocketException {
      throw Exception('Unable to connect to server. Check your connection.');
    } catch (e) {
      throw Exception('Unable to retrieve bulk incident. Please try again.');
    }
  }
}
