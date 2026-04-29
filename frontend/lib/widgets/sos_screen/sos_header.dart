import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class SosHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;

  SosHeader({Key? key, this.onBackPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button or placeholder
          SizedBox(
            width: 48,
            child: onBackPressed != null
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppTheme.getPrimaryTextColor(),
                      size: 20,
                    ),
                    onPressed: onBackPressed,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),
          // Centered content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.sos,
                    color: AppColors.danger,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hold the button for 3 seconds to alert your trusted contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Balance spacer
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
