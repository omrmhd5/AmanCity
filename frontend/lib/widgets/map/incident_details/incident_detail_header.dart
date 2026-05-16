import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../shared/custom_text.dart';

class IncidentDetailHeader extends StatelessWidget {
  final String incidentId;
  final String? title;
  final String? addressText;
  final String? city;
  final DateTime? timestamp;
  final Color? typeColor;
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;

  const IncidentDetailHeader({
    Key? key,
    required this.incidentId,
    this.title,
    this.addressText,
    this.city,
    this.timestamp,
    this.typeColor,
    required this.onBackPressed,
    required this.onSharePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Type-color accent strip
        if (typeColor != null)
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor!.withOpacity(0.0),
                  typeColor!.withOpacity(0.7),
                  typeColor!.withOpacity(0.0),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardBackgroundColor(),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.getBorderColor(),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
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
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.ios_share,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Teal gradient divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.0),
                AppColors.secondary.withOpacity(0.3),
                AppColors.secondary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
