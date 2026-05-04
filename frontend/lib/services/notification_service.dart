import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/alert_notification.dart';

/// Must be a top-level function — firebase_messaging requirement
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart before this runs.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'nearby_alerts';
  static const _channelName = 'Nearby Alerts';
  static const _channelDesc = 'Alerts for incidents near your location';
  static const _prefsKey = 'notification_alerts';
  static const _maxAlerts = 50;

  final ValueNotifier<List<AlertNotification>> alerts = ValueNotifier([]);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  Future<void> init() async {
    // 1. Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Register top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Init flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // 4. Create the Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 5. Load persisted alerts
    await _loadFromPrefs();

    // 6. Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      _onMessageReceived(message);
      final n = message.notification;
      if (n != null) {
        showLocalNotification(
          title: n.title ?? 'Alert',
          body: n.body ?? '',
          payload: message.data['incidentId'],
          incidentType: message.data['incidentType'],
        );
      }
    });

    // 7. Tapped from background (app was minimised)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data['incidentId']);
    });

    // 8. App launched from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onMessageReceived(initial);
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
  // Local notification
  // -------------------------------------------------------------------------

  void showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? incidentType,
  }) {
    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
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
    _saveToPrefs();
  }

  void markAllRead() {
    final list = List<AlertNotification>.from(alerts.value);
    for (final a in list) {
      a.isRead = true;
    }
    alerts.value = list;
    unreadCount.value = 0;
    _saveToPrefs();
  }

  void clearAll() {
    alerts.value = [];
    unreadCount.value = 0;
    _saveToPrefs();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _onMessageReceived(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final alert = AlertNotification(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: n.title ?? 'Alert',
      body: n.body ?? '',
      alertType: _parseAlertType(message.data['type']),
      timestamp: DateTime.now(),
      distanceKm: message.data['distanceKm'] != null
          ? double.tryParse(message.data['distanceKm'].toString())
          : null,
      incidentId: message.data['incidentId'],
      incidentType: message.data['incidentType'],
    );
    final list = [alert, ...alerts.value];
    if (list.length > _maxAlerts) list.removeLast();
    alerts.value = list;
    _updateUnreadCount();
    _saveToPrefs();
  }

  AlertType _parseAlertType(String? type) {
    switch (type) {
      case 'nearbyIncident':
        return AlertType.nearbyIncident;
      case 'hotspotEntry':
        return AlertType.hotspotEntry;
      default:
        return AlertType.system;
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = alerts.value.where((a) => !a.isRead).length;
  }

  void _handleNotificationTap(String? incidentId) {
    // Future: navigate to incident detail via NavigationService
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final List decoded = jsonDecode(raw) as List;
      alerts.value = decoded
          .map((e) => AlertNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      _updateUnreadCount();
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(alerts.value.map((a) => a.toJson()).toList()),
      );
    } catch (_) {}
  }
}
