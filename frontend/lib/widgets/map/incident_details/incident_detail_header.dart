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

  const IncidentDetailHeader({
    Key? key,
    required this.incidentId,
    this.title,
    this.addressText,
    this.city,
    this.timestamp,
    this.typeColor,
    required this.onBackPressed,
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
            children: [
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
                onTap: onBackPressed,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 28,
                  color: AppColors.secondary,
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
