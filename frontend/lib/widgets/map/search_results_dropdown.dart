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

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          shadowColor: Colors.black.withOpacity(0.15),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 380),
            decoration: BoxDecoration(
              color: AppTheme.currentMode == AppThemeMode.dark
                  ? AppColors.primary
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final place = results[index];
                final isLast = index == results.length - 1;

                return Column(
                  children: [
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: GestureDetector(
                          onTap: () => onResultTap(place),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: place.markerColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: place.markerColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  place.icon,
                                  color: place.markerColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.getPrimaryTextColor(),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            place.address,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppTheme.getSecondaryTextColor(),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: place.markerColor
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            place.typeLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: place.markerColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Divider(
                          height: 1,
                          color: AppTheme.getBorderColor(),
                          thickness: 1,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
