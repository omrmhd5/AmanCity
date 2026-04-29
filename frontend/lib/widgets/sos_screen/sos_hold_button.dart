import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SosHoldButton extends StatefulWidget {
  final VoidCallback onActivate;

  const SosHoldButton({Key? key, required this.onActivate}) : super(key: key);

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onActivate();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _isHolding = true);
    _controller.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _onLongPressEnd(LongPressEndDetails _) => _reset();
  void _onLongPressCancel() => _reset();

  void _reset() {
    if (_controller.status != AnimationStatus.completed) {
      setState(() => _isHolding = false);
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final remainingSecs = (3 - progress * 3).ceil();

          return SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ripple rings (only when holding)
                if (_isHolding) ...[
                  _RippleRing(progress: progress, delay: 0.0, maxSize: 240),
                  _RippleRing(progress: progress, delay: 0.33, maxSize: 240),
                  _RippleRing(progress: progress, delay: 0.66, maxSize: 240),
                ],
                // Progress ring
                CustomPaint(
                  size: const Size(210, 210),
                  painter: _ProgressRingPainter(progress: progress),
                ),
                // Main button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFEF4444,
                        ).withOpacity(_isHolding ? 0.75 : 0.4),
                        blurRadius: _isHolding ? 48 : 20,
                        spreadRadius: _isHolding ? 8 : 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sos, color: Colors.white, size: 62),
                      const SizedBox(height: 2),
                      Text(
                        _isHolding ? '${remainingSecs}s' : 'HOLD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
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

class _RippleRing extends StatelessWidget {
  final double progress;
  final double delay;
  final double maxSize;

  const _RippleRing({
    required this.progress,
    required this.delay,
    required this.maxSize,
  });

  @override
  Widget build(BuildContext context) {
    final p = ((progress - delay + 1.0) % 1.0).clamp(0.0, 1.0);
    if (progress < delay) return const SizedBox();
    final size = p * maxSize;
    final opacity = (1.0 - p).clamp(0.0, 0.6);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..color = const Color(0xFFEF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}
