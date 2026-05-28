import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torch_light/torch_light.dart';

import '../../config/app_config.dart';
import '../../models/sos/sos_recording.dart';
import '../../models/sos/sos_session_info.dart';
import '../map/geocoding_api_service.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  static const String _recordingsKey = 'sos_recordings';
  static const _base = '${AppConfig.backendUrl}/sos';

  Timer? _flashTimer;
  bool _torchIsOn = false;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  int _recordingStartMs = 0;
  AudioPlayer? _sirenPlayer;
  AudioPlayer? _alertPlayer; // receiver-side alert sound

  // ─── Flashlight strobe ──────────────────────────────────────────────────────

  Future<void> startFlashStrobe() async {
    _flashTimer?.cancel();
    bool available = false;
    try {
      available = await TorchLight.isTorchAvailable();
    } catch (_) {}
    if (!available) return;

    _flashTimer = Timer.periodic(const Duration(milliseconds: 350), (_) async {
      try {
        if (_torchIsOn) {
          await TorchLight.disableTorch();
        } else {
          await TorchLight.enableTorch();
        }
        _torchIsOn = !_torchIsOn;
      } catch (_) {}
    });
  }

  Future<void> stopFlashStrobe() async {
    _flashTimer?.cancel();
    _flashTimer = null;
    try {
      if (_torchIsOn) await TorchLight.disableTorch();
    } catch (_) {}
    _torchIsOn = false;
  }

  // ─── Siren ──────────────────────────────────────────────────────────────────

  static final AudioContext _sirenAudioContext = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: {
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.allowBluetooth,
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
    android: AudioContextAndroid(
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  Future<void> startSiren() async {
    // Always dispose the old player so the new one gets a fresh native instance
    // with the correct audio context — setAudioContext() on an existing player
    // does NOT propagate to the already-initialized native side.
    await stopSiren();

    final player = AudioPlayer();
    _sirenPlayer = player;
    try {
      await player.setAudioContext(_sirenAudioContext);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sos_sound.mp3'), volume: 1.0);
    } catch (e) {
      await player.dispose();
      _sirenPlayer = null;
    }
  }

  Future<void> stopSiren() async {
    final player = _sirenPlayer;
    _sirenPlayer = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {}
  }

  // ─── Alert sound (receiver side) ────────────────────────────────────────────

  static final AudioContext _alertAudioContext = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: {
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.allowBluetooth,
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
    android: AudioContextAndroid(
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  Future<void> playAlertSound() async {
    await stopAlertSound();
    final player = AudioPlayer();
    _alertPlayer = player;
    try {
      await player.setAudioContext(_alertAudioContext);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sos_sound.mp3'), volume: 1.0);
    } catch (e) {
      await player.dispose();
      _alertPlayer = null;
    }
  }

  Future<void> stopAlertSound() async {
    final player = _alertPlayer;
    _alertPlayer = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {}
  }

  // ─── Audio recording ────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    if (_isRecording) return false;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    try {
      // Save to app documents directory (persistent, user-accessible)
      final dir = await getApplicationDocumentsDirectory();
      final sosDirPath = '${dir.path}/sos_recordings';
      await Directory(sosDirPath).create(recursive: true);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '$sosDirPath/sos_$id.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 256000,
          // echoCancel: true,
          autoGain: true,
          // androidConfig: AndroidRecordConfig(
          //   audioSource: AndroidAudioSource.voiceCommunication,
          // ),
        ),
        path: path,
      );

      _currentRecordingPath = path;
      _recordingStartMs = DateTime.now().millisecondsSinceEpoch;
      _isRecording = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stops recording and saves metadata. Pass [lat]/[lng] to embed location.
  Future<void> stopRecording({double? lat, double? lng}) async {
    if (!_isRecording) return;
    try {
      await _recorder.stop();
    } catch (_) {}

    final path = _currentRecordingPath;
    if (path != null) {
      final durationSeconds =
          ((DateTime.now().millisecondsSinceEpoch - _recordingStartMs) / 1000)
              .round();
      String? address;
      if (lat != null && lng != null) {
        try {
          final result = await GeocodingService.reverseGeocode(lat, lng);
          address = result['text'];
        } catch (_) {}
      }
      final recording = SosRecording(
        id: _recordingStartMs.toString(),
        path: path,
        timestampMs: _recordingStartMs,
        durationSeconds: durationSeconds,
        latitude: lat,
        longitude: lng,
        address: address,
      );
      await _saveRecordingMetadata(recording);
    }

    _isRecording = false;
    _currentRecordingPath = null;
    _recordingStartMs = 0;
  }

  // ─── Recording history ───────────────────────────────────────────────────────

  Future<List<SosRecording>> getRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recordingsKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      // Filter out entries whose file no longer exists
      final recordings = list
          .map((e) => SosRecording.fromJson(e as Map<String, dynamic>))
          .where((r) => File(r.path).existsSync())
          .toList();
      recordings.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
      return recordings;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteRecording(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recordingsKey);
      if (json == null) return;
      final list = (jsonDecode(json) as List)
          .map((e) => SosRecording.fromJson(e as Map<String, dynamic>))
          .toList();

      final toDelete = list.firstWhere(
        (r) => r.id == id,
        orElse: () => throw Exception('not found'),
      );

      // Delete the audio file
      final file = File(toDelete.path);
      if (await file.exists()) await file.delete();

      // Remove from stored list
      list.removeWhere((r) => r.id == id);
      await prefs.setString(
        _recordingsKey,
        jsonEncode(list.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _saveRecordingMetadata(SosRecording recording) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recordingsKey);
      final list = json != null
          ? (jsonDecode(json) as List)
                .map((e) => SosRecording.fromJson(e as Map<String, dynamic>))
                .toList()
          : <SosRecording>[];
      list.add(recording);
      await prefs.setString(
        _recordingsKey,
        jsonEncode(list.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ─── Location ────────────────────────────────────────────────────────────────

  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Fast path: emulator/devices often already have a cached fix.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── SOS Session API ─────────────────────────────────────────────────────────

  static Future<String?> _idToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Creates a new SOS session. Returns the sessionId on success, null on failure.
  static Future<String?> createSession(double lat, double lng) async {
    try {
      final token = await _idToken();
      if (token == null) return null;
      final res = await http.post(
        Uri.parse('$_base/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['sessionId'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Updates the live location for an active session.
  static Future<void> updateLocation(
    String sessionId,
    double lat,
    double lng,
  ) async {
    try {
      final token = await _idToken();
      if (token == null) return;
      await http.patch(
        Uri.parse('$_base/sessions/$sessionId/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
    } catch (_) {}
  }

  /// Ends the session.
  static Future<void> endSession(String sessionId) async {
    try {
      final token = await _idToken();
      if (token == null) return;
      await http.patch(
        Uri.parse('$_base/sessions/$sessionId/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }

  /// Polls the current state of a session.
  static Future<SosSessionInfo?> getSession(String sessionId) async {
    try {
      final token = await _idToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.parse('$_base/sessions/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return SosSessionInfo.fromJson(data, sessionId);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Stop all ────────────────────────────────────────────────────────────────

  Future<void> stopAll() async {
    await Future.wait([stopFlashStrobe(), stopSiren(), stopRecording()]);
  }
}
