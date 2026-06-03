import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/map/geocoding_api_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/sos/sos_service.dart';
import '../../utils/app_theme.dart';
import 'live_tracking_screen.dart';

import '../../widgets/sos_screen/incoming_sos/incoming_sos_map_background.dart';
import '../../widgets/sos_screen/incoming_sos/incoming_sos_header.dart';
import '../../widgets/sos_screen/incoming_sos/incoming_sos_ripple_avatar.dart';
import '../../widgets/sos_screen/incoming_sos/incoming_sos_identity.dart';
import '../../widgets/sos_screen/incoming_sos/incoming_sos_actions.dart';
import '../../widgets/sos_screen/incoming_sos/incoming_sos_slide_to_ignore.dart';

class IncomingSosAlertScreen extends StatefulWidget {
  final String sessionId;
  final String triggerUserName;
  final String triggerUserPhone;
  final double lat;
  final double lng;

  const IncomingSosAlertScreen({
    Key? key,
    required this.sessionId,
    required this.triggerUserName,
    required this.triggerUserPhone,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  State<IncomingSosAlertScreen> createState() => _IncomingSosAlertScreenState();
}

class _IncomingSosAlertScreenState extends State<IncomingSosAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late double _resolvedLat;
  late double _resolvedLng;

  String? _locationText;
  int? _distanceMeters;
  bool _locationLoading = true;
  bool _alarmMuted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _resolvedLat = widget.lat;
    _resolvedLng = widget.lng;

    // Auto-dismiss when the sender marks safe
    NotificationService.instance.sosEndedNotifier.addListener(_onSosEnded);
    _refreshLocationText();
    _refreshDistanceFromCurrentUser();
    _refreshSessionLocation();
  }

  Future<void> _refreshSessionLocation() async {
    final session = await SosService.getSession(widget.sessionId);
    if (!mounted || session == null) return;
    if (session.lat == _resolvedLat && session.lng == _resolvedLng) return;
    setState(() {
      _resolvedLat = session.lat;
      _resolvedLng = session.lng;
    });
    await _refreshLocationText();
    await _refreshDistanceFromCurrentUser();
  }

  Future<void> _refreshDistanceFromCurrentUser() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      final meters = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        _resolvedLat,
        _resolvedLng,
      );
      if (!mounted) return;
      setState(() => _distanceMeters = meters.round());
    } catch (_) {}
  }

  Future<void> _refreshLocationText() async {
    if (mounted) {
      setState(() => _locationLoading = true);
    }
    final result = await GeocodingService.reverseGeocode(
      _resolvedLat,
      _resolvedLng,
    );
    if (!mounted) return;
    setState(() {
      _locationText = result['text'];
      _locationLoading = false;
    });
  }

  void _onSosEnded() {
    final endedId = NotificationService.instance.sosEndedNotifier.value;
    if (endedId == widget.sessionId && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    NotificationService.instance.sosEndedNotifier.removeListener(_onSosEnded);
    NotificationService.instance.onIncomingAlertScreenClosed();
    _pulseController.dispose();
    SosService().stopAlertSound();
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  Future<void> _callUser() async {
    if (widget.triggerUserPhone.isEmpty) return;
    final uri = Uri.parse('tel:${widget.triggerUserPhone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:122');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _stopAlarm() {
    FlutterRingtonePlayer().stop();
    SosService().stopAlertSound();
    setState(() => _alarmMuted = true);
  }

  void _openLiveTracking() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(
          sessionId: widget.sessionId,
          initialUserName: widget.triggerUserName,
          initialUserPhone: widget.triggerUserPhone,
          initialLat: _resolvedLat,
          initialLng: _resolvedLng,
        ),
      ),
    );
  }

  void _handleDismiss() {
    NotificationService.instance.dismissIncomingAlert();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          IncomingSosMapBackground(lat: _resolvedLat, lng: _resolvedLng),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const IncomingSosHeader(),
                const Spacer(),
                IncomingSosRippleAvatar(
                  animation: _pulseController,
                  triggerUserName: widget.triggerUserName,
                ),
                const SizedBox(height: 4),
                IncomingSosIdentity(
                  animation: _pulseController,
                  triggerUserName: widget.triggerUserName,
                  locationLoading: _locationLoading,
                  locationText: _locationText,
                  distanceMeters: _distanceMeters,
                  resolvedLat: _resolvedLat,
                  resolvedLng: _resolvedLng,
                ),
                const Spacer(),
                IncomingSosActions(
                  triggerUserName: widget.triggerUserName,
                  onOpenLiveTracking: _openLiveTracking,
                  onCallUser: _callUser,
                  onCallEmergency: _callEmergency,
                  onMuteAlarm: _stopAlarm,
                  alarmMuted: _alarmMuted,
                ),
                const SizedBox(height: 12),
                IncomingSosSlideToIgnore(onDismiss: _handleDismiss),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
