import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class LanguageSwitcherTile extends StatefulWidget {
  const LanguageSwitcherTile({Key? key}) : super(key: key);

  @override
  State<LanguageSwitcherTile> createState() => _LanguageSwitcherTileState();
}

class _LanguageSwitcherTileState extends State<LanguageSwitcherTile> {
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
