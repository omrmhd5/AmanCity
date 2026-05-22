import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class NewsHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const NewsHeader({Key? key, this.onBackPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.getBackgroundColor().withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.getBorderColor().withOpacity(0.15),
                  width: 0.75,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.getPrimaryTextColor(),
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Twitter Incidents',
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              'Grok AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
