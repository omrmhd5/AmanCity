import 'package:flutter/material.dart';

class MapActionButtons extends StatelessWidget {
  final VoidCallback? onReportPressed;
  final VoidCallback onMyLocationPressed;

  const MapActionButtons({
    Key? key,
    required this.onReportPressed,
    required this.onMyLocationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Report button
        Positioned(
          right: 16,
          bottom: 180,
          child: FloatingActionButton(
            heroTag: 'report_button',
            backgroundColor: Colors.red.shade500,
            onPressed: onReportPressed,
            child: const Icon(
              Icons.announcement,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // My Location button
        Positioned(
          right: 16,
          bottom: 110,
          child: FloatingActionButton(
            heroTag: 'my_location_button',
            backgroundColor: Colors.blue.shade400,
            onPressed: onMyLocationPressed,
            child: const Icon(Icons.my_location, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}
