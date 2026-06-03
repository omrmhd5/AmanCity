import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class IncomingSosRippleAvatar extends StatelessWidget {
  final Animation<double> animation;
  final String triggerUserName;

  const IncomingSosRippleAvatar({
    Key? key,
    required this.animation,
    required this.triggerUserName,
  }) : super(key: key);

  String get _initials {
    final parts = triggerUserName.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 180,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _PulseRing(progress: animation.value, delay: 0.0),
              _PulseRing(progress: animation.value, delay: 0.33),
              _PulseRing(progress: animation.value, delay: 0.66),
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
                child: Text(
                  'sos.help_requested'.tr(),
                  style: const TextStyle(
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
