import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

enum ConnectivityStatus { online, noInternet, serverDown }

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// Reactive state — listen with ValueListenableBuilder.
  final ValueNotifier<ConnectivityStatus> notifier = ValueNotifier(
    ConnectivityStatus.online,
  );

  // NOTE: health route is at /health (root), NOT under /api.
  static const _healthUrl = '${AppConfig.fileServerUrl}/health';
  static const _httpTimeout = Duration(seconds: 5);
  static const _pollInterval = Duration(seconds: 5);

  bool _bypassed = false;
  bool _checking = false;

  Timer? _pollTimer;
  StreamSubscription? _connectivitySub;

  // ── Public API ─────────────────────────────────────────────────────────────

  void init() {
    // 1. Subscribe to platform connectivity events for instant detection.
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (_) => _check(),
    );

    // 2. Periodic poll as a reliable fallback.
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

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _check() async {
    if (_bypassed) return;
    if (_checking) return; // debounce
    await _forceCheck();
  }

  Future<void> _forceCheck() async {
    _checking = true;
    try {
      // Step 1: internet reachability via TCP socket to Cloudflare DNS.
      bool hasInternet = false;
      try {
        final socket = await Socket.connect(
          '1.1.1.1',
          53,
          timeout: const Duration(seconds: 3),
        );
        socket.destroy();
        hasInternet = true;
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
    _pollTimer?.cancel();
    _connectivitySub?.cancel();
    notifier.dispose();
  }
}
