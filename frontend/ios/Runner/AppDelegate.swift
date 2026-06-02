import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Build +12 bisect: Maps ON, Impeller OFF (see Info.plist FLTEnableImpeller).
    // Codemagic sed replaces API_KEY_PLACEHOLDER before compile.
    let mapsApiKey = "API_KEY_PLACEHOLDER"
    if !mapsApiKey.isEmpty && !mapsApiKey.contains("PLACEHOLDER") {
      GMSServices.provideAPIKey(mapsApiKey)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Plugin registration for scene / implicit-engine Flutter apps (Flutter 3.16+).
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
