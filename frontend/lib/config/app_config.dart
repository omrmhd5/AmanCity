/// Environment configuration
/// Backend URL configuration for API calls
class AppConfig {
  /// Backend API base URL (includes /api)
  /// For emulator: 10.0.2.2:5000 (Android default gateway)
  /// For physical device: use your computer's local IP
  static const String backendUrl = 'http://10.0.2.2:5000/api';
}
