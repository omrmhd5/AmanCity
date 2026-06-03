import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/alerts/alert_notification.dart';

import 'fcm_background_handler.dart';
import 'local_notification_manager.dart';
import '../../models/notifications/incoming_sos_session.dart';
import 'notification_storage.dart';
import 'sos_notification_manager.dart';
import 'notification_translator.dart';

export 'fcm_background_handler.dart';
export 'local_notification_manager.dart';
export '../../models/notifications/incoming_sos_session.dart';
export 'notification_storage.dart';
export 'sos_notification_manager.dart';

class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final LocalNotificationManager _localManager = LocalNotificationManager();
  final SosNotificationManager _sosManager = SosNotificationManager();

  static const _maxAlerts = 50;
  DateTime? _clearedAt;

  final ValueNotifier<List<AlertNotification>> alerts = ValueNotifier([]);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  // Expose SOS managers properties to maintain backward compatibility
  ValueNotifier<String?> get sosEndedNotifier => _sosManager.sosEndedNotifier;
  ValueNotifier<IncomingSosSession?> get activeIncomingSession =>
      _sosManager.activeIncomingSession;

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  Future<void> init() async {
    // 1. Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Register top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Init local notifications
    await _localManager.init(_handleNotificationTap);

    // 4. Load persisted alerts & lifecycle observer
    await _loadFromPrefs();
    WidgetsBinding.instance.addObserver(this);

    // 5. Foreground message handler
    FirebaseMessaging.onMessage.listen((message) async {
      final type = message.data['type'] as String?;
      final lang = await getLanguageCode();

      if (type == 'sos_alert') {
        _sosManager.handleSosAlert(message.data, _localManager, _addAlert, lang);
        return;
      }
      if (type == 'sos_ended') {
        _sosManager.handleSosEnded(message.data, _addAlert, lang);
        return;
      }

      await _onMessageReceived(message, lang);
      final n = message.notification;
      if (n != null) {
        final translation = NotificationTranslator.translate(
          type: type ?? '',
          data: message.data,
          lang: lang,
        );
        _localManager.showLocalNotification(
          title: translation.key,
          body: translation.value,
          payload: _buildPayload(message.data),
          incidentType: message.data['incidentType'],
        );
      }
    });

    // 6. Tapped from background (app was minimised)
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      final lang = await getLanguageCode();
      _handleMessageTap(message.data);
      await _onMessageReceived(message, lang);
    });

    // 7. App launched from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final lang = await getLanguageCode();
      _handleMessageTap(initial.data);
      await _onMessageReceived(initial, lang);
    }
  }

  // -------------------------------------------------------------------------
  // FCM token
  // -------------------------------------------------------------------------

  Future<void> updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      await http.put(
        Uri.parse('${AppConfig.backendUrl}/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (_) {
      // Non-fatal
    }
  }

  // -------------------------------------------------------------------------
  // Local notification delegation
  // -------------------------------------------------------------------------

  void showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? incidentType,
    bool isSos = false,
  }) {
    _localManager.showLocalNotification(
      title: title,
      body: body,
      payload: payload,
      incidentType: incidentType,
      isSos: isSos,
    );
  }

  // -------------------------------------------------------------------------
  // Read / clear
  // -------------------------------------------------------------------------

  void markRead(String id) {
    final list = List<AlertNotification>.from(alerts.value);
    for (final a in list) {
      if (a.id == id) a.isRead = true;
    }
    alerts.value = list;
    _updateUnreadCount();
    NotificationStorage.saveAlerts(alerts.value);
  }

  void markAllRead() {
    final list = List<AlertNotification>.from(alerts.value);
    for (final a in list) {
      a.isRead = true;
    }
    alerts.value = list;
    unreadCount.value = 0;
    NotificationStorage.saveAlerts(alerts.value);
  }

  void clearAll() {
    _clearedAt = DateTime.now();
    alerts.value = [];
    unreadCount.value = 0;
    NotificationStorage.saveAlerts(alerts.value);
    NotificationStorage.saveClearedAt(_clearedAt);
  }

  // SOS delegation
  void dismissIncomingAlert() => _sosManager.dismissIncomingAlert();
  void onIncomingAlertScreenClosed() =>
      _sosManager.onIncomingAlertScreenClosed();
  void reopenIncomingAlert() => _sosManager.reopenIncomingAlert();

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<void> _onMessageReceived(RemoteMessage message, String lang) async {
    final type = message.data['type'] as String?;
    final translation = NotificationTranslator.translate(
      type: type ?? '',
      data: message.data,
      lang: lang,
    );

    final alert = AlertNotification(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: translation.key,
      body: translation.value,
      alertType: _parseAlertType(type),
      timestamp: DateTime.now(),
      distanceKm: message.data['distanceKm'] != null
          ? double.tryParse(message.data['distanceKm'].toString())
          : null,
      incidentId: message.data['incidentId'],
      incidentType: message.data['incidentType'],
    );
    _addAlert(alert);
  }

  void _addAlert(AlertNotification alert) {
    if (alerts.value.any((a) => a.id == alert.id)) return;
    final list = [alert, ...alerts.value];
    if (list.length > _maxAlerts) list.removeLast();
    alerts.value = list;
    _updateUnreadCount();
    NotificationStorage.saveAlerts(alerts.value);
  }

  AlertType _parseAlertType(String? type) {
    switch (type) {
      case 'nearbyIncident':
        return AlertType.nearbyIncident;
      case 'hotspotEntry':
        return AlertType.hotspotEntry;
      case 'contactRequest':
      case 'contact_request':
        return AlertType.contactRequest;
      case 'contactAccepted':
      case 'contact_accepted':
        return AlertType.contactAccepted;
      case 'sos_alert':
        return AlertType.sosAlert;
      case 'sos_ended':
        return AlertType.sosEnded;
      default:
        return AlertType.system;
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = alerts.value.where((a) => !a.isRead).length;
  }

  void _handleMessageTap(Map<String, dynamic> data) {}

  String? _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'sos_alert') return jsonEncode(data);
    return data['incidentId'] as String?;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleMessageTap(data);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  Future<void> _onAppResumed() async {
    FlutterRingtonePlayer().stop();
    await _loadFromPrefs();
    _sosManager.pushSosScreenIfNeeded();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final cleared = await NotificationStorage.loadClearedAt();
      if (cleared != null) _clearedAt = cleared;

      await _sosManager.restorePendingSession();

      alerts.value = await NotificationStorage.loadAlerts(_clearedAt);
      _updateUnreadCount();

      await NotificationStorage.saveAlerts(alerts.value); // cleans up expired
    } catch (_) {}
  }
}
