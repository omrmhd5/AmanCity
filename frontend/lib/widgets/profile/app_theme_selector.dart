import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class AppThemeSelector extends StatefulWidget {
  const AppThemeSelector({super.key});

  @override
  State<AppThemeSelector> createState() => _AppThemeSelectorState();
}

class _AppThemeSelectorState extends State<AppThemeSelector> {
  AppThemeMode _current = AppTheme.currentMode;

  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() => _current = AppTheme.currentMode);
  }

  Future<void> _select(AppThemeMode mode) async {
    if (_current == mode) return;
    await AppTheme.setTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row label
              Row(
                children: [
                  const Icon(
                    Icons.contrast_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'profile.app_theme'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.25),
                        width: 0.75,
                      ),
                    ),
                    child: Text(
                      _current == AppThemeMode.dark
                          ? 'profile.dark'.tr()
                          : 'profile.light'.tr(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Two option cards
              Row(
                children: [
                  Expanded(
                    child: _ThemeOptionCard(
                      label: 'profile.dark'.tr(),
                      icon: Icons.dark_mode_rounded,
                      isActive: _current == AppThemeMode.dark,
                      onTap: () => _select(AppThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeOptionCard(
                      label: 'profile.light'.tr(),
                      icon: Icons.wb_sunny_rounded,
                      isActive: _current == AppThemeMode.light,
                      onTap: () => _select(AppThemeMode.light),
                    ),
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

// ─── Individual option card ──────────────────────────────────────────────────

class _ThemeOptionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ThemeOptionCard> createState() => _ThemeOptionCardState();
}

class _ThemeOptionCardState extends State<_ThemeOptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: Duration(milliseconds: _pressed ? 80 : 300),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.secondary.withValues(alpha: 0.12)
                : AppTheme.getCardBackgroundColor(),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.secondary.withValues(alpha: 0.55)
                  : AppTheme.getBorderColor(),
              width: widget.isActive ? 1.5 : 1,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: widget.isActive
                    ? AppColors.secondary
                    : AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: widget.isActive
                      ? AppColors.secondary
                      : AppTheme.getSecondaryTextColor(),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isActive ? 1.0 : 0.0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
