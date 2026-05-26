enum AlertType {
  nearbyIncident,
  hotspotEntry,
  contactRequest,
  contactAccepted,
  sosAlert,
  sosEnded,
  system,
}

class AlertNotification {
  final String id;
  final String title;
  final String body;
  final AlertType alertType;
  final DateTime timestamp;
  final double? distanceKm;
  final String? incidentId;
  final String? incidentType;
  bool isRead;

  AlertNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.alertType,
    required this.timestamp,
    this.distanceKm,
    this.incidentId,
    this.incidentType,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'alertType': alertType.name,
    'timestamp': timestamp.toIso8601String(),
    'distanceKm': distanceKm,
    'incidentId': incidentId,
    'incidentType': incidentType,
    'isRead': isRead,
  };

  factory AlertNotification.fromJson(Map<String, dynamic> json) =>
      AlertNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        alertType: AlertType.values.firstWhere(
          (e) => e.name == json['alertType'],
          orElse: () => AlertType.system,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        distanceKm: json['distanceKm'] != null
            ? (json['distanceKm'] as num).toDouble()
            : null,
        incidentId: json['incidentId'] as String?,
        incidentType: json['incidentType'] as String?,
        isRead: json['isRead'] as bool? ?? false,
      );
}
