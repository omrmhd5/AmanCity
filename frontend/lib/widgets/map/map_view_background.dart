import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class MapViewBackground extends StatelessWidget {
  const MapViewBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark map background
        Container(
          decoration: BoxDecoration(
            color: AppTheme.currentMode == AppThemeMode.dark
                ? const Color(0xFF0F1623)
                : AppColors.lightBackground,
            gradient: RadialGradient(
              center: const Alignment(0.2, 0.3),
              radius: 1.5,
              colors: AppTheme.currentMode == AppThemeMode.dark
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF0F1623),
                    ]
                  : [
                      AppColors.softGray.withOpacity(0.5),
                      AppColors.lightBackground,
                    ],
            ),
          ),
        ),
        // Heat spots - Danger zones
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: MediaQuery.of(context).size.width * 0.15,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.danger.withOpacity(0.6),
                  AppColors.danger.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        // Heat spots - Safe zones
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25,
          right: MediaQuery.of(context).size.width * 0.1,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.4),
                  AppColors.secondary.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        // Grid overlay for map effect
        Opacity(
          opacity: 0.1,
          child: CustomPaint(painter: GridPainter(), size: Size.infinite),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const gridSize = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
