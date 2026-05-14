import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/profile/profile_card.dart';
import '../../widgets/profile/profile_menu_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            children: [
              // Top Navigation Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ),

              // Profile Card with User Info
              ProfileCard(user: user),

              // Settings Menu (Appearance, Location, Sign Out)
              const ProfileMenuSection(),

              // Version Info
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 32.0),
                child: Center(
                  child: Text(
                    'Version 1.0.0 • Build 1',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
