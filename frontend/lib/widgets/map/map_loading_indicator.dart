import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../custom_text.dart';

class MapLoadingIndicator extends StatelessWidget {
  const MapLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
            const SizedBox(height: 12),
            CustomText(
              text: 'Getting your location...',
              size: 13,
              weight: FontWeight.w600,
              color: AppTheme.getPrimaryTextColor(),
            ),
            const SizedBox(height: 4),
            CustomText(
              text: 'Please wait',
              size: 11,
              weight: FontWeight.w400,
              color: AppTheme.getSecondaryTextColor().withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
