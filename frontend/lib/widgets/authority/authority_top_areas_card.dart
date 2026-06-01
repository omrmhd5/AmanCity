import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared/custom_text.dart';
import '../../../services/authority/authority_api_service.dart';

/// Bar chart of top affected areas/cities.
class AuthorityTopAreasCard extends StatelessWidget {
  final List<AreaBreakdown> topAreas;

  const AuthorityTopAreasCard({Key? key, required this.topAreas})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (topAreas.isEmpty) return const SizedBox.shrink();

    final maxCount = topAreas.fold(0, (m, a) => a.count > m ? a.count : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('MOST AFFECTED AREAS'),
          const SizedBox(height: 14),
          ...topAreas.map((a) => _areaRow(a, maxCount)).toList(),
        ],
      ),
    );
  }

  Widget _areaRow(AreaBreakdown breakdown, int max) {
    final ratio = max > 0 ? breakdown.count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  text: breakdown.area,
                  size: 13,
                  weight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              CustomText(
                text: '${breakdown.count}',
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 5,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorderColor(),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 5,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.warning, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return CustomText(
      text: label,
      size: 11,
      weight: FontWeight.w800,
      color: AppTheme.getSecondaryTextColor(),
    );
  }
}
