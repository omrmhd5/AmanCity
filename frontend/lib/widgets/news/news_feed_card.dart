import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/incidents/osint_incident.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../../data/incident_types_config.dart';
import '../shared/custom_text.dart';
import '../../utils/localization_formatter.dart';

class NewsFeedCard extends StatefulWidget {
  final OsintIncident incident;
  final VoidCallback onTap;

  const NewsFeedCard({Key? key, required this.incident, required this.onTap})
    : super(key: key);

  @override
  State<NewsFeedCard> createState() => _NewsFeedCardState();
}

class _NewsFeedCardState extends State<NewsFeedCard> {
  bool _pressed = false;

  /// Get color based on osintConfidence severity
  Color _getConfidenceColor() {
    if (widget.incident.osintConfidence >= 0.7) {
      return AppColors.danger; // Red for high severity
    } else if (widget.incident.osintConfidence >= 0.4) {
      return AppColors.warning; // Amber for medium
    } else {
      return AppColors.success; // Green for low
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeConfig = IncidentTypesConfig.getByKey(widget.incident.type);
    final confidenceColor = _getConfidenceColor();

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: _pressed
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              typeConfig.color.withOpacity(0.04),
              AppTheme.getCardBackgroundColor(),
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: typeConfig.color, width: 4)),
            boxShadow: [
              BoxShadow(
                color: typeConfig.color.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type Badge + Time + Source Badge
              Row(
                children: [
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeConfig.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeConfig.icon,
                          size: 12,
                          color: typeConfig.color,
                        ),
                        const SizedBox(width: 4),
                        CustomText(
                          text: () {
                            final key = 'incident_type.${widget.incident.type}';
                            final t = key.tr();
                            return t == key ? widget.incident.type : t;
                          }(),
                          size: 10,
                          weight: FontWeight.w600,
                          color: typeConfig.color,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Time
                  CustomText(
                    text: LocalizationFormatter.formatTimeAgo(context, widget.incident.timestamp),
                    size: 11,
                    weight: FontWeight.w900,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              CustomText(
                text: widget.incident.title,
                size: 13,
                weight: FontWeight.w600,
                color: AppTheme.getPrimaryTextColor(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Location + Precision Badge
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: CustomText(
                      text: widget.incident.locationText,
                      size: 11,
                      weight: FontWeight.w400,
                      color: AppTheme.getSecondaryTextColor(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.incident.locationPrecision == "EXACT"
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CustomText(
                      text: widget.incident.locationPrecision == 'EXACT'
                          ? 'news.precision_exact'.tr()
                          : 'news.precision_approximate'.tr(),
                      size: 8,
                      weight: FontWeight.w600,
                      color: widget.incident.locationPrecision == "EXACT"
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Confidence Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'news.ai_confidence'.tr(),
                        size: 10,
                        weight: FontWeight.w500,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      CustomText(
                        text:
                            '${(widget.incident.osintConfidence * 100).toStringAsFixed(0)}%',
                        size: 10,
                        weight: FontWeight.w600,
                        color: confidenceColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.incident.osintConfidence,
                      minHeight: 6,
                      backgroundColor: AppTheme.getBorderColor(),
                      valueColor: AlwaysStoppedAnimation(confidenceColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Twitter Source Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    CustomText(
                      text: widget.incident.sourceUrls.length == 1
                          ? 'news.sources_count_one'.tr()
                          : 'news.sources_count_other'.tr(namedArgs: {'count': '${widget.incident.sourceUrls.length}'}),
                      size: 10,
                      weight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
