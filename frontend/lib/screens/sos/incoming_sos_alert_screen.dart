import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_colors.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/sos/sos_service.dart';
import 'live_tracking_screen.dart';

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
  late Animation<double> _pulseAnim;

  late final String
  _mapUrl; // Single map URL used for both background and mini map
  bool _alarmMuted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    // Single map URL: with marker, sized for background (640x400)
    // Mini map will display the same image, scaled down (Flutter caches the image)
    _mapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${widget.lat},${widget.lng}'
        '&zoom=15&size=640x400&scale=2'
        '&markers=color:red%7C${widget.lat},${widget.lng}'
        '&style=element:geometry%7Ccolor:0x1a2744'
        '&style=element:labels.text.fill%7Ccolor:0x9ca5b3'
        '&key=$apiKey';

    // Auto-dismiss when the sender marks safe
    NotificationService.instance.sosEndedNotifier.addListener(_onSosEnded);
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

  String get _initials {
    final parts = widget.triggerUserName.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
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
          initialLat: widget.lat,
          initialLng: widget.lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: map with marker
          if (_mapUrl.isNotEmpty) _buildMapBackground(),

          // Gradient overlay: map visible at top, solid at bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF080F1E).withOpacity(0.15),
                  const Color(0xFF080F1E).withOpacity(0.97),
                ],
                stops: const [0.0, 0.65],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildPill(),
                const Spacer(),
                _buildRippleAvatar(),
                const SizedBox(height: 20),
                _buildNameRow(),
                const SizedBox(height: 6),
                _buildSubtitle(),
                const Spacer(),
                _buildMiniMap(),
                const Spacer(),
                _buildActionButtons(),
                const SizedBox(height: 10),
                _buildStopAlarmButton(),
                const SizedBox(height: 4),
                _buildIgnoreButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Positioned.fill(
      child: Image.network(
        _mapUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B3B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF3B3B).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B3B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SOS ALERT RECEIVED',
            style: TextStyle(
              color: Color(0xFFFF3B3B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRippleAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ripple
            Container(
              width: 120 + 40 * _pulseAnim.value,
              height: 120 + 40 * _pulseAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFFF3B3B,
                ).withOpacity(0.08 * (1 - _pulseAnim.value)),
              ),
            ),
            // Mid ripple
            Container(
              width: 120 + 20 * _pulseAnim.value,
              height: 120 + 20 * _pulseAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFFF3B3B,
                ).withOpacity(0.12 * (1 - _pulseAnim.value)),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFF3B3B).withOpacity(0.2),
          border: Border.all(color: const Color(0xFFFF3B3B), width: 2.5),
        ),
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow() {
    return Text(
      widget.triggerUserName.isEmpty
          ? 'Unknown Contact'
          : widget.triggerUserName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      widget.triggerUserPhone.isNotEmpty
          ? widget.triggerUserPhone
          : 'Trusted contact',
      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
    );
  }

  Widget _buildMiniMap() {
    // Use the same map URL as background (Flutter's image cache handles deduplication)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        _mapUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF1A2744),
          child: const Center(
            child: Icon(Icons.location_on, color: Color(0xFFFF3B3B), size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Primary: Open Live Tracking
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openLiveTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'OPEN LIVE TRACKING',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Call user
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callUser,
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(
                    widget.triggerUserName.isEmpty
                        ? 'Call'
                        : 'Call ${widget.triggerUserName.split(' ').first}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Call 122
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callEmergency,
                  icon: const Icon(Icons.local_police, size: 18),
                  label: const Text('Call 122'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B3B),
                    side: BorderSide(
                      color: const Color(0xFFFF3B3B).withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopAlarmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _alarmMuted ? null : _stopAlarm,
          icon: Icon(
            _alarmMuted ? Icons.notifications_off : Icons.volume_off,
            size: 18,
          ),
          label: Text(_alarmMuted ? 'Alarm Muted' : 'Stop Alarm'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _alarmMuted
                ? Colors.white38
                : const Color(0xFFFF9500),
            side: BorderSide(
              color: _alarmMuted
                  ? Colors.white12
                  : const Color(0xFFFF9500).withOpacity(0.6),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIgnoreButton() {
    return TextButton(
      onPressed: () {
        NotificationService.instance.dismissIncomingAlert();
        Navigator.of(context).pop();
      },
      child: Text(
        'Ignore',
        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
      ),
    );
  }
}
