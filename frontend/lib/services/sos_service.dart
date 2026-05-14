import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sos/sos_contact.dart';
import '../models/sos/sos_recording.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  static const String _contactsKey = 'sos_contacts';
  static const String _recordingsKey = 'sos_recordings';

  Timer? _flashTimer;
  bool _torchIsOn = false;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  int _recordingStartMs = 0;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();

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

  Future<void> startSiren() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
    } catch (_) {}

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sos_sound.mp3'), volume: 1.0);
    } catch (e) {
      print('Failed to play custom SOS sound: $e');
      // Fallback to system ringtone if custom audio fails
      try {
        await _ringtonePlayer.playAlarm(looping: true, volume: 1.0);
      } catch (_) {}
    }
  }

  Future<void> stopSiren() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _ringtonePlayer.stop();
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
      final recording = SosRecording(
        id: _recordingStartMs.toString(),
        path: path,
        timestampMs: _recordingStartMs,
        durationSeconds: durationSeconds,
        latitude: lat,
        longitude: lng,
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
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── WhatsApp alert ──────────────────────────────────────────────────────────

  Future<void> sendWhatsAppAlert(
    SosContact contact,
    double? lat,
    double? lng,
  ) async {
    String message;
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      final mapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
      message =
          '🚨 EMERGENCY SOS ALERT!\n\nI need immediate help! This is my live location:\n$mapsUrl\n\nPlease call me or contact emergency services!';
    } else {
      message =
          '🚨 EMERGENCY SOS ALERT!\n\nI need immediate help! I have triggered my emergency SOS. Please call me or contact emergency services immediately!';
    }

    final cleanPhone = contact.phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ─── Contacts (SharedPreferences) ───────────────────────────────────────────

  Future<List<SosContact>> getContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_contactsKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((e) => SosContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveContacts(List<SosContact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _contactsKey,
        jsonEncode(contacts.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ─── Stop all ────────────────────────────────────────────────────────────────

  Future<void> stopAll() async {
    await Future.wait([stopFlashStrobe(), stopSiren(), stopRecording()]);
  }
}
