import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../screens/sos/incoming_sos_alert_screen.dart';
import '../../services/notifications/notification_service.dart';
import '../../utils/app_theme.dart';

/// Displays a red "Incoming SOS Alert" re-access tile whenever a trusted
/// contact has an active SOS session. Disappears automatically when the
/// session ends. Tapping it re-opens [IncomingSosAlertScreen].
///
/// Self-contained — just drop it anywhere in the widget tree; no
/// configuration required.
class HomeIncomingSosTile extends StatefulWidget {
  const HomeIncomingSosTile({Key? key}) : super(key: key);

  @override
  State<HomeIncomingSosTile> createState() => _HomeIncomingSosTileState();
}

class _HomeIncomingSosTileState extends State<HomeIncomingSosTile> {
  bool _pressed = false;

  void _onTap(IncomingSosSession session) {
    NotificationService.instance.reopenIncomingAlert();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomingSosAlertScreen(
          sessionId: session.sessionId,
          triggerUserName: session.senderName,
          triggerUserPhone: session.senderPhone,
          lat: session.lat,
          lng: session.lng,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IncomingSosSession?>(
      valueListenable: NotificationService.instance.activeIncomingSession,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            _onTap(session);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: _pressed
                ? const Duration(milliseconds: 80)
                : const Duration(milliseconds: 300),
            curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.danger.withOpacity(0.35),
                  width: 0.75,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.25),
                        width: 0.75,
                      ),
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incoming SOS Alert',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.senderName.isNotEmpty ? session.senderName : "A contact"} needs help · Tap to respond',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
