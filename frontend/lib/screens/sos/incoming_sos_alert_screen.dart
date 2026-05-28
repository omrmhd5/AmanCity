import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_colors.dart';
import '../../services/map/geocoding_api_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/sos/sos_service.dart';
import '../../utils/app_theme.dart';
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
  late double _resolvedLat;
  late double _resolvedLng;

  String? _cachedMapUrl;
  NetworkImage? _cachedMapImage;
  double? _cachedLat;
  double? _cachedLng;
  String? _locationText;
  int? _distanceMeters;
  bool _locationLoading = true;
  bool _alarmMuted = false;
  double _ignoreDragOffset = 0.0;
  static const double _ignoreThumbSize = 44.0;
  static const double _ignoreThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _resolvedLat = widget.lat;
    _resolvedLng = widget.lng;
    AppTheme.themeNotifier.addListener(_onThemeChange);

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
      _cachedMapUrl = null;
      _cachedMapImage = null;
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

  void _onThemeChange() {
    if (mounted) {
      _cachedMapUrl = null;
      _cachedMapImage = null;
      setState(() {});
    }
  }

  void _onSosEnded() {
    final endedId = NotificationService.instance.sosEndedNotifier.value;
    if (endedId == widget.sessionId && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
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
          initialLat: _resolvedLat,
          initialLng: _resolvedLng,
        ),
      ),
    );
  }

  String _buildMapUrl() {
    final lat = _resolvedLat;
    final lng = _resolvedLng;
    if (lat == _cachedLat && lng == _cachedLng && _cachedMapUrl != null) {
      return _cachedMapUrl!;
    }
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _cachedLat = lat;
    _cachedLng = lng;
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    final styleParams = isDark
        ? '&style=feature:all|element:labels|visibility:off'
              '&style=feature:water|element:geometry|color:0x060e1a'
              '&style=feature:all|element:geometry|color:0x0d1b2a'
              '&style=feature:road|element:geometry|color:0x1a3050'
        : '&style=feature:all|element:labels|visibility:off';
    _cachedMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=14'
        '&size=640x640'
        '&markers=color:red%7C$lat,$lng'
        '$styleParams'
        '&key=$apiKey';
    return _cachedMapUrl!;
  }

  ImageProvider _buildMapImage() {
    final url = _buildMapUrl();
    if (_cachedMapImage != null && _cachedMapUrl == url) {
      return _cachedMapImage!;
    }
    _cachedMapImage = NetworkImage(url);
    return _cachedMapImage!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(color: AppTheme.getBackgroundColor()),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1200),
              opacity: 1.0,
              child: Image(
                image: _buildMapImage(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.getBackgroundColor().withOpacity(0.15),
                    AppTheme.getBackgroundColor().withOpacity(0.97),
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: AppColors.danger.withOpacity(0.06)),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildPill(),
                const SizedBox(height: 6),
                _buildReceivedTime(),
                const Spacer(),
                _buildRippleAvatar(),
                const SizedBox(height: 4),
                _buildBouncingIdentityBlock(),
                const Spacer(),
                _buildActionButtons(),
                const SizedBox(height: 14),
                _buildMuteAlarmButton(),
                const SizedBox(height: 12),
                _buildSlideToIgnore(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
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

  Widget _buildReceivedTime() {
    final now = DateTime.now();
    final time = TimeOfDay.fromDateTime(now).format(context);
    return Text(
      'Today at $time',
      style: TextStyle(
        color: AppTheme.getSecondaryTextColor().withOpacity(0.8),
        fontSize: 12,
      ),
    );
  }

  Widget _buildRippleAvatar() {
    return SizedBox(
      width: 250,
      height: 180,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _PulseRing(progress: _pulseController.value, delay: 0.0),
              _PulseRing(progress: _pulseController.value, delay: 0.33),
              _PulseRing(progress: _pulseController.value, delay: 0.66),
              child!,
            ],
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
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
            Positioned(
              bottom: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B3B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'HELP REQUESTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBouncingIdentityBlock() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final offsetY = math.sin(_pulseController.value * 2 * math.pi) * 4;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Column(
            children: [
              _buildNameRow(),
              const SizedBox(height: 8),
              _buildLocationLine(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameRow() {
    return Text(
      widget.triggerUserName.isEmpty
          ? 'Unknown Contact'
          : widget.triggerUserName,
      style: TextStyle(
        color: AppTheme.getPrimaryTextColor(),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLocationLine() {
    if (_locationLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading location...',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor().withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final hasLocation = _locationText?.trim().isNotEmpty == true;
    final title = hasLocation ? _locationText! : 'Coordinates';
    final distanceSuffix = _distanceMeters != null
        ? ' (${_distanceMeters}m away)'
        : '';
    final coordsText =
        '${_resolvedLat.toStringAsFixed(5)}\n${_resolvedLng.toStringAsFixed(5)}';
    final displayText = hasLocation
        ? '$title$distanceSuffix'
        : '$title$distanceSuffix\n$coordsText';
    final maxLines = hasLocation ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.place_rounded, color: Color(0xFFFF3B3B), size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor().withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openLiveTracking,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text(
                'OPEN LIVE TRACKING',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Call user
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callUser,
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(
                    widget.triggerUserName.isEmpty
                        ? 'Call'
                        : 'Call ${widget.triggerUserName.split(' ').first}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142744),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Call 122
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callEmergency,
                  icon: const Icon(Icons.local_police, size: 18),
                  label: const Text('Call 122'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C2D47),
                    foregroundColor: const Color(0xFFFF6B6B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildMuteAlarmButton() {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
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
          label: Text(_alarmMuted ? 'ALARM MUTED' : 'MUTE ALARM'),
          style: OutlinedButton.styleFrom(
            backgroundColor: isDark
                ? Colors.transparent
                : (_alarmMuted
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFFFBBF24)),
            foregroundColor: _alarmMuted
                ? (isDark ? Colors.white38 : const Color(0xFF6B7280))
                : (isDark ? const Color(0xFFFFB020) : const Color(0xFF1F2937)),
            side: BorderSide(
              color: _alarmMuted
                  ? (isDark
                        ? Colors.white12
                        : const Color(0xFF9CA3AF).withOpacity(0.9))
                  : (isDark
                        ? const Color(0xFFFFB020).withOpacity(0.6)
                        : const Color(0xFFF59E0B).withOpacity(0.95)),
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

  Widget _buildSlideToIgnore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDark = AppTheme.currentMode == AppThemeMode.dark;
          final maxOffset = (constraints.maxWidth - _ignoreThumbSize - 8).clamp(
            0.0,
            double.infinity,
          );
          final progress = maxOffset > 0
              ? (_ignoreDragOffset / maxOffset).clamp(0.0, 1.0)
              : 0.0;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _ignoreDragOffset = (_ignoreDragOffset + details.delta.dx)
                    .clamp(0.0, maxOffset);
              });
            },
            onHorizontalDragEnd: (_) {
              if (maxOffset > 0 &&
                  _ignoreDragOffset / maxOffset >= _ignoreThreshold) {
                HapticFeedback.mediumImpact();
                NotificationService.instance.dismissIncomingAlert();
                Navigator.of(context).pop();
              } else {
                setState(() => _ignoreDragOffset = 0.0);
              }
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.white.withOpacity(0.10)
                        : AppTheme.getPrimaryTextColor().withOpacity(0.12),
                    isDark
                        ? Colors.white.withOpacity(0.07)
                        : AppTheme.getPrimaryTextColor().withOpacity(0.06),
                  ],
                ),
                border: Border.all(color: AppTheme.getBorderColor(), width: 1),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 40),
                    width: (_ignoreDragOffset + _ignoreThumbSize + 6).clamp(
                      _ignoreThumbSize + 6,
                      constraints.maxWidth,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2 * progress),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: (1.0 - progress * 2).clamp(0.0, 0.7),
                      child: Text(
                        'SLIDE TO IGNORE',
                        style: TextStyle(
                          color: AppTheme.getPrimaryTextColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4 + _ignoreDragOffset,
                    top: 5,
                    child: Container(
                      width: _ignoreThumbSize,
                      height: _ignoreThumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        progress >= _ignoreThreshold
                            ? Icons.check
                            : Icons.close,
                        color: progress >= _ignoreThreshold
                            ? AppColors.success
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double progress;
  final double delay;

  const _PulseRing({required this.progress, required this.delay});

  @override
  Widget build(BuildContext context) {
    if (progress < delay) return const SizedBox.shrink();
    final p = ((progress - delay + 1.0) % 1.0).clamp(0.0, 1.0);
    final size = 110 + (p * 120);
    final opacity = (1.0 - p).clamp(0.0, 1.0) * 0.3;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF3B3B).withOpacity(opacity),
          width: 1.6,
        ),
      ),
    );
  }
}
