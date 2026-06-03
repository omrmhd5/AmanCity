import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/map/hotspot_zone.dart';
import '../map/directions_service.dart';

class SafeRouteHomeResult {
  final bool routeFound;
  final String? googleMapsUrl;
  final double? dangerScore;
  final String? distance;
  final String? duration;
  final String? homeAddress;
  final String? errorMessage;

  SafeRouteHomeResult({
    this.routeFound = false,
    this.googleMapsUrl,
    this.dangerScore,
    this.distance,
    this.duration,
    this.homeAddress,
    this.errorMessage,
  });
}

class SafeRouteHomeService {
  /// Keywords that trigger route home detection
  static const List<String> homeKeywords = [
    // English
    'safest route home',
    'route home',
    'get home safe',
    'home safely',
    'go home safe',
    'get me home',
    'navigate home',
    'safe route home',
    'way home',
    // Arabic - بيت variants
    'البيت',
    'بيتي',
    'أعود للبيت',
    'أعود إلى البيت',
    'طريق آمن للبيت',
    'طريقة آمنة للبيت',
    'للبيت',
    // Arabic - منزل variants (used by quick prompt: "أأمن طريق للمنزل")
    'المنزل',
    'منزلي',
    'للمنزل',
    'إلى المنزل',
    'أعود للمنزل',
    'أعود إلى المنزل',
    'طريق آمن للمنزل',
    'طريقة آمنة للمنزل',
    'أأمن طريق للمنزل',
    // Arabic - general safe route keywords
    'أمن طريق',
    'طريق أمن',
    'مسار آمن',
  ];

  /// Detect if message is asking for route home
  static bool isRouteHomeRequest(String message) {
    final lowerMessage = message.toLowerCase().trim();
    return homeKeywords.any(
      (keyword) => lowerMessage.contains(keyword.toLowerCase()),
    );
  }

  /// Returns true if the message appears to be in Arabic
  static bool _isArabic(String message) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(message);
  }

  /// Returns the "no home set" message for Gemini, in the right language
  static String noHomeMessage(String userMessage) {
    if (_isArabic(userMessage)) {
      return 'المستخدم طلب أأمن طريق للمنزل، لكنه لم يحدد موقع منزله بعد. '
          'قل له بالعربية أن يحدد موقع منزله من إعدادات الملف الشخصي (تبويب "الملف") '
          'حتى نتمكن من حساب أأمن مسار له.';
    }
    return 'User requested the safest route home, but they have no home location set. '
        'Tell them to set it in the Settings (under the Profile tab) first so we can calculate the safest route.';
  }

  /// Returns the Gemini context message when a route IS found, in the right language
  static String routeFoundMessage({
    required String userMessage,
    required double dangerScore,
    required String? distance,
    required String? duration,
    required String homeAddress,
  }) {
    final distanceStr = distance ?? '';
    final durationStr = duration ?? '';

    if (_isArabic(userMessage)) {
      final String riskLevel = dangerScore < 0.2
          ? 'آمن'
          : dangerScore < 0.4
              ? 'متوسط الخطورة'
              : 'عالي الخطورة';
      return 'تم حساب أأمن مسار للمنزل: $distanceStr ($durationStr). '
          'المسار يمر عبر منطقة $riskLevel. '
          'قدّم نصائح سلامة بالعربية للتنقل إلى $homeAddress.';
    }

    final String riskLevel = dangerScore < 0.2
        ? 'safe'
        : dangerScore < 0.4
            ? 'moderately risky'
            : 'high danger';
    return 'I have calculated the safest route home: $distanceStr away ($durationStr). '
        'The route passes through a $riskLevel area. '
        'Please provide safety tips for traveling this route to $homeAddress.';
  }

  /// Check if the user has a saved home location
  static Future<bool> hasSavedHomeLocation() async {
    final loc = await _getHomeLocation();
    return loc != null;
  }

  /// Load home location from SharedPreferences
  static Future<LatLng?> _getHomeLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('home_location_lat');
      final lng = prefs.getDouble('home_location_lng');

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('Error loading home location: $e');
    }
    return null;
  }

  /// Get home address from SharedPreferences
  static Future<String?> _getHomeAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('home_location_address');
    } catch (e) {
      return null;
    }
  }

  /// Sample waypoints from polyline (max 8 intermediate points)
  static List<String> _sampleWaypoints(List<LatLng> points) {
    if (points.length <= 2) return [];

    final waypointCount = 8;
    final sampleRate = (points.length / (waypointCount + 1)).ceil();
    final waypoints = <String>[];

    for (int i = sampleRate; i < points.length - 1; i += sampleRate) {
      if (waypoints.length < waypointCount) {
        waypoints.add('${points[i].latitude},${points[i].longitude}');
      }
    }

    return waypoints;
  }

  /// Detect route home request and calculate safe route
  static Future<SafeRouteHomeResult> detectAndCalculateRouteHome(
    String message,
    LatLng userLocation,
    List<HotspotZone> hotspots,
  ) async {
    try {
      // Check if message is asking for route home
      if (!isRouteHomeRequest(message)) {
        return SafeRouteHomeResult(routeFound: false);
      }

      // Load saved home location
      final homeLocation = await _getHomeLocation();
      if (homeLocation == null) {
        return SafeRouteHomeResult(
          routeFound: false,
          errorMessage: 'No home location saved. Please set it in Settings.',
        );
      }

      // Get home address
      final homeAddress = await _getHomeAddress();

      // Calculate safe route
      final routeData = await DirectionsService.getSafeRoute(
        userLocation,
        homeLocation,
        hotspots,
      );

      final points = routeData['points'] as List<LatLng>;
      final dangerScore = routeData['dangerScore'] as double;
      final distance = routeData['distance'] as String?;
      final duration = routeData['duration'] as String?;

      // Sample waypoints from polyline
      final waypoints = _sampleWaypoints(points);

      // Build Google Maps URL
      String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&origin=${userLocation.latitude},${userLocation.longitude}&destination=${homeLocation.latitude},${homeLocation.longitude}&travelmode=driving';

      if (waypoints.isNotEmpty) {
        googleMapsUrl += '&waypoints=${waypoints.join('|')}';
      }

      return SafeRouteHomeResult(
        routeFound: true,
        googleMapsUrl: googleMapsUrl,
        dangerScore: dangerScore,
        distance: distance,
        duration: duration,
        homeAddress: homeAddress ?? 'Home',
      );
    } catch (e) {
      print('Error calculating route home: $e');
      return SafeRouteHomeResult(
        routeFound: false,
        errorMessage: 'Error calculating route: ${e.toString()}',
      );
    }
  }
}
