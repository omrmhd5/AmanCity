import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import 'sos_slide_to_cancel.dart';
import 'sos_status_checklist.dart';

class SosActiveView extends StatefulWidget {
  final bool locationAcquired;
  final bool contactsNotified;
  final int recordingSeconds;
  final String? locationText;
  final double? activeLat;
  final double? activeLng;
  final VoidCallback onCancel;

  const SosActiveView({
    Key? key,
    required this.locationAcquired,
    required this.contactsNotified,
    required this.recordingSeconds,
    this.locationText,
    this.activeLat,
    this.activeLng,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SosActiveView> createState() => _SosActiveViewState();
}

class _SosActiveViewState extends State<SosActiveView>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _blinkController;
  late AnimationController _entryController;
  late Animation<double> _blinkAnim;

  String? _cachedMapUrl;
  double? _cachedLat;
  double? _cachedLng;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) {
      _cachedMapUrl = null; // force map URL regeneration with new theme style
      setState(() {});
    }
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _radarController.dispose();
    _blinkController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final interval = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: interval,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(interval),
        child: child,
      ),
    );
  }

  String _buildMapUrl() {
    final lat = widget.activeLat!;
    final lng = widget.activeLng!;
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
        '$styleParams'
        '&key=$apiKey';
    return _cachedMapUrl!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 0: base background
        Positioned.fill(
          child: ColoredBox(color: AppTheme.getBackgroundColor()),
        ),
        // Layer 1: user location map (fades in once GPS acquired)
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1200),
            opacity: widget.activeLat != null ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                image: widget.activeLat != null
                    ? DecorationImage(
                        image: NetworkImage(_buildMapUrl()),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),
        ),
        // Layer 2: gradient overlay — map visible at top, solid at bottom
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
        // Layer 3: danger red tint
        Positioned.fill(
          child: Container(color: AppColors.danger.withOpacity(0.06)),
        ),
        // Layer 4: content
        Positioned.fill(
          child: Column(
            children: [
              // Header
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      // "Emergency Mode Active" pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: _blinkAnim,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'EMERGENCY MODE ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.getPrimaryTextColor(),
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: AppColors.danger.withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'ACTIVATED',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.danger,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Help request broadcasted',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                start: 0.0,
                end: 0.5,
              ),
              // Gradient divider
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.danger.withOpacity(0.0),
                          AppColors.danger.withOpacity(0.25),
                          AppColors.danger.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                start: 0.15,
                end: 0.65,
              ),
              // Radar animation
              Expanded(
                child: _animated(
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (_, __) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _RadarRing(
                                progress: _radarController.value,
                                delay: 0.0,
                              ),
                              _RadarRing(
                                progress: _radarController.value,
                                delay: 0.33,
                              ),
                              _RadarRing(
                                progress: _radarController.value,
                                delay: 0.66,
                              ),
                              // Center icon
                              Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.danger.withOpacity(0.6),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.sos_rounded,
                                  color: Colors.white,
                                  size: 46,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  start: 0.2,
                  end: 0.7,
                ),
              ),
              // Status checklist card
              _animated(
                SosStatusChecklist(
                  locationAcquired: widget.locationAcquired,
                  contactsNotified: widget.contactsNotified,
                  recordingSeconds: widget.recordingSeconds,
                  locationText: widget.locationText,
                ),
                start: 0.35,
                end: 0.85,
              ),
              const SizedBox(height: 24),
              // Slide to cancel
              _animated(
                SosSlideToCancelWidget(onCancel: widget.onCancel),
                start: 0.45,
                end: 0.95,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadarRing extends StatelessWidget {
  final double progress;
  final double delay;

  const _RadarRing({required this.progress, required this.delay});

  @override
  Widget build(BuildContext context) {
    final p = ((progress - delay + 1.0) % 1.0).clamp(0.0, 1.0);
    if (progress < delay) return const SizedBox();
    final size = p * 240.0;
    final opacity = (1.0 - p).clamp(0.0, 0.8);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.danger.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }
}
