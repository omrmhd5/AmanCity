import 'package:flutter/material.dart';
import '../models/alert_notification.dart';
import '../services/notification_service.dart';
import '../data/app_colors.dart';
import '../utils/app_theme.dart';
import '../data/incident_types_config.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(),
        elevation: 0,
        title: Text(
          'Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getPrimaryTextColor(),
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.getPrimaryTextColor()),
        actions: [
          ValueListenableBuilder<List<AlertNotification>>(
            valueListenable: NotificationService.instance.alerts,
            builder: (context, list, _) {
              final hasUnread = list.any((a) => !a.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: NotificationService.instance.markAllRead,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<List<AlertNotification>>(
            valueListenable: NotificationService.instance.alerts,
            builder: (context, list, _) {
              if (list.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear all',
                onPressed: () => _confirmClear(context),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AlertNotification>>(
        valueListenable: NotificationService.instance.alerts,
        builder: (context, list, _) {
          if (list.isEmpty) return _buildEmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, i) => _AlertCard(alert: list[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: AppColors.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All Clear',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No alerts at the moment.\nYou\'re in a safe zone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.getCardBackgroundColor(),
        title: Text(
          'Clear all alerts?',
          style: TextStyle(color: AppTheme.getPrimaryTextColor()),
        ),
        content: Text(
          'This will remove all notifications from your inbox.',
          style: TextStyle(color: AppTheme.getSecondaryTextColor()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getSecondaryTextColor()),
            ),
          ),
          TextButton(
            onPressed: () {
              NotificationService.instance.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AlertCard extends StatelessWidget {
  final AlertNotification alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final stripeColor = _stripeColor();
    final iconData = _icon();

    return GestureDetector(
      onTap: () => NotificationService.instance.markRead(alert.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: alert.isRead
              ? AppTheme.getCardBackgroundColor()
              : stripeColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead
                ? AppTheme.getBorderColor()
                : stripeColor.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colour stripe
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon circle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stripeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: stripeColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: alert.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Unread dot
                          if (!alert.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6, right: 4),
                              decoration: BoxDecoration(
                                color: stripeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Incident type badge (if available)
                      if (alert.incidentType != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: stripeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: stripeColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              IncidentTypesConfig.getByKey(
                                alert.incidentType!,
                              ).displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: stripeColor,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        alert.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(
                            _timeAgo(alert.timestamp),
                            Icons.access_time,
                            AppTheme.getSecondaryTextColor(),
                          ),
                          if (alert.distanceKm != null)
                            _chip(
                              '${alert.distanceKm!.toStringAsFixed(1)} km away',
                              Icons.location_on_outlined,
                              stripeColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Color _stripeColor() {
    // For nearby incidents, use the incident type config color
    if (alert.alertType == AlertType.nearbyIncident &&
        alert.incidentType != null) {
      return IncidentTypesConfig.getByKey(alert.incidentType!).color;
    }

    switch (alert.alertType) {
      case AlertType.nearbyIncident:
        return Colors.red.shade600;
      case AlertType.hotspotEntry:
        return Colors.orange.shade600;
      case AlertType.system:
        return Colors.blue.shade600;
    }
  }

  IconData _icon() {
    // For nearby incidents, use the incident type config icon
    if (alert.alertType == AlertType.nearbyIncident &&
        alert.incidentType != null) {
      return IncidentTypesConfig.getByKey(alert.incidentType!).icon;
    }

    switch (alert.alertType) {
      case AlertType.nearbyIncident:
        return Icons.warning_amber_rounded;
      case AlertType.hotspotEntry:
        return Icons.local_fire_department;
      case AlertType.system:
        return Icons.info_outline;
    }
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
