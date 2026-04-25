import 'package:flutter/material.dart';
import '../../../models/osint_incident.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/app_colors.dart';
import '../../shared/custom_text.dart';

class NewsDetailLocationSection extends StatelessWidget {
  final OsintIncident incident;

  const NewsDetailLocationSection({Key? key, required this.incident})
    : super(key: key);

  String _formatTime12Hour(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Location',
                size: 14,
                weight: FontWeight.w600,
                color: AppTheme.getPrimaryTextColor(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: incident.timeAgo,
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    text: _formatTime12Hour(incident.timestamp),
                    size: 10,
                    weight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: incident.locationText,
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppTheme.getPrimaryTextColor(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: incident.locationPrecision == "EXACT"
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        text: incident.locationPrecision,
                        size: 10,
                        weight: FontWeight.w600,
                        color: incident.locationPrecision == "EXACT"
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomText(
                  text:
                      '${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}',
                  size: 11,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
