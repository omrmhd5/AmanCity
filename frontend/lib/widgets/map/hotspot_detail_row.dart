import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../shared/custom_text.dart';

class HotspotDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const HotspotDetailRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          size: 13,
          color: AppTheme.getSecondaryTextColor(),
          weight: FontWeight.w500,
        ),
        CustomText(
          text: value,
          size: 13,
          weight: FontWeight.w700,
          color: AppTheme.getPrimaryTextColor(),
        ),
      ],
    );
  }
}
