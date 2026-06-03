import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../models/incidents/osint_incident.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';

class NewsDetailConfidenceSection extends StatelessWidget {
  final OsintIncident incident;

  const NewsDetailConfidenceSection({Key? key, required this.incident})
    : super(key: key);

  Color _getConfidenceColor() {
    if (incident.osintConfidence >= 0.7) return AppColors.danger;
    if (incident.osintConfidence >= 0.4) return AppColors.warning;
    return AppColors.success;
  }

  String _getLevelTextKey() {
    if (incident.osintConfidence >= 0.7) return 'news.level_text_high';
    if (incident.osintConfidence >= 0.4) return 'news.level_text_medium';
    return 'news.level_text_low';
  }

  String _getLevelDescKey() {
    if (incident.osintConfidence >= 0.7) return 'news.level_desc_high';
    if (incident.osintConfidence >= 0.4) return 'news.level_desc_medium';
    return 'news.level_desc_low';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConfidenceColor();
    final percent = (incident.osintConfidence * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 15,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'news.confidence_label'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getSecondaryTextColor(),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  _getLevelTextKey().tr(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Row(
              children: [
                // Circular gauge
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Track ring
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(
                            color.withOpacity(0.12),
                          ),
                        ),
                      ),
                      // Value ring
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: incident.osintConfidence,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      // Center text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: color,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'news.score_label'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right side info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'news.confidence_score'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getPrimaryTextColor(),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Mini tick marks for Low / Med / High
                      Row(
                        children: [
                          _LevelDot(
                            label: 'news.level_low'.tr(),
                            active: incident.osintConfidence < 0.4,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          _LevelDot(
                            label: 'news.level_med'.tr(),
                            active:
                                incident.osintConfidence >= 0.4 &&
                                incident.osintConfidence < 0.7,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          _LevelDot(
                            label: 'news.level_high'.tr(),
                            active: incident.osintConfidence >= 0.7,
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _getLevelDescKey().tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelDot extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;

  const _LevelDot({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : color.withOpacity(0.2),
            boxShadow: active
                ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? color : AppTheme.getSecondaryTextColor(),
          ),
        ),
      ],
    );
  }
}
