/// Holds the data for an active incoming SOS session so the UI can re-open
/// the alert screen without requiring a new FCM message.
class IncomingSosSession {
  final String sessionId;
  final String senderName;
  final String senderPhone;
  final double lat;
  final double lng;

  const IncomingSosSession({
    required this.sessionId,
    required this.senderName,
    required this.senderPhone,
    required this.lat,
    required this.lng,
  });
}
