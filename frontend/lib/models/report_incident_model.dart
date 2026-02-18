/// Enum for incident categories in the report flow
enum IncidentCategory { harassment, suspicious, theft, medical, fire, other }

/// Enum for evidence types available when reporting
enum EvidenceType { photo, video, textOnly }

/// Simple location data class
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}
