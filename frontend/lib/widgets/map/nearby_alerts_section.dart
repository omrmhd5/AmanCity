import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../custom_text.dart';
import 'alert_card.dart';

class NearbyAlertsSection extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final VoidCallback? onViewAll;

  const NearbyAlertsSection({Key? key, required this.alerts, this.onViewAll})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: AppTheme.getCardBackgroundColor(),
        border: Border(
          top: BorderSide(color: AppTheme.getBorderColor(), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Nearby Alerts',
                size: 13,
                weight: FontWeight.w600,
                color: AppTheme.getPrimaryTextColor(),
              ),
              GestureDetector(
                onTap: onViewAll ?? () {},
                child: CustomText(
                  text: 'View all',
                  size: 11,
                  weight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Alert cards carousel
          SizedBox(
            height: 140,
            child: alerts.isEmpty
                ? Center(
                    child: CustomText(
                      text: 'No recent alerts',
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return AlertCard(
                        alertType: alert['type'],
                        description: alert['description'],
                        timeAgo: alert['timeAgo'],
                        distance: alert['distance'],
                        borderColor: alert['color'],
                        icon: alert['icon'],
                        onTap: alert['onTap'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
