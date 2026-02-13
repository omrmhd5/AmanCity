import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

enum NavItem { map, report, home, alerts, profile }

class BottomNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.currentItem,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.currentMode == AppThemeMode.dark
            ? AppColors.primary
            : AppColors.white,
        border: Border(
          top: BorderSide(color: AppTheme.getBorderColor(), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(icon: Icons.map, label: 'Map', item: NavItem.map),
              _buildNavItem(
                icon: Icons.edit,
                label: 'Report',
                item: NavItem.report,
              ),
              _buildHomeButton(),
              _buildNavItem(
                icon: Icons.notifications,
                label: 'Alerts',
                item: NavItem.alerts,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                item: NavItem.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required NavItem item,
  }) {
    final isSelected = currentItem == item;
    return GestureDetector(
      onTap: () => onItemTapped(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppColors.secondary
                : AppTheme.getSecondaryTextColor(),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? AppColors.secondary
                  : AppTheme.getSecondaryTextColor(),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    final isSelected = currentItem == NavItem.home;
    return GestureDetector(
      onTap: () => onItemTapped(NavItem.home),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.secondary : Colors.transparent,
          border: Border.all(
            color: AppColors.secondary,
            width: isSelected ? 0 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Icon(
          Icons.home,
          color: isSelected
              ? Colors.white
              : AppTheme.currentMode == AppThemeMode.dark
              ? AppColors.secondary
              : AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}
