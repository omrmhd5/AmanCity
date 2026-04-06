import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/emergency_poi.dart';

class SearchResultsDropdown extends StatelessWidget {
  final List<EmergencyPOI> results;
  final Function(EmergencyPOI) onResultTap;

  const SearchResultsDropdown({
    Key? key,
    required this.results,
    required this.onResultTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: AppTheme.currentMode == AppThemeMode.dark
              ? AppColors.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              leading: Icon(
                Icons.location_on,
                color: AppColors.secondary,
                size: 20,
              ),
              title: Text(
                place.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getPrimaryTextColor(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                place.address,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onResultTap(place),
            );
          },
        ),
      ),
    );
  }
}
