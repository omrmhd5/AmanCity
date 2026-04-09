import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/emergency_poi.dart';

class SearchResultsDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final Function(Map<String, dynamic>) onResultTap;

  const SearchResultsDropdown({
    Key? key,
    required this.results,
    required this.onResultTap,
  }) : super(key: key);

  /// Get icon and color for a search result
  /// For POIs (hospital, police, fire) use their specific icons
  /// For generic places use a generic location icon
  Map<String, dynamic> _getIconAndColor(Map<String, dynamic> place) {
    final type = place['type'] as String?;

    if (type == 'hospital') {
      return {
        'icon': Icons.local_hospital,
        'color': const Color(0xFFEF4444), // Red
      };
    } else if (type == 'police') {
      return {
        'icon': Icons.local_police,
        'color': const Color(0xFF3B82F6), // Blue
      };
    } else if (type == 'fire') {
      return {
        'icon': Icons.fire_truck,
        'color': const Color(0xFFF59E0B), // Orange
      };
    } else {
      // Generic place - use default icon and color
      return {'icon': Icons.location_on, 'color': AppColors.secondary};
    }
  }

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
                final iconData = _getIconAndColor(place);
                final icon = iconData['icon'] as IconData;
                final color = iconData['color'] as Color;

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
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place['name'] ?? 'Unknown',
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
                                            place['address'] ?? '',
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
                                        if (place['type'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getTypeLabel(place['type']),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: color,
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

  /// Convert type code to display label
  String _getTypeLabel(String? type) {
    switch (type) {
      case 'hospital':
        return 'Hospital';
      case 'police':
        return 'Police Station';
      case 'fire':
        return 'Fire Station';
      default:
        return '';
    }
  }
}
