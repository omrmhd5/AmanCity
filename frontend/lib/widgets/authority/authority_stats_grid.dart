import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared/custom_text.dart';
import '../../../services/authority/authority_api_service.dart';

/// Displays the 6-stat overview row: total, 24h, 7d, human, OSINT, bulk.
class AuthorityStatsGrid extends StatelessWidget {
  final AuthorityStats stats;

  const AuthorityStatsGrid({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('authority.overview'.tr()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'authority.total'.tr(),
                '${stats.total}',
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'authority.last_24h'.tr(),
                '${stats.last24h}',
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'authority.last_7d'.tr(),
                '${stats.last7d}',
                AppColors.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'authority.human'.tr(),
                '${stats.human}',
                AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'authority.osint'.tr(),
                '${stats.osint}',
                AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'authority.clusters'.tr(),
                '${stats.bulkIncidents}',
                AppColors.secondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: label,
            size: 10,
            weight: FontWeight.w800,
            color: AppTheme.getSecondaryTextColor(),
          ),
          const SizedBox(height: 6),
          CustomText(
            text: value,
            size: 26,
            weight: FontWeight.w800,
            color: accent,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return CustomText(
      text: label,
      size: 11,
      weight: FontWeight.w800,
      color: AppTheme.getSecondaryTextColor(),
    );
  }
}
