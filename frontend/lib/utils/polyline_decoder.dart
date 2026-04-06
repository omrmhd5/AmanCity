import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility to decode Google's Polyline Algorithm Format
/// Reference: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
class PolylineDecoder {
  /// Decode a polyline string to list of LatLng coordinates
  static List<LatLng> decode(String polyline) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int result = 0;
      int shift = 0;

      // Decode latitude
      int byte;
      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decode longitude
      result = 0;
      shift = 0;
      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
