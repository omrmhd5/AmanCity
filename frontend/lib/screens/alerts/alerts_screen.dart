import 'package:flutter/material.dart';
import '../../models/alerts/alert_notification.dart';
import '../../services/notifications/notification_service.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../data/incident_types_config.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            _animated(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.getBackgroundColor().withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.getBorderColor().withOpacity(0.15),
                            width: 0.75,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.getPrimaryTextColor(),
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Alerts',
                      style: TextStyle(
                        color: AppTheme.getPrimaryTextColor(),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<List<AlertNotification>>(
                          valueListenable: NotificationService.instance.alerts,
                          builder: (context, list, _) {
                            final hasUnread = list.any((a) => !a.isRead);
                            if (!hasUnread) return const SizedBox(width: 40);
                            return GestureDetector(
                              onTap: NotificationService.instance.markAllRead,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Read all',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        ValueListenableBuilder<List<AlertNotification>>(
                          valueListenable: NotificationService.instance.alerts,
                          builder: (context, list, _) {
                            if (list.isEmpty) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () => _confirmClear(context),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              start: 0.0,
              end: 0.5,
            ),
            // Teal gradient divider
            _animated(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.0),
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              start: 0.05,
              end: 0.55,
            ),
            Expanded(
              child: ValueListenableBuilder<List<AlertNotification>>(
                valueListenable: NotificationService.instance.alerts,
                builder: (context, list, _) {
                  if (list.isEmpty) return _buildEmptyState();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      _animated(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_rounded,
                                size: 15,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'RECENT ALERTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.getSecondaryTextColor(),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        start: 0.1,
                        end: 0.6,
                      ),
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 0),
                          itemBuilder: (context, i) {
                            final delay = (i * 0.06).clamp(0.0, 0.4);
                            return _animated(
                              _AlertCard(alert: list[i]),
                              start: 0.15 + delay,
                              end: (0.65 + delay).clamp(0.0, 1.0),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.2),
                width: 0.75,
              ),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 40,
              color: AppColors.secondary.withOpacity(0.6),
            ),
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear all alerts?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will remove all notifications from your inbox.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      NotificationService.instance.clearAll();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AlertCard extends StatefulWidget {
  final AlertNotification alert;
  const _AlertCard({required this.alert});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final stripeColor = _stripeColor();
    final iconData = _icon();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        NotificationService.instance.markRead(widget.alert.id);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 300),
        curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: widget.alert.isRead
                ? AppTheme.getCardBackgroundColor()
                : stripeColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.alert.isRead
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
                                widget.alert.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: widget.alert.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: AppTheme.getPrimaryTextColor(),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Unread dot
                            if (!widget.alert.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(
                                  left: 6,
                                  right: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: stripeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Incident type badge (if available)
                        if (widget.alert.incidentType != null)
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
                                  widget.alert.incidentType!,
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
                          widget.alert.body,
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
                              _timeAgo(widget.alert.timestamp),
                              Icons.access_time,
                              AppTheme.getSecondaryTextColor(),
                            ),
                            if (widget.alert.distanceKm != null)
                              _chip(
                                '${widget.alert.distanceKm!.toStringAsFixed(1)} km away',
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
      ),
    );
  }

  Color _stripeColor() {
    if (widget.alert.alertType == AlertType.nearbyIncident &&
        widget.alert.incidentType != null) {
      return IncidentTypesConfig.getByKey(widget.alert.incidentType!).color;
    }

    switch (widget.alert.alertType) {
      case AlertType.nearbyIncident:
        return Colors.red.shade600;
      case AlertType.hotspotEntry:
        return Colors.orange.shade600;
      case AlertType.system:
        return Colors.blue.shade600;
    }
  }

  IconData _icon() {
    if (widget.alert.alertType == AlertType.nearbyIncident &&
        widget.alert.incidentType != null) {
      return IncidentTypesConfig.getByKey(widget.alert.incidentType!).icon;
    }

    switch (widget.alert.alertType) {
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
