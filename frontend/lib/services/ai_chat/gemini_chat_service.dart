import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';

class GeminiChatService {
  static const String _endpoint = '${AppConfig.backendUrl}/chat/send';

  /// Send a message to Gemini chat API with optional location context
  /// @param message - User's chat message
  /// @param latitude - Optional user latitude for incident context
  /// @param longitude - Optional user longitude for incident context
  /// @return - Gemini's response text
  static Future<String> sendMessage(
    String message, {
    double? latitude,
    double? longitude,
  }) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      final payload = {
        'message': message,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'No response received';
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please wait a moment.');
      } else if (response.statusCode == 503) {
        throw Exception('Service temporarily unavailable. Please try again.');
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
