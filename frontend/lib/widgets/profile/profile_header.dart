import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'Manage your account and preferences',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
        ],
      ),
    );
  }
}
