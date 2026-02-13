import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../custom_text.dart';

class MapFilterSection extends StatefulWidget {
  final ValueChanged<String?>? onFilterChanged;

  const MapFilterSection({Key? key, this.onFilterChanged}) : super(key: key);

  @override
  State<MapFilterSection> createState() => _MapFilterSectionState();
}

class _MapFilterSectionState extends State<MapFilterSection> {
  String? selectedFilter;
  final searchController = TextEditingController();

  final List<Map<String, dynamic>> filters = [
    {'label': 'Safe Zones', 'icon': Icons.verified_user},
    {'label': 'Hospitals', 'icon': Icons.local_hospital},
    {'label': 'Police', 'icon': Icons.local_police},
    {'label': 'Cafés', 'icon': Icons.local_cafe},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Search bar and filter button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.getCardBackgroundColor(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.getBorderColor(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(
                            color: AppTheme.getPrimaryTextColor(),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            hintStyle: TextStyle(
                              color: AppTheme.getSecondaryTextColor(),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.tune,
                      color: AppTheme.getPrimaryTextColor(),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter['label'];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == filters.length - 1 ? 0 : 8,
                  ),
                  child: FilterChip(
                    label: Row(
                      children: [
                        Icon(
                          filter['icon'],
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.getSecondaryTextColor(),
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                          text: filter['label'],
                          size: 11,
                          weight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.getSecondaryTextColor(),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilter = selected ? filter['label'] : null;
                        widget.onFilterChanged?.call(selectedFilter);
                      });
                    },
                    backgroundColor: AppTheme.getCardBackgroundColor(),
                    selectedColor: AppColors.secondary,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.secondary
                          : AppTheme.getBorderColor(),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
