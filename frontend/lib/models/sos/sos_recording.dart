class SosRecording {
  final String id;
  final String path;
  final int timestampMs;
  final int durationSeconds;
  final double? latitude;
  final double? longitude;

  const SosRecording({
    required this.id,
    required this.path,
    required this.timestampMs,
    required this.durationSeconds,
    this.latitude,
    this.longitude,
  });

  factory SosRecording.fromJson(Map<String, dynamic> json) {
    return SosRecording(
      id: json['id'] as String,
      path: json['path'] as String,
      timestampMs: json['timestampMs'] as int,
      durationSeconds: json['durationSeconds'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'timestampMs': timestampMs,
      'durationSeconds': durationSeconds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestampMs);
}
