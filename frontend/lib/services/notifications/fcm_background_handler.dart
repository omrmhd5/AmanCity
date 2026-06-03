import 'dart:convert';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/alerts/alert_notification.dart';
import 'notification_translator.dart';

Future<String> getLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // easy_localization key is normally 'locale'
    final savedLocale = prefs.getString('locale');
    if (savedLocale != null && savedLocale.isNotEmpty) {
      if (savedLocale.startsWith('ar')) return 'ar';
      if (savedLocale.startsWith('en')) return 'en';
    }
  } catch (_) {}
  // Fallback to system locale
  try {
    final systemLocale = PlatformDispatcher.instance.locale.languageCode;
    if (systemLocale == 'ar' || systemLocale == 'en') {
      return systemLocale;
    }
  } catch (_) {}
  return 'en';
}

/// Must be a top-level function — firebase_messaging requirement
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Flutter bindings are ready so platform plugins work in this isolate.
  WidgetsFlutterBinding.ensureInitialized();
  if (message.data['type'] == 'sos_alert') {
    await FlutterRingtonePlayer().playAlarm(looping: false, asAlarm: true);
  }

  // Persist the alert to SharedPreferences so it appears in the inbox
  // when the user opens the app (background + terminated both hit this).
  await persistBackgroundAlert(message);
}

/// Saves a background/terminated FCM message directly to SharedPreferences
/// using the same key and JSON format as NotificationService.
/// Covers ALL notification types including sos_ended.
Future<void> persistBackgroundAlert(RemoteMessage message) async {
  try {
    const prefsKey = 'notification_alerts';
    const maxAlerts = 50;
    final prefs = await SharedPreferences.getInstance();
    final type = message.data['type'] as String?;
    final n = message.notification;
    final String id;
    final String title;
    final String body;
    final AlertType alertType;

    final lang = await getLanguageCode();
    final translation = NotificationTranslator.translate(
      type: type ?? '',
      data: message.data,
      lang: lang,
      fallbackTitle: n?.title,
      fallbackBody: n?.body,
    );

    if (type == 'sos_ended') {
      // Use deterministic id — same as _handleSosEnded — so dedup catches it
      final sessionId = (message.data['sessionId'] as String?) ?? '';
      id = 'sos_ended_$sessionId';
      title = translation.key;
      body = translation.value;
      alertType = AlertType.sosEnded;
    } else {
      id = message.messageId ?? DateTime.now().toIso8601String();
      title = translation.key;
      body = translation.value;
      switch (type) {
        case 'sos_alert':
          alertType = AlertType.sosAlert;
          break;
        case 'contact_request':
        case 'contactRequest':
          alertType = AlertType.contactRequest;
          break;
        case 'contact_accepted':
        case 'contactAccepted':
          alertType = AlertType.contactAccepted;
          break;
        case 'nearbyIncident':
          alertType = AlertType.nearbyIncident;
          break;
        case 'hotspotEntry':
          alertType = AlertType.hotspotEntry;
          break;
        default:
          alertType = AlertType.system;
      }
    }

    final alert = AlertNotification(
      id: id,
      title: title,
      body: body,
      alertType: alertType,
      timestamp: DateTime.now(),
      distanceKm: message.data['distanceKm'] != null
          ? double.tryParse(message.data['distanceKm'].toString())
          : null,
      incidentId: message.data['incidentId'] as String?,
      incidentType: message.data['incidentType'] as String?,
      isRead: false,
    );

    // Honour the user's "clear all" — filter out alerts older than cleared_at
    const clearedAtKey = 'notification_cleared_at';
    final clearedAtRaw = prefs.getString(clearedAtKey);
    final clearedAt = clearedAtRaw != null
        ? DateTime.tryParse(clearedAtRaw)
        : null;

    final raw = prefs.getString(prefsKey);
    final List rawExisting = raw != null ? jsonDecode(raw) as List : [];
    final List existing = clearedAt != null
        ? rawExisting.where((e) {
            final ts = (e as Map<String, dynamic>)['timestamp'] as String?;
            if (ts == null) return false;
            final dt = DateTime.tryParse(ts);
            return dt != null && dt.isAfter(clearedAt);
          }).toList()
        : rawExisting;

    // Deduplicate: skip if this id was already written (e.g. FCM delivered twice)
    if (existing.any((e) => (e as Map<String, dynamic>)['id'] == alert.id)) {
      return;
    }
    final updated = [alert.toJson(), ...existing];
    if (updated.length > maxAlerts) updated.removeLast();
    await prefs.setString(prefsKey, jsonEncode(updated));

    // Persist/clear active SOS session so the main isolate can restore it on resume
    const sosPendingKey = 'pending_sos_session';
    if (type == 'sos_alert') {
      final sessionId = message.data['sessionId'] as String?;
      if (sessionId != null && sessionId.isNotEmpty) {
        await prefs.setString(
          sosPendingKey,
          jsonEncode({
            'sessionId': sessionId,
            'senderName': (message.data['triggerUserName'] as String?) ?? '',
            'senderPhone': (message.data['triggerUserPhone'] as String?) ?? '',
            'lat':
                double.tryParse(message.data['lat']?.toString() ?? '') ?? 0.0,
            'lng':
                double.tryParse(message.data['lng']?.toString() ?? '') ?? 0.0,
          }),
        );
      }
    } else if (type == 'sos_ended') {
      final sessionId = (message.data['sessionId'] as String?) ?? '';
      final pendingRaw = prefs.getString(sosPendingKey);
      if (pendingRaw != null) {
        try {
          final pendingJson = jsonDecode(pendingRaw) as Map<String, dynamic>;
          if (pendingJson['sessionId'] == sessionId) {
            await prefs.remove(sosPendingKey);
          }
        } catch (_) {}
      }
    }
  } catch (_) {}
}
