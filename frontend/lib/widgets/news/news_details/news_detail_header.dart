import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../data/incident_types_config.dart';
import '../../shared/custom_text.dart';

class NewsDetailHeader extends StatelessWidget {
  final String title;
  final String incidentType;
  final VoidCallback onBackPressed;

  const NewsDetailHeader({
    Key? key,
    required this.title,
    required this.incidentType,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeConfig = IncidentTypesConfig.getByKey(incidentType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onBackPressed,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Type Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: typeConfig.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: typeConfig.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeConfig.icon, size: 13, color: typeConfig.color),
                const SizedBox(width: 6),
                CustomText(
                  text: incidentType,
                  size: 11,
                  weight: FontWeight.w600,
                  color: typeConfig.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
