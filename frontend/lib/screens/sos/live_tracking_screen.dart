import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/sos/sos_session_info.dart';
import '../../services/sos/sos_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String sessionId;
  final String initialUserName;
  final String initialUserPhone;
  final double initialLat;
  final double initialLng;

  const LiveTrackingScreen({
    Key? key,
    required this.sessionId,
    required this.initialUserName,
    required this.initialUserPhone,
    required this.initialLat,
    required this.initialLng,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  SosSessionInfo? _session;
  Timer? _pollTimer;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  bool _sessionEnded = false;
  late AnimationController _entryController;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _session = SosSessionInfo(
      sessionId: widget.sessionId,
      triggerUserName: widget.initialUserName,
      triggerUserPhone: widget.initialUserPhone,
      lat: widget.initialLat,
      lng: widget.initialLng,
      active: true,
      updatedAt: DateTime.now(),
    );
    _updateMarker(widget.initialLat, widget.initialLng);
    _startPolling();
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _poll() async {
    final updated = await SosService.getSession(widget.sessionId);
    if (!mounted || updated == null) return;
    setState(() {
      _session = updated;
      _sessionEnded = !updated.active;
    });
    _updateMarker(updated.lat, updated.lng);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(updated.lat, updated.lng)),
    );
    if (_sessionEnded) {
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
    }
  }

  void _updateMarker(double lat, double lng) {
    final marker = Marker(
      markerId: const MarkerId('sos_user'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: widget.initialUserName),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    setState(() {
      _markers
        ..clear()
        ..add(marker);
    });
  }

  String get _elapsedLabel {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _lastUpdatedLabel {
    if (_session == null) return '';
    final diff = DateTime.now().difference(_session!.updatedAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  Future<void> _callUser() async {
    final phone = _session?.triggerUserPhone ?? widget.initialUserPhone;
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:122');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final lat = _session?.lat ?? widget.initialLat;
    final lng = _session?.lng ?? widget.initialLng;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 16,
            ),
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top bar
          _animated(
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.getPrimaryTextColor(),
                        size: 25,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC080F1E),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _sessionEnded
                              ? Colors.grey.withOpacity(0.4)
                              : const Color(0xFFFF3B3B).withOpacity(0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_sessionEnded)
                            _BlinkingDot()
                          else
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 10,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _sessionEnded
                                ? 'SOS Ended'
                                : 'SOS Active • $_elapsedLabel',
                            style: TextStyle(
                              color: _sessionEnded
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFFFF3B3B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            start: 0.0,
            end: 0.6,
          ),

          // Bottom sheet
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomSheet()),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    final name = _session?.triggerUserName ?? widget.initialUserName;
    final phone = _session?.triggerUserPhone ?? widget.initialUserPhone;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF3B3B).withOpacity(0.18),
                  border: Border.all(
                    color: const Color(0xFFFF3B3B).withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Unknown' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'Updated $_lastUpdatedLabel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone,
                  label: 'Call',
                  color: AppColors.secondary,
                  onTap: _callUser,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.local_police,
                  label: 'Call 122',
                  color: const Color(0xFFFF3B3B),
                  onTap: _callEmergency,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.my_location,
                  label: 'Center',
                  color: Colors.white.withOpacity(0.15),
                  iconColor: Colors.white,
                  onTap: () {
                    final lat = _session?.lat ?? widget.initialLat;
                    final lng = _session?.lng ?? widget.initialLng;
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFFF3B3B),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: iconColor ?? Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
