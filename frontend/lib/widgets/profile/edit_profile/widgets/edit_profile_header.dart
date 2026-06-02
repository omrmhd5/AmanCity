import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../data/app_colors.dart';
import '../../../../utils/app_theme.dart';

class EditProfileHeader extends StatelessWidget {
  const EditProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // Title row
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.28),
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.edit.title'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
                Text(
                  'profile.edit.subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
