import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_text.dart';

class IncidentDetailHeader extends StatelessWidget {
  final String incidentId;
  final String? addressText;
  final String? city;
  final DateTime? timestamp;
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;

  const IncidentDetailHeader({
    Key? key,
    required this.incidentId,
    this.addressText,
    this.city,
    this.timestamp,
    required this.onBackPressed,
    required this.onSharePressed,
  }) : super(key: key);

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
    return Container(
      color: AppTheme.getBackgroundColor(),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.95),
            border: Border(
              bottom: BorderSide(color: AppTheme.getBorderColor(), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: 'INCIDENT #$incidentId',
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    const SizedBox(height: 2),
                    if (addressText != null)
                      Flexible(
                        child: CustomText(
                          text: addressText!.toUpperCase(),
                          size: 10,
                          weight: FontWeight.w400,
                          color: AppTheme.getSecondaryTextColor(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else if (city != null)
                      CustomText(
                        text: city!.toUpperCase(),
                        size: 10,
                        weight: FontWeight.w400,
                        color: AppTheme.getSecondaryTextColor(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        text: _formatTime12Hour(timestamp!),
                        size: 9,
                        weight: FontWeight.w400,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSharePressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.ios_share,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
