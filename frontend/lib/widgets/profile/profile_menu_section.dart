import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'map_theme_selector.dart';
import 'home_location_selector.dart';
import 'logout_section.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryTextColor(),
              ),
            ),
          ),

          // Appearance Tile
          MapThemeSelector(isCompact: true),
          const SizedBox(height: 12),

          // Home Location Tile
          HomeLocationSelector(isCompact: true),
          const SizedBox(height: 12),

          // Sign Out Tile
          LogoutSection(isCompact: true),
        ],
      ),
    );
  }
}
