import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class HomeSosCard extends StatefulWidget {
  final VoidCallback onActivate;
  final VoidCallback onOpenSos;
  final VoidCallback onContactsTap;
  final VoidCallback onRecordingsTap;

  const HomeSosCard({
    Key? key,
    required this.onActivate,
    required this.onOpenSos,
    required this.onContactsTap,
    required this.onRecordingsTap,
  }) : super(key: key);

  @override
  State<HomeSosCard> createState() => _HomeSosCardState();
}

class _HomeSosCardState extends State<HomeSosCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onOpenSos,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.danger.withOpacity(0.22), width: 1),
        ),
        child: Column(
          children: [
            // ── Top: label + subtitle ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, __) => Transform.scale(
                                scale: _pulse.value,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'EMERGENCY SOS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hold the button to activate alert & recording',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getSecondaryTextColor(),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Go-to SOS screen arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.2),
                        width: 0.75,
                      ),
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      color: AppColors.danger,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // ── Center: compact hold button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: GestureDetector(
                onTap: null,
                onLongPress: null,
                child: _SosHoldButton(onActivate: widget.onActivate),
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────────
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
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

            // ── Bottom quick links ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _quickLink(
                      icon: Icons.people_rounded,
                      label: 'Contacts',
                      onTap: widget.onContactsTap,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.danger.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _quickLink(
                      icon: Icons.history_rounded,
                      label: 'Recordings',
                      onTap: widget.onRecordingsTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.danger.withOpacity(0.8), size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.danger.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hold button ─────────────────────────────────────────────────────────────

class _SosHoldButton extends StatefulWidget {
  final VoidCallback onActivate;
  const _SosHoldButton({required this.onActivate});

  @override
  State<_SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<_SosHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onActivate();
        _reset();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _reset() {
    if (mounted) {
      setState(() => _holding = false);
      _ctrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _holding = true);
        _ctrl.forward(from: 0);
        HapticFeedback.mediumImpact();
      },
      onLongPressEnd: (_) {
        if (_ctrl.status != AnimationStatus.completed) _reset();
      },
      onLongPressCancel: () {
        if (_ctrl.status != AnimationStatus.completed) _reset();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final p = _ctrl.value;
          final secs = (3 - p * 3).ceil();
          return SizedBox(
            width: 148,
            height: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_holding) ...[
                  _Ripple(p: p, delay: 0.0, max: 148),
                  _Ripple(p: p, delay: 0.33, max: 148),
                  _Ripple(p: p, delay: 0.66, max: 148),
                ],
                CustomPaint(
                  size: const Size(132, 132),
                  painter: _ProgressRing(p),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withOpacity(
                          _holding ? 0.7 : 0.35,
                        ),
                        blurRadius: _holding ? 32 : 14,
                        spreadRadius: _holding ? 4 : 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sos_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _holding ? '${secs}s' : 'HOLD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  final double p, delay, max;
  const _Ripple({required this.p, required this.delay, required this.max});

  @override
  Widget build(BuildContext context) {
    if (p < delay) return const SizedBox();
    final t = ((p - delay + 1.0) % 1.0).clamp(0.0, 1.0);
    return Container(
      width: t * max,
      height: t * max,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.danger.withOpacity((1.0 - t).clamp(0.0, 0.55)),
          width: 1.5,
        ),
      ),
    );
  }
}

class _ProgressRing extends CustomPainter {
  final double p;
  _ProgressRing(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.danger.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (p > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        p * 2 * math.pi,
        false,
        Paint()
          ..color = AppColors.danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRing old) => old.p != p;
}
