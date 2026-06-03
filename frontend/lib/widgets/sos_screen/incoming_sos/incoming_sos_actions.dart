import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../utils/app_theme.dart';

class IncomingSosActions extends StatelessWidget {
  final String triggerUserName;
  final VoidCallback onOpenLiveTracking;
  final VoidCallback onCallUser;
  final VoidCallback onCallEmergency;
  final VoidCallback onMuteAlarm;
  final bool alarmMuted;

  const IncomingSosActions({
    Key? key,
    required this.triggerUserName,
    required this.onOpenLiveTracking,
    required this.onCallUser,
    required this.onCallEmergency,
    required this.onMuteAlarm,
    required this.alarmMuted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButtons(),
        const SizedBox(height: 14),
        _buildMuteAlarmButton(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenLiveTracking,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                'sos.open_live_tracking'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Call user
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCallUser,
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(
                    triggerUserName.isEmpty
                        ? 'sos.call'.tr()
                        : 'Call ${triggerUserName.split(' ').first}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142744),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Call 122
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCallEmergency,
                  icon: const Icon(Icons.local_police, size: 18),
                  label: const Text('Call 122'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C2D47),
                    foregroundColor: const Color(0xFFFF6B6B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuteAlarmButton() {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: alarmMuted ? null : onMuteAlarm,
          icon: Icon(
            alarmMuted ? Icons.notifications_off : Icons.volume_off,
            size: 18,
          ),
          label: Text(
            alarmMuted ? 'sos.alarm_muted'.tr() : 'sos.mute_alarm'.tr(),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: isDark
                ? Colors.transparent
                : (alarmMuted
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFFFBBF24)),
            foregroundColor: alarmMuted
                ? (isDark ? Colors.white38 : const Color(0xFF6B7280))
                : (isDark ? const Color(0xFFFFB020) : const Color(0xFF1F2937)),
            side: BorderSide(
              color: alarmMuted
                  ? (isDark
                      ? Colors.white12
                      : const Color(0xFF9CA3AF).withOpacity(0.9))
                  : (isDark
                      ? const Color(0xFFFFB020).withOpacity(0.6)
                      : const Color(0xFFF59E0B).withOpacity(0.95)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
