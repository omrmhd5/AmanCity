import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/alerts/alert_notification.dart';
import '../../models/notifications/incoming_sos_session.dart';

class NotificationStorage {
  static const prefsKey = 'notification_alerts';
  static const clearedAtKey = 'notification_cleared_at';
  static const sosPendingSessionKey = 'pending_sos_session';
  static const maxAlerts = 50;

  static Future<List<AlertNotification>> loadAlerts(DateTime? clearedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force re-read from disk

    final raw = prefs.getString(prefsKey);
    if (raw == null) return [];

    try {
      final List decoded = jsonDecode(raw) as List;
      var loaded = decoded
          .map((e) => AlertNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter out anything the user already cleared
      if (clearedAt != null) {
        loaded = loaded.where((a) => a.timestamp.isAfter(clearedAt)).toList();
      }

      return loaded;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAlerts(List<AlertNotification> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefsKey,
        jsonEncode(alerts.map((a) => a.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<DateTime?> loadClearedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final clearedAtRaw = prefs.getString(clearedAtKey);
    if (clearedAtRaw != null) {
      return DateTime.tryParse(clearedAtRaw);
    }
    return null;
  }

  static Future<void> saveClearedAt(DateTime? ts) async {
    if (ts == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(clearedAtKey, ts.toIso8601String());
    } catch (_) {}
  }

  static Future<IncomingSosSession?> loadSosPendingSession(
    Set<String> endedSessionIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sosRaw = prefs.getString(sosPendingSessionKey);
      if (sosRaw != null) {
        final json = jsonDecode(sosRaw) as Map<String, dynamic>;
        final sessionId = json['sessionId'] as String?;
        if (sessionId != null && !endedSessionIds.contains(sessionId)) {
          return IncomingSosSession(
            sessionId: sessionId,
            senderName: (json['senderName'] as String?) ?? '',
            senderPhone: (json['senderPhone'] as String?) ?? '',
            lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
            lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveSosPendingSession({
    required String sessionId,
    required String senderName,
    required String senderPhone,
    required double lat,
    required double lng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        sosPendingSessionKey,
        jsonEncode({
          'sessionId': sessionId,
          'senderName': senderName,
          'senderPhone': senderPhone,
          'lat': lat,
          'lng': lng,
        }),
      );
    } catch (_) {}
  }

  static Future<void> clearSosPendingSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(sosPendingSessionKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['sessionId'] == sessionId) {
        await prefs.remove(sosPendingSessionKey);
      }
    } catch (_) {}
  }
}
