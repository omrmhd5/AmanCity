import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared/custom_text.dart';
import '../../../services/authority/authority_api_service.dart';

/// Tile for an active SOS session.
class AuthoritySosTile extends StatelessWidget {
  final AuthoritySosSession session;

  const AuthoritySosTile({Key? key, required this.session}) : super(key: key);

  String get _timeAgo {
    final diff = DateTime.now().difference(session.createdAt);
    if (diff.inMinutes < 1) return 'common.just_now'.tr();
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          // SOS indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency,
              color: AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: session.userName,
                  size: 13,
                  weight: FontWeight.w700,
                ),
                if (session.userPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    text: session.userPhone,
                    size: 12,
                    weight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
                const SizedBox(height: 3),
                CustomText(
                  text:
                      'Lat ${session.lat.toStringAsFixed(4)}, Lng ${session.lng.toStringAsFixed(4)}',
                  size: 11,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: CustomText(
                  text: 'common.active'.tr(),
                  size: 10,
                  weight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 4),
              CustomText(
                text: _timeAgo,
                size: 11,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
