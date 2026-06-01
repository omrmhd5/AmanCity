import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared/custom_text.dart';
import '../../../services/authority/authority_api_service.dart';

/// Bar chart of top incident types.
class AuthorityTopTypesCard extends StatelessWidget {
  final List<TypeBreakdown> topTypes;

  const AuthorityTopTypesCard({Key? key, required this.topTypes})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (topTypes.isEmpty) return const SizedBox.shrink();

    final maxCount = topTypes.fold(0, (m, t) => t.count > m ? t.count : m);

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
          _sectionLabel('authority.top_incident_types'.tr()),
          const SizedBox(height: 14),
          ...topTypes.map((t) => _typeRow(t, maxCount)).toList(),
        ],
      ),
    );
  }

  Widget _typeRow(TypeBreakdown breakdown, int max) {
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
                  text: breakdown.type,
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
                color: AppColors.secondary,
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
                      color: AppColors.secondary,
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
