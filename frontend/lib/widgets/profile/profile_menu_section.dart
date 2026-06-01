import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../services/core/connectivity_service.dart';
import 'home_location_selector.dart';
import 'logout_section.dart';
import 'app_theme_selector.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── APPEARANCE ─────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.palette_rounded,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'profile.appearance'.tr(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.0),
                  AppColors.secondary.withValues(alpha: 0.20),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AppThemeSelector(),
          const SizedBox(height: 24),
          // ─── PREFERENCES ────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'profile.preferences'.tr(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Teal gradient divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.0),
                  AppColors.secondary.withValues(alpha: 0.20),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          HomeLocationSelector(isCompact: true),
          const SizedBox(height: 10),
          const _LanguageSwitcherTile(),
          const SizedBox(height: 10),
          LogoutSection(isCompact: true),
          const SizedBox(height: 10),
          const _ResetOnboardingTile(),
        ],
      ),
    );
  }
}

// ─── Language Switcher Tile ───────────────────────────────────────────────────

class _LanguageSwitcherTile extends StatefulWidget {
  const _LanguageSwitcherTile();

  @override
  State<_LanguageSwitcherTile> createState() => _LanguageSwitcherTileState();
}

class _LanguageSwitcherTileState extends State<_LanguageSwitcherTile> {
  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackgroundColor(),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.20),
                    width: 0.75,
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'profile.language'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ),
              Row(
                children: [
                  _LangButton(
                    label: 'EN',
                    isActive: !isArabic,
                    onTap: () => context.setLocale(const Locale('en')),
                  ),
                  const SizedBox(width: 8),
                  _LangButton(
                    label: 'AR',
                    isActive: isArabic,
                    onTap: () => context.setLocale(const Locale('ar')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.secondary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.secondary.withOpacity(0.5)
                : AppTheme.getBorderColor(),
            width: isActive ? 1.5 : 0.75,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive
                ? AppColors.secondary
                : AppTheme.getSecondaryTextColor(),
          ),
        ),
      ),
    );
  }
}

// ─── Reset Onboarding Tile ───────────────────────────────────────────────────

class _ResetOnboardingTile extends StatefulWidget {
  const _ResetOnboardingTile();

  @override
  State<_ResetOnboardingTile> createState() => _ResetOnboardingTileState();
}

class _ResetOnboardingTileState extends State<_ResetOnboardingTile> {
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    if (mounted) {
      ConnectivityService.instance.setBypass(true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetOnboarding,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: _pressed ? 90 : 300),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCardBackgroundColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.getBorderColor(), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.20),
                        width: 0.75,
                      ),
                    ),
                    child: const Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.reset_onboarding'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'profile.reset_onboarding_subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
