import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import 'sos_slide_to_cancel.dart';
import 'sos_status_checklist.dart';

class SosActiveView extends StatefulWidget {
  final bool locationAcquired;
  final bool contactsNotified;
  final int recordingSeconds;
  final String? locationText;
  final VoidCallback onCancel;

  const SosActiveView({
    Key? key,
    required this.locationAcquired,
    required this.contactsNotified,
    required this.recordingSeconds,
    this.locationText,
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
  late Animation<double> _entryAnim;

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
      duration: const Duration(milliseconds: 300),
    )..forward();
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _blinkController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryAnim,
      child: Column(
        children: [
          // Header
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
                    color: Colors.white,
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
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          // Red gradient separator
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.danger.withOpacity(0.06),
                  AppColors.danger.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // Radar animation
          Expanded(
            child: Center(
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
                                blurRadius: 32,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
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
          ),

          // Status checklist card
          SosStatusChecklist(
            locationAcquired: widget.locationAcquired,
            contactsNotified: widget.contactsNotified,
            recordingSeconds: widget.recordingSeconds,
            locationText: widget.locationText,
          ),
          const SizedBox(height: 24),

          // Slide to cancel
          SosSlideToCancelWidget(onCancel: widget.onCancel),
          const SizedBox(height: 28),
        ],
      ),
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
    if (progress < delay && progress > 0.01) return const SizedBox();
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
