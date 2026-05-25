class SosSessionInfo {
  final String sessionId;
  final String triggerUserName;
  final String triggerUserPhone;
  final double lat;
  final double lng;
  final bool active;
  final DateTime updatedAt;

  const SosSessionInfo({
    required this.sessionId,
    required this.triggerUserName,
    required this.triggerUserPhone,
    required this.lat,
    required this.lng,
    required this.active,
    required this.updatedAt,
  });

  factory SosSessionInfo.fromJson(Map<String, dynamic> json, String sessionId) {
    final user = (json['triggerUser'] as Map<String, dynamic>?) ?? {};
    return SosSessionInfo(
      sessionId: sessionId,
      triggerUserName: (user['name'] as String?) ?? '',
      triggerUserPhone: (user['phone'] as String?) ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      active: (json['active'] as bool?) ?? false,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  SosSessionInfo copyWith({
    double? lat,
    double? lng,
    bool? active,
    DateTime? updatedAt,
  }) {
    return SosSessionInfo(
      sessionId: sessionId,
      triggerUserName: triggerUserName,
      triggerUserPhone: triggerUserPhone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
