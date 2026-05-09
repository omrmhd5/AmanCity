import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../screens/onboarding_screen.dart';
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
          const SizedBox(height: 12),

          // Reset Onboarding Tile
          _ResetOnboardingButton(),
        ],
      ),
    );
  }
}

// ─── Reset Onboarding Button ────────────────────────────────────────────────

class _ResetOnboardingButton extends StatelessWidget {
  const _ResetOnboardingButton();

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _resetOnboarding(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.restart_alt_outlined,
                size: 20,
                color: AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reset Onboarding',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
