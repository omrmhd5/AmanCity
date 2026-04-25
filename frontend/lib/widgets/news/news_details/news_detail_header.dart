import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + Title
          Row(
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.getPrimaryTextColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Type Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: typeConfig.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeConfig.icon, size: 14, color: typeConfig.color),
                const SizedBox(width: 6),
                CustomText(
                  text: incidentType,
                  size: 12,
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
