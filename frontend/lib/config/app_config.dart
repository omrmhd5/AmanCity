/// Environment configuration
/// Backend URL configuration for API calls
class AppConfig {
  /// Backend API base URL (includes /api)
  /// For hotspot: use the host PC's IP address on the network
  /// For emulator on localhost: 10.0.2.2:5000 (Android default gateway)
  /// For physical device: use your computer's local IP
  // static const String backendUrl = 'http://10.0.2.2:5000/api';
  static const String backendUrl = 'http://192.168.1.30:5000/api';

  /// File server base URL (for uploading/serving files)
  /// For hotspot: use the host PC's IP address
  /// For emulator: 10.0.2.2:5000
  /// For physical device: use your computer's local IP
  // static const String fileServerUrl = 'http://10.0.2.2:5000';
  static const String fileServerUrl = 'http://192.168.1.30:5000';
}
