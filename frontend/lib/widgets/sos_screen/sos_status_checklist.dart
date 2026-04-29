import 'package:flutter/material.dart';

import '../../data/app_colors.dart';

class SosStatusChecklist extends StatelessWidget {
  final bool locationAcquired;
  final bool contactsNotified;
  final int recordingSeconds;
  final String? locationText;

  const SosStatusChecklist({
    Key? key,
    required this.locationAcquired,
    required this.contactsNotified,
    required this.recordingSeconds,
    this.locationText,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tracking Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 24, color: Colors.white.withOpacity(0.1)),

          // Location row
          _StatusRow(
            iconData: locationAcquired ? Icons.check : Icons.hourglass_top,
            iconColor: locationAcquired
                ? AppColors.success
                : const Color(0xFFFBBF24),
            title: 'Location Acquired',
            subtitle: locationAcquired
                ? (locationText ?? 'Sent to contacts')
                : 'Acquiring GPS...',
          ),
          const SizedBox(height: 16),

          // Contacts row
          _StatusRow(
            iconData: contactsNotified ? Icons.check : Icons.hourglass_top,
            iconColor: contactsNotified
                ? AppColors.success
                : const Color(0xFFFBBF24),
            title: 'Contacts Notified',
            subtitle: contactsNotified
                ? 'WhatsApp alerts sent'
                : 'Opening WhatsApp...',
          ),
          const SizedBox(height: 16),

          // Recording row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio Recording',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capturing audio evidence...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDuration(recordingSeconds),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatusRow({
    required this.iconData,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.4), width: 1),
          ),
          child: Icon(iconData, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
