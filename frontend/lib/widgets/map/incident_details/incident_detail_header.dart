import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/app_colors.dart';
import '../../shared/custom_text.dart';

class IncidentDetailHeader extends StatelessWidget {
  final String incidentId;
  final String? title;
  final String? addressText;
  final String? city;
  final DateTime? timestamp;
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;

  const IncidentDetailHeader({
    Key? key,
    required this.incidentId,
    this.title,
    this.addressText,
    this.city,
    this.timestamp,
    required this.onBackPressed,
    required this.onSharePressed,
  }) : super(key: key);

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
                    if (title != null)
                      CustomText(
                        text: title!,
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      CustomText(
                        text: 'INCIDENT #$incidentId',
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
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
