import 'package:flutter/material.dart';

class AppColors {
  // Main Color (Primary)
  // Navy Blue — #09182F
  // Represents trust, security, authority
  // Strong foundation for headers, app bars, buttons, map overlays
  // Works perfectly for dark mode base
  static const Color primary = Color(0xFF09182F);
  static const Color primaryHover = Color(0xFF152D52);

  // Secondary Color (Accent)
  // Teal — #00B3A4
  // Represents AI, technology, intelligence
  // Use for highlights, active states, icons, radar waves, links
  // Keeps it modern without looking flashy
  static const Color secondary = Color(0xFF00B3A4);

  // Supporting Neutrals
  // Light Background — #F4F8FF
  static const Color lightBackground = Color(0xFFF4F8FF);

  // White — #FFFFFF
  static const Color white = Color(0xFFFFFFFF);

  // Soft Gray — #E5EAF2
  static const Color softGray = Color(0xFFE5EAF2);

  // Dark Text — #1A1A1A
  static const Color darkText = Color(0xFF1A1A1A);

  // Additional neutral colors for UI
  static const Color lightGray = Color(0xFFF6F7F8);
  static const Color mediumGray = Color(0xFFE5EAF2);
  static const Color darkGray = Color(0xFF64748B);
  static const Color slateGray = Color(0xFF94A3B8);

  // Registration screen specific neutrals
  // Neutral-800 — slightly lighter than primary for inputs
  static const Color neutral800 = Color(0xFF162A4D);

  // Neutral-700 — border color
  static const Color neutral700 = Color(0xFF1E3A66);

  // Neutral-400 — placeholder text
  static const Color neutral400 = Color(0xFF94A3B8);

  // Neutral-300 — secondary text
  static const Color neutral300 = Color(0xFFCBD5E1);

  // Alert Status Colors
  // Danger/Error — Red
  static const Color danger = Color(0xFFEF4444);

  // Warning — Amber
  static const Color warning = Color(0xFFFBBF24);

  // Success — Green
  static const Color success = Color(0xFF10B981);

  // ==================== MAP STYLING ====================
  // Custom map styles for light and dark themes

  static const String darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#0d1e38"}]
    },
    {
      "elementType": "geometry.fill",
      "stylers": [{"color": "#0a1828"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b8ba0"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#09182F"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#1e3a66"}]
    },
    {
      "featureType": "administrative.country",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8eadc8"}]
    },
    {
      "featureType": "administrative.land_parcel",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#a8c0d8"}]
    },
    {
      "featureType": "administrative.neighborhood",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#7a9ab5"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b8ba0"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#1a6b6b"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#1d7a7a"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#2e7d5e"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#09182F"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#162d50"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#0d1e38"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8eadc8"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#09182F"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#1a3355"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#1e3a66"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#1e3a66"}]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [{"color": "#243f6e"}]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#122540"}]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#5a7a96"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#0f2040"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b8ba0"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0a4a8a"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#0d5099"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#2e5272"}]
    }
  ]
  ''';

  static const String lightMapStyle = '';
  // Empty string uses default Google Maps light style
}
