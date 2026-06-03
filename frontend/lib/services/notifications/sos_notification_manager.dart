import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../models/alerts/alert_notification.dart';
import '../../screens/sos/incoming_sos_alert_screen.dart';
import '../../utils/navigation_service.dart' as navigation;
import '../sos/sos_service.dart';
import '../../models/notifications/incoming_sos_session.dart';
import 'notification_storage.dart';
import 'local_notification_manager.dart';
import 'notification_translator.dart';

class SosNotificationManager {
  // Emits sessionId when that SOS session is marked safe/ended
  final ValueNotifier<String?> sosEndedNotifier = ValueNotifier<String?>(null);

  // Non-null while a remote SOS is active (cleared when the session ends).
  final ValueNotifier<IncomingSosSession?> activeIncomingSession =
      ValueNotifier(null);

  // Sessions that have already ended — guards against stale notification taps.
  final Set<String> endedSessionIds = {};

  // True while IncomingSosAlertScreen is in the navigator stack.
  bool _incomingScreenActive = false;

  void dismissIncomingAlert() {
    _incomingScreenActive = false;
  }

  void onIncomingAlertScreenClosed() {
    _incomingScreenActive = false;
  }

  void reopenIncomingAlert() {
    _incomingScreenActive = true;
  }

  void handleSosEnded(
    Map<String, dynamic> data,
    void Function(AlertNotification) addAlertCallback,
    String lang,
  ) {
    final sessionId = data['sessionId'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;

    SosService().stopAlertSound();
    FlutterRingtonePlayer().stop();
    sosEndedNotifier.value = sessionId;

    final translation = NotificationTranslator.translate(
      type: 'sos_ended',
      data: data,
      lang: lang,
    );

    addAlertCallback(
      AlertNotification(
        id: 'sos_ended_$sessionId',
        title: translation.key,
        body: translation.value,
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
    endedSessionIds.add(sessionId);
    if (activeIncomingSession.value?.sessionId == sessionId) {
      activeIncomingSession.value = null;
    }
    _incomingScreenActive = false;
    NotificationStorage.clearSosPendingSession(sessionId);
  }

  void handleSosAlert(
    Map<String, dynamic> data,
    LocalNotificationManager localManager,
    void Function(AlertNotification) addAlertCallback,
    String lang,
  ) {
    final sessionId = data['sessionId'] as String?;
    final name = (data['triggerUserName'] as String?) ?? '';
    final phone = (data['triggerUserPhone'] as String?) ?? '';
    final lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;
    if (sessionId == null || sessionId.isEmpty) return;

    // Guard: session already ended
    if (endedSessionIds.contains(sessionId)) return;
    // Guard: screen already showing
    if (activeIncomingSession.value?.sessionId == sessionId &&
        _incomingScreenActive) {
      return;
    }

    activeIncomingSession.value = IncomingSosSession(
      sessionId: sessionId,
      senderName: name,
      senderPhone: phone,
      lat: lat,
      lng: lng,
    );
    _incomingScreenActive = true;

    NotificationStorage.saveSosPendingSession(
      sessionId: sessionId,
      senderName: name,
      senderPhone: phone,
      lat: lat,
      lng: lng,
    );

    final translation = NotificationTranslator.translate(
      type: 'sos_alert',
      data: data,
      lang: lang,
    );

    localManager.showLocalNotification(
      title: translation.key,
      body: translation.value,
      payload: jsonEncode(data),
      isSos: true,
    );

    addAlertCallback(
      AlertNotification(
        id: 'sos_$sessionId',
        title: translation.key,
        body: translation.value,
        alertType: AlertType.sosAlert,
        timestamp: DateTime.now(),
      ),
    );

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

  void pushSosScreenIfNeeded() {
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

  Future<void> restorePendingSession() async {
    final session = await NotificationStorage.loadSosPendingSession(
      endedSessionIds,
    );
    if (session != null && activeIncomingSession.value == null) {
      activeIncomingSession.value = session;
    }
  }
}
