import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import 'onboarding_screen.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _pageController.dispose();
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = 1);
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('initial_setup_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/logos/AmanCity_Logo_Only.png',
                      height: 34,
                      errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 34),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentStep + 1}/2',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _LanguageStep(onNext: _nextStep),
                  _ThemeStep(onNext: _nextStep),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  final VoidCallback onNext;
  const _LanguageStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.language, size: 80, color: AppColors.secondary),
          const SizedBox(height: 32),
          Text(
            'profile.select_language'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر لغتك المفضلة\nChoose your preferred language',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 48),
          _SelectionCard(
            title: '🇺🇸 English',
            subtitle: 'English Language',
            isSelected: currentLocale == 'en',
            onTap: () {
              context.setLocale(const Locale('en'));
            },
          ),
          const SizedBox(height: 16),
          _SelectionCard(
            title: '🇪🇬 العربية',
            subtitle: 'اللغة العربية',
            isSelected: currentLocale == 'ar',
            onTap: () {
              context.setLocale(const Locale('ar'));
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              currentLocale == 'ar' ? 'متابعة' : 'Continue',
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ThemeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _ThemeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.palette_outlined, size: 80, color: AppColors.secondary),
          const SizedBox(height: 32),
          Text(
            'profile.app_theme'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.locale.languageCode == 'ar' 
              ? 'يمكنك تغيير هذا لاحقاً من الإعدادات'
              : 'This can be changed later from settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: _SelectionCard(
                  title: 'profile.theme_light'.tr(),
                  icon: Icons.light_mode,
                  isSelected: !isDark,
                  onTap: () {
                    AppTheme.setTheme(AppThemeMode.light);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SelectionCard(
                  title: 'profile.theme_dark'.tr(),
                  icon: Icons.dark_mode,
                  isSelected: isDark,
                  onTap: () {
                    AppTheme.setTheme(AppThemeMode.dark);
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'common.continue_btn'.tr(),
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = subtitle == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : AppTheme.getCardBackgroundColor(),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppTheme.getBorderColor(),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? AppColors.secondary : AppTheme.getSecondaryTextColor(),
                size: isCompact ? 24 : 28,
              ),
              SizedBox(width: isCompact ? 8 : 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.secondary : AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.secondary : AppTheme.getBorderColor(),
              size: isCompact ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }
}
