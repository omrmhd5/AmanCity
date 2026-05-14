import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

/// Listens to GPS and PUTs the user's location to the backend
/// whenever they move more than 10m from the last synced position.
class UserLocationSyncService {
  UserLocationSyncService._();
  static final UserLocationSyncService instance = UserLocationSyncService._();

  StreamSubscription<Position>? _sub;
  Position? _lastSynced;

  static const _syncThresholdMeters = 10.0;

  void start() {
    _sub ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        // Wake up every 5m move to check the 10m sync threshold
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  // -------------------------------------------------------------------------

  Future<void> _onPosition(Position pos) async {
    if (_lastSynced != null) {
      final dist = Geolocator.distanceBetween(
        _lastSynced!.latitude,
        _lastSynced!.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (dist < _syncThresholdMeters) return;
    }
    _lastSynced = pos;
    await _sendToBackend(pos.latitude, pos.longitude);
  }

  Future<void> _sendToBackend(double lat, double lng) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      await http.put(
        Uri.parse('${AppConfig.backendUrl}/users/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
    } catch (_) {
      // Non-fatal
    }
  }
}
