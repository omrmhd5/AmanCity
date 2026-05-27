import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../models/alerts/alert_notification.dart';
import '../../screens/sos/incoming_sos_alert_screen.dart';
import '../../utils/navigation_service.dart' as navigation;
import '../sos/sos_service.dart';

/// Must be a top-level function — firebase_messaging requirement
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Flutter bindings are ready so platform plugins work in this isolate.
  WidgetsFlutterBinding.ensureInitialized();
  if (message.data['type'] == 'sos_alert') {
    await FlutterRingtonePlayer().playAlarm(looping: false);
  }

  // Persist the alert to SharedPreferences so it appears in the inbox
  // when the user opens the app (background + terminated both hit this).
  await _persistBackgroundAlert(message);
}

/// Saves a background/terminated FCM message directly to SharedPreferences
/// using the same key and JSON format as NotificationService.
/// Covers ALL notification types including sos_ended.
Future<void> _persistBackgroundAlert(RemoteMessage message) async {
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

    if (type == 'sos_ended') {
      // Use deterministic id — same as _handleSosEnded — so dedup catches it
      final sessionId = (message.data['sessionId'] as String?) ?? '';
      final name = (message.data['triggerUserName'] as String?) ?? '';
      id = 'sos_ended_$sessionId';
      title = '✅ ${name.isNotEmpty ? name : "A contact"} is now safe';
      body = 'They have cancelled their SOS alert.';
      alertType = AlertType.sosEnded;
    } else {
      id = message.messageId ?? DateTime.now().toIso8601String();
      title = n?.title ?? message.data['title'] as String? ?? 'Alert';
      body = n?.body ?? message.data['body'] as String? ?? '';
      switch (type) {
        case 'sos_alert':
          alertType = AlertType.sosAlert;
          break;
        case 'contact_request':
          alertType = AlertType.contactRequest;
          break;
        case 'contact_accepted':
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
    if (existing.any((e) => (e as Map<String, dynamic>)['id'] == alert.id))
      return;
    final updated = [alert.toJson(), ...existing];
    if (updated.length > maxAlerts) updated.removeLast();
    await prefs.setString(prefsKey, jsonEncode(updated));

    // Persist/clear active SOS session so the main isolate can restore it on resume
    const sosPendingKey = 'pending_sos_session';
    if (type == 'sos_alert') {
      final sessionId = message.data['sessionId'] as String?;
      if (sessionId != null && sessionId.isNotEmpty) {
        await prefs.setString(sosPendingKey, jsonEncode({
          'sessionId': sessionId,
          'senderName': (message.data['triggerUserName'] as String?) ?? '',
          'senderPhone': (message.data['triggerUserPhone'] as String?) ?? '',
          'lat': double.tryParse(message.data['lat']?.toString() ?? '') ?? 0.0,
          'lng': double.tryParse(message.data['lng']?.toString() ?? '') ?? 0.0,
        }));
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

class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'nearby_alerts';
  static const _channelName = 'Nearby Alerts';
  static const _channelDesc = 'Alerts for incidents near your location';
  static const _sosChannelId = 'sos_alerts';
  static const _sosChannelName = 'SOS Alerts';
  static const _sosChannelDesc = 'Emergency SOS alerts from trusted contacts';
  static const _prefsKey = 'notification_alerts';
  static const _clearedAtKey = 'notification_cleared_at';
  static const _sosPendingSessionKey = 'pending_sos_session';
  static const _maxAlerts = 50;

  // In-memory copy of the last explicit clear time (also persisted via _clearedAtKey)
  DateTime? _clearedAt;

  final ValueNotifier<List<AlertNotification>> alerts = ValueNotifier([]);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  // Emits sessionId when that SOS session is marked safe/ended
  final sosEndedNotifier = ValueNotifier<String?>(null);

  // ---- Incoming SOS re-access state ----------------------------------------
  // Non-null while a remote SOS is active (cleared when the session ends).
  final ValueNotifier<IncomingSosSession?> activeIncomingSession =
      ValueNotifier(null);
  // Sessions that have already ended — guards against stale notification taps.
  final Set<String> _endedSessionIds = {};
  // True while IncomingSosAlertScreen is in the navigator stack.
  bool _incomingScreenActive = false;

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

    // 4. Create Android notification channels
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    const sosChannel = AndroidNotificationChannel(
      _sosChannelId,
      _sosChannelName,
      description: _sosChannelDesc,
      importance: Importance.max,
      playSound: true,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(sosChannel);

    // 5. Load persisted alerts + register lifecycle observer so we re-sync
    //    with SharedPreferences when the app returns from background
    await _loadFromPrefs();
    WidgetsBinding.instance.addObserver(this);

    // 6. Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['type'] as String?;
      if (type == 'sos_alert') {
        _handleSosAlert(message.data);
        return; // Skip local notification — we show full-screen UI
      }
      if (type == 'sos_ended') {
        _handleSosEnded(message.data);
        return;
      }
      _onMessageReceived(message);
      final n = message.notification;
      if (n != null) {
        showLocalNotification(
          title: n.title ?? 'Alert',
          body: n.body ?? '',
          payload: _buildPayload(message.data),
          incidentType: message.data['incidentType'],
        );
      }
    });

    // 7. Tapped from background (app was minimised)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageTap(message.data);
      _onMessageReceived(message); // ensure it lands in the inbox
    });

    // 8. App launched from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleMessageTap(initial.data);
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
    bool isSos = false,
  }) {
    final channelId = isSos ? _sosChannelId : _channelId;
    final channelName = isSos ? _sosChannelName : _channelName;
    final channelDesc = isSos ? _sosChannelDesc : _channelDesc;
    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: isSos ? Importance.max : Importance.high,
          priority: isSos ? Priority.max : Priority.high,
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
    _clearedAt = DateTime.now();
    alerts.value = [];
    unreadCount.value = 0;
    _saveToPrefs();
    _saveClearedAt();
  }

  /// Call when the user presses Ignore on the incoming SOS screen.
  void dismissIncomingAlert() {
    _incomingScreenActive = false;
  }

  /// Call from IncomingSosAlertScreen.dispose() to track that the screen
  /// is no longer in the navigator stack.
  void onIncomingAlertScreenClosed() {
    _incomingScreenActive = false;
  }

  /// Call when re-opening the incoming SOS alert from the tile in SosScreen.
  void reopenIncomingAlert() {
    _incomingScreenActive = true;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _onMessageReceived(RemoteMessage message) {
    final n = message.notification;
    // Use notification fields if available, fall back to data payload
    final title = n?.title ?? message.data['title'] as String?;
    final body = n?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;
    final alert = AlertNotification(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: title ?? 'Alert',
      body: body ?? '',
      alertType: _parseAlertType(message.data['type']),
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
    // Skip if we already have this alert (background handler may have already persisted it)
    if (alerts.value.any((a) => a.id == alert.id)) return;
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

  void _handleMessageTap(Map<String, dynamic> data) {
    // SOS types: notification tap just opens the app.
    // State (tile visibility, active session) is fully governed by
    // pending_sos_session in SharedPreferences via _onAppResumed → _loadFromPrefs.
    // Future: handle incidentId tap → navigate to incident detail
  }

  void _handleSosEnded(Map<String, dynamic> data) {
    final sessionId = data['sessionId'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;
    SosService().stopAlertSound();
    FlutterRingtonePlayer().stop();
    sosEndedNotifier.value = sessionId;
    final name = (data['triggerUserName'] as String?) ?? '';
    _addAlert(
      AlertNotification(
        id: 'sos_ended_$sessionId',
        title: '✅ ${name.isNotEmpty ? name : "A contact"} is now safe',
        body: 'They have cancelled their SOS alert.',
        alertType: AlertType.sosEnded,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );

    // Reset so the same sessionId can trigger again if needed
    Future.delayed(const Duration(seconds: 1), () {
      if (sosEndedNotifier.value == sessionId) sosEndedNotifier.value = null;
    });

    // Clear incoming SOS state for this session
    _endedSessionIds.add(sessionId);
    if (activeIncomingSession.value?.sessionId == sessionId) {
      activeIncomingSession.value = null;
    }
    _incomingScreenActive = false;
    _clearSosPendingSession(sessionId);
  }

  void _handleSosAlert(Map<String, dynamic> data) {
    final sessionId = data['sessionId'] as String?;
    final name = (data['triggerUserName'] as String?) ?? '';
    final phone = (data['triggerUserPhone'] as String?) ?? '';
    final lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;
    if (sessionId == null || sessionId.isEmpty) return;

    // Guard: session already ended — ignore stale notification
    if (_endedSessionIds.contains(sessionId)) return;
    // Guard: screen is already showing for this session — no duplicate push
    if (activeIncomingSession.value?.sessionId == sessionId &&
        _incomingScreenActive)
      return;

    // Track this as the active incoming session
    activeIncomingSession.value = IncomingSosSession(
      sessionId: sessionId,
      senderName: name,
      senderPhone: phone,
      lat: lat,
      lng: lng,
    );
    _incomingScreenActive = true;
    _saveSosPendingSession(
        sessionId: sessionId,
        senderName: name,
        senderPhone: phone,
        lat: lat,
        lng: lng);

    // Fire a high-priority local notification so the user always hears/sees it
    showLocalNotification(
      title: '🆘 ${name.isNotEmpty ? name : "A contact"} is in danger!',
      body: 'Tap to view their live location and call for help.',
      payload: jsonEncode(data),
      isSos: true,
    );

    // Add to alerts inbox
    _addAlert(
      AlertNotification(
        id: 'sos_${sessionId}',
        title: '🆘 ${name.isNotEmpty ? name : "A contact"} is in danger!',
        body: 'Tap to view their live location and call for help.',
        alertType: AlertType.sosAlert,
        timestamp: DateTime.now(),
      ),
    );

    // Play the custom siren (foreground only — background uses system alarm via FCM handler)
    // Stop the phone alarm first in case this path was reached via notification tap.
    FlutterRingtonePlayer().stop();
    SosService().playAlertSound();

    navigation.Navigator.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingSosAlertScreen(
          sessionId: sessionId,
          triggerUserName: name,
          triggerUserPhone: phone,
          lat: lat,
          lng: lng,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  String? _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'sos_alert') return jsonEncode(data);
    return data['incidentId'] as String?;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    // Try to parse as JSON (SOS alert payload)
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleMessageTap(data);
    } catch (_) {
      // Plain incidentId string — future: navigate to incident detail
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app comes to the foreground, re-read SharedPreferences.
    // The background isolate may have written new alerts while the app was paused.
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  // Awaits prefs load (which restores activeIncomingSession) before checking.
  Future<void> _onAppResumed() async {
    FlutterRingtonePlayer().stop();
    await _loadFromPrefs();

    // If an active SOS session was restored from prefs and the screen isn't
    // already in the stack, push it now so the receiver sees it immediately.
    final session = activeIncomingSession.value;
    if (session != null && !_incomingScreenActive) {
      _incomingScreenActive = true;
      SosService().playAlertSound();
      navigation.Navigator.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingSosAlertScreen(
            sessionId: session.sessionId,
            triggerUserName: session.senderName,
            triggerUserPhone: session.senderPhone,
            lat: session.lat,
            lng: session.lng,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Force re-read from disk so we pick up what the background isolate wrote.
      await prefs.reload();

      // Restore the cleared_at boundary (needed after app restart).
      final clearedAtRaw = prefs.getString(_clearedAtKey);
      if (clearedAtRaw != null) {
        _clearedAt = DateTime.tryParse(clearedAtRaw) ?? _clearedAt;
      }

      // Restore active incoming SOS session written by the background isolate.
      // Must run before the early-return below so it works even with no stored alerts.
      final sosRaw = prefs.getString(_sosPendingSessionKey);
      if (sosRaw != null && activeIncomingSession.value == null) {
        try {
          final json = jsonDecode(sosRaw) as Map<String, dynamic>;
          final sessionId = json['sessionId'] as String?;
          if (sessionId != null && !_endedSessionIds.contains(sessionId)) {
            activeIncomingSession.value = IncomingSosSession(
              sessionId: sessionId,
              senderName: (json['senderName'] as String?) ?? '',
              senderPhone: (json['senderPhone'] as String?) ?? '',
              lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
              lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
            );
          }
        } catch (_) {}
      }

      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final List decoded = jsonDecode(raw) as List;
      var loaded = decoded
          .map((e) => AlertNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter out anything the user already cleared.
      final clearedAt = _clearedAt;
      if (clearedAt != null) {
        loaded = loaded.where((a) => a.timestamp.isAfter(clearedAt)).toList();
      }

      alerts.value = loaded;
      _updateUnreadCount();
      // Re-save to disk to actually delete the filtered-out (old) alerts.
      // This frees up storage instead of just hiding them.
      await _saveToPrefs();
    } catch (_) {}
  }

  Future<void> _saveClearedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _clearedAt;
      if (ts != null) {
        await prefs.setString(_clearedAtKey, ts.toIso8601String());
      }
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

  Future<void> _saveSosPendingSession({
    required String sessionId,
    required String senderName,
    required String senderPhone,
    required double lat,
    required double lng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sosPendingSessionKey, jsonEncode({
        'sessionId': sessionId,
        'senderName': senderName,
        'senderPhone': senderPhone,
        'lat': lat,
        'lng': lng,
      }));
    } catch (_) {}
  }

  Future<void> _clearSosPendingSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sosPendingSessionKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['sessionId'] == sessionId) {
        await prefs.remove(_sosPendingSessionKey);
      }
    } catch (_) {}
  }
}
