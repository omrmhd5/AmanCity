class OsintIncident {
  final String id;
  final String title;
  final String type;
  final String locationText;
  final double latitude;
  final double longitude;
  final double osintConfidence; // 0.0 - 1.0
  final String locationPrecision; // "EXACT" or "VAGUE"
  final List<String> sourceUrls; // Twitter/X URLs
  final DateTime timestamp;

  OsintIncident({
    required this.id,
    required this.title,
    required this.type,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    required this.osintConfidence,
    required this.locationPrecision,
    required this.sourceUrls,
    required this.timestamp,
  });

  /// Convert timestamp to "time ago" format
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  /// Parse from JSON response
  factory OsintIncident.fromJson(Map<String, dynamic> json) {
    return OsintIncident(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'Unknown',
      locationText: json['location'] ?? 'Unknown Location',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      osintConfidence: (json['osintConfidence'] as num?)?.toDouble() ?? 0.0,
      locationPrecision: json['locationPrecision'] ?? 'VAGUE',
      sourceUrls: List<String>.from(json['sourceUrls'] ?? []),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
