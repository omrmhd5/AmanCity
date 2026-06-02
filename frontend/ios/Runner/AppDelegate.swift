import Flutter
import UIKit
// import GoogleMaps — temporarily disabled for native boot rescue (see GMSServices below)

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TEMPORARY: Google Maps native init bypassed — can deadlock main thread at launch.
    // Re-enable after TestFlight confirms purple/login boot. Codemagic sed target:
    // let mapsApiKey = "API_KEY_PLACEHOLDER"
    // if !mapsApiKey.isEmpty && !mapsApiKey.contains("PLACEHOLDER") {
    //   GMSServices.provideAPIKey(mapsApiKey)
    // }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Plugin registration for scene / implicit-engine Flutter apps (Flutter 3.16+).
  /// Do not move to didFinishLaunching — use engineBridge.pluginRegistry here.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
