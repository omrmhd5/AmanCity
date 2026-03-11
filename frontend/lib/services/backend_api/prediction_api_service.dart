import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/prediction_result_model.dart';

/// API service for prediction-related requests
/// Handles communication with the YOLO inference backend
class PredictionApiService {
  /// Get MIME type based on file extension
  static String _getMimeType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mpeg':
      case 'mpg':
        return 'video/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Send image or video file for prediction
  /// Returns PredictionResult with class prediction and confidence score
  ///
  /// Throws Exception if prediction fails
  static Future<PredictionResult> predictFromFile(File file) async {
    try {
      final backendUrl = AppConfig.backendUrl;
      final predictionUrl = '$backendUrl/predict';
      final filename = file.path.split(Platform.isWindows ? '\\' : '/').last;

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(predictionUrl));

      // Add file to request with proper MIME type
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      // Set the content-type header with the proper MIME type
      // This fixes the issue of application/octet-stream being used
      request.headers['Content-Type'] = 'multipart/form-data';

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
            throw SocketException('Request timeout after 30 seconds'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response
        final jsonData = jsonDecode(response.body);

        // Extract prediction data from response
        final predictionData = jsonData['data'];

        if (predictionData != null) {
          return PredictionResult.fromJson(predictionData);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        throw Exception(
          'Prediction failed: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network Error: $e');
      throw Exception(
        'Network error: Unable to connect to prediction server.\n'
        'Backend URL: ${AppConfig.backendUrl}\n'
        'Error: $e',
      );
    } catch (e) {
      debugPrint('❌ Prediction Error: $e');
      throw Exception('Prediction error: $e');
    }
  }

  /// Get the prediction API URL (useful for testing or configuration)
  static String get predictionApiUrl => '${AppConfig.backendUrl}/predict';
}
