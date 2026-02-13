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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
            const SizedBox(width: 8),
            CustomText(
              text: 'Getting your location...',
              size: 12,
              weight: FontWeight.w500,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ],
        ),
      ),
    );
  }
}
