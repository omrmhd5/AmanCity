import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/profile/map_theme_selector.dart';
import '../widgets/profile/home_location_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(),
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Settings Section Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Map Theme Selector Widget
          const MapThemeSelector(),
          const SizedBox(height: 24),
          // Home Location Selector Widget
          const HomeLocationSelector(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
