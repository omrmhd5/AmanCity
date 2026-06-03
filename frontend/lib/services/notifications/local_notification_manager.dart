import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationManager {
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static const channelId = 'nearby_alerts';
  static const channelName = 'Nearby Alerts';
  static const channelDesc = 'Alerts for incidents near your location';
  
  static const sosChannelId = 'sos_alerts';
  static const sosChannelName = 'SOS Alerts';
  static const sosChannelDesc = 'Emergency SOS alerts from trusted contacts';

  Future<void> init(void Function(String?) onNotificationTap) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Show notifications as banners/alerts even when app is in foreground
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );
    await plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap(details.payload);
      },
    );

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.high,
    );
    const sosChannel = AndroidNotificationChannel(
      sosChannelId,
      sosChannelName,
      description: sosChannelDesc,
      importance: Importance.max,
      playSound: true,
    );
    
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(sosChannel);
  }

  void showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? incidentType,
    bool isSos = false,
  }) {
    final chId = isSos ? sosChannelId : channelId;
    final chName = isSos ? sosChannelName : channelName;
    final chDesc = isSos ? sosChannelDesc : channelDesc;
    
    plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chId,
          chName,
          channelDescription: chDesc,
          importance: isSos ? Importance.max : Importance.high,
          priority: isSos ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
