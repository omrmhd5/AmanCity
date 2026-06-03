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

    // Set this class as the UNUserNotificationCenter delegate so we receive
    // foreground notification callbacks (willPresent) and can show banners.
    UNUserNotificationCenter.current().delegate = self

    // Register with APNs so the OS issues a device token.
    // firebase_messaging picks this up automatically, but being explicit is safer.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ─── APNs → FCM token bridge ───────────────────────────────────────────────
  // Called by iOS when APNs issues a device token.
  // firebase_messaging with method swizzling (default) handles this automatically,
  // but providing the explicit implementation prevents edge cases on some builds.
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
    print("APNs registration failed: \(error.localizedDescription)")
  }

  // ─── UNUserNotificationCenterDelegate ─────────────────────────────────────
  // Show notifications as banners + play sound even when the app is in the foreground.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.list, .banner, .sound, .badge])
  }

  // Handle the user tapping a notification (foreground or background).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }

  // ─── FlutterImplicitEngineBridge ──────────────────────────────────────────
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
