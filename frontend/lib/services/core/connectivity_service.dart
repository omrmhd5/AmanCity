import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

enum ConnectivityStatus { online, noInternet, serverDown }

class ConnectivityService with WidgetsBindingObserver {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// Reactive state — listen with ValueListenableBuilder.
  final ValueNotifier<ConnectivityStatus> notifier = ValueNotifier(
    ConnectivityStatus.online,
  );

  // NOTE: health route is at /health (root), NOT under /api.
  static const _healthUrl = '${AppConfig.fileServerUrl}/health';
  static const _httpTimeout = Duration(seconds: 5);
  // Poll every 4 s — keeps detection snappy on iOS where the stream can lag.
  static const _pollInterval = Duration(seconds: 4);

  bool _bypassed = false;
  bool _checking = false;

  Timer? _pollTimer;
  StreamSubscription? _connectivitySub;

  // ── Public API ─────────────────────────────────────────────────────────────

  void init() {
    // Register as a lifecycle observer so we re-check on every app resume.
    // This is the key fix for iOS: connectivity_plus's stream does NOT reliably
    // fire on iOS when Wi-Fi is toggled while the app is in the foreground.
    WidgetsBinding.instance.addObserver(this);

    // 1. Subscribe to platform connectivity events for instant detection.
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (_) => _check(),
    );

    // 2. Periodic poll as a reliable fallback (essential for iOS).
    _pollTimer = Timer.periodic(_pollInterval, (_) => _check());

    // 3. Immediate first check.
    _check();
  }

  /// Bypass connectivity checks during onboarding/permissions screens.
  void setBypass(bool value) {
    _bypassed = value;
    if (value) {
      notifier.value = ConnectivityStatus.online;
    } else {
      // Immediately run a real check when bypass is lifted.
      _forceCheck();
    }
  }

  /// Trigger an immediate re-check (e.g. from the Retry button).
  Future<void> retry() => _forceCheck();

  // ── WidgetsBindingObserver ─────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Force a connectivity re-check the instant the app comes back to the
    // foreground. This is what makes iOS react to Wi-Fi being toggled —
    // the platform stream often only fires AFTER the app is brought back.
    if (state == AppLifecycleState.resumed) {
      _forceCheck();
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _check() async {
    if (_bypassed) return;
    if (_checking) return; // debounce
    await _forceCheck();
  }

  Future<void> _forceCheck() async {
    _checking = true;
    try {
      // Step 1: internet reachability via DNS lookup.
      // This is much more reliable on iOS for detecting when the active interface drops.
      bool hasInternet = false;
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          hasInternet = true;
        }
      } catch (_) {
        hasInternet = false;
      }

      if (!hasInternet) {
        notifier.value = ConnectivityStatus.noInternet;
        return;
      }

      // Step 2: server reachability via HTTP health check.
      try {
        final response = await http
            .get(Uri.parse(_healthUrl))
            .timeout(_httpTimeout);
        if (response.statusCode == 200) {
          notifier.value = ConnectivityStatus.online;
        } else {
          notifier.value = ConnectivityStatus.serverDown;
        }
      } catch (_) {
        notifier.value = ConnectivityStatus.serverDown;
      }
    } finally {
      _checking = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _connectivitySub?.cancel();
    notifier.dispose();
  }
}
