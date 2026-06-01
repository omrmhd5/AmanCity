import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared/custom_text.dart';
import '../../../services/authority/authority_api_service.dart';

/// Compact tile for a single incident in the authority incidents list.
class AuthorityIncidentTile extends StatelessWidget {
  final AuthorityIncident incident;

  const AuthorityIncidentTile({Key? key, required this.incident})
    : super(key: key);

  Color get _sourceColor =>
      incident.isOsint ? AppColors.warning : AppColors.success;

  String get _sourceLabel => incident.isOsint ? 'OSINT' : 'HUMAN';

  String get _timeAgo {
    final diff = DateTime.now().difference(incident.timestamp);
    if (diff.inMinutes < 1) return 'Just now';
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
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: Row(
        children: [
          // Source dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _sourceColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: incident.title,
                  size: 13,
                  weight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    CustomText(
                      text: incident.type,
                      size: 11,
                      weight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                    if (incident.location.isNotEmpty) ...[
                      CustomText(
                        text: '  •  ',
                        size: 11,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      Expanded(
                        child: CustomText(
                          text: incident.location,
                          size: 11,
                          weight: FontWeight.w400,
                          color: AppTheme.getSecondaryTextColor(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right meta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _sourceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: CustomText(
                  text: _sourceLabel,
                  size: 10,
                  weight: FontWeight.w700,
                  color: _sourceColor,
                ),
              ),
              const SizedBox(height: 4),
              CustomText(
                text: _timeAgo,
                size: 11,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
