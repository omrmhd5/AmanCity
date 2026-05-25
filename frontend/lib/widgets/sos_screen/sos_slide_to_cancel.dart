import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_colors.dart';

class SosSlideToCancelWidget extends StatefulWidget {
  final VoidCallback onCancel;

  const SosSlideToCancelWidget({Key? key, required this.onCancel})
    : super(key: key);

  @override
  State<SosSlideToCancelWidget> createState() => _SosSlideToCancelWidgetState();
}

class _SosSlideToCancelWidgetState extends State<SosSlideToCancelWidget> {
  double _dragOffset = 0.0;
  static const double _thumbSize = 52.0;
  static const double _threshold = 0.8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swipe_right_alt_rounded,
                size: 13,
                color: Colors.white.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                'SLIDE TO MARK AS SAFE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxOffset = (constraints.maxWidth - _thumbSize - 8).clamp(
                0.0,
                double.infinity,
              );
              final progress = maxOffset > 0
                  ? (_dragOffset / maxOffset).clamp(0.0, 1.0)
                  : 0.0;

              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset = (_dragOffset + details.delta.dx).clamp(
                      0.0,
                      maxOffset,
                    );
                  });
                  if (progress >= _threshold) {
                    HapticFeedback.lightImpact();
                  }
                },
                onHorizontalDragEnd: (_) {
                  if (_dragOffset / maxOffset >= _threshold) {
                    HapticFeedback.heavyImpact();
                    widget.onCancel();
                  } else {
                    setState(() => _dragOffset = 0.0);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.07),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(29),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Progress fill
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 30),
                            width: (_dragOffset + _thumbSize + 4).clamp(
                              _thumbSize + 4,
                              constraints.maxWidth,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(
                                0.2 * progress,
                              ),
                              borderRadius: BorderRadius.circular(29),
                            ),
                          ),
                          // Background label
                          Center(
                            child: Opacity(
                              opacity: (1.0 - progress * 2.5).clamp(0.0, 0.5),
                              child: const Text(
                                'MARK AS SAFE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          // Sliding thumb
                          Positioned(
                            left: 3 + _dragOffset,
                            top: 3,
                            child: Container(
                              width: _thumbSize,
                              height: _thumbSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                progress >= _threshold
                                    ? Icons.check
                                    : Icons.chevron_right,
                                color: progress >= _threshold
                                    ? AppColors.success
                                    : AppColors.primary,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
