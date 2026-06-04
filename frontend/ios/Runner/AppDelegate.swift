import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps
    let mapsApiKey = "API_KEY_PLACEHOLDER"
    if !mapsApiKey.isEmpty && !mapsApiKey.contains("PLACEHOLDER") {
      GMSServices.provideAPIKey(mapsApiKey)
    }

    // Set ourselves as UNUserNotificationCenterDelegate BEFORE super so we own
    // the delegate slot and Firebase does not compete for it.
    UNUserNotificationCenter.current().delegate = self

    // Register with APNs. In a scene-based app this may not happen automatically.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ─── APNs token → FCM ──────────────────────────────────────────────────────
  // Bridge the device token to Firebase so FCM can send to this device.
  // Required in scene-based apps where Firebase swizzling may be bypassed.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[FCM] APNs registration failed: \(error.localizedDescription)")
  }

  // ─── Background / data-only messages ───────────────────────────────────────
  // Called when a notification arrives while the app is in the BACKGROUND
  // (minimised) AND for data-only / content-available messages at all times.
  // Without this, background data messages never reach the Firebase Flutter
  // plugin and therefore never fire onMessage / onBackgroundMessage in Dart.
  // See: https://firebase.google.com/docs/cloud-messaging/ios/receive-messages
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Tell Firebase about this message — required per official documentation.
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler(.newData)
  }

  // ─── UNUserNotificationCenterDelegate ──────────────────────────────────────

  // Called when a notification arrives while the app is in the FOREGROUND.
  // Per Firebase docs: call appDidReceiveMessage so Firebase knows the message
  // arrived — this is what triggers FirebaseMessaging.onMessage in Dart.
  // Then call completionHandler with presentation options to show the banner.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    // Notify Firebase — fires onMessage in the Flutter Dart side.
    Messaging.messaging().appDidReceiveMessage(userInfo)

    // Show the system banner + play sound + update badge in foreground.
    // Without this, iOS silently swallows the notification while app is open.
    completionHandler([.list, .banner, .sound, .badge])
  }

  // Called when the user TAPS a notification (foreground or background).
  // Notifying Firebase here enables onMessageOpenedApp to fire in Dart.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler()
  }

  // ─── FlutterImplicitEngineBridge ───────────────────────────────────────────
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
