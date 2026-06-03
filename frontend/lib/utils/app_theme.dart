import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_colors.dart';

enum AppThemeMode { light, dark }

class AppTheme {
  static AppThemeMode currentMode = AppThemeMode.light;

  /// Reactive notifier — listen to this to rebuild on theme change.
  static final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(
    AppThemeMode.light,
  );

  /// Load persisted theme from SharedPreferences (call once before runApp).
  static Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('app_theme_mode');
    final mode = stored == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
    currentMode = mode;
    themeNotifier.value = mode;
  }

  /// Persist + apply a new theme mode.
  static Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_theme_mode',
      mode == AppThemeMode.dark ? 'dark' : 'light',
    );
    currentMode = mode;
    themeNotifier.value = mode;
  }

  /// Toggle between light and dark mode
  static void toggleTheme() {
    currentMode = currentMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
  }

  /// Get background color based on current theme
  static Color getBackgroundColor() {
    return currentMode == AppThemeMode.dark
        ? AppColors.primary
        : AppColors.lightBackground;
  }

  /// Get gradient start color based on current theme
  static Color getGradientStartColor() {
    return currentMode == AppThemeMode.dark
        ? Colors.white.withOpacity(0.05)
        : AppColors.primary.withOpacity(0.1);
  }

  /// Get primary text color based on current theme
  static Color getPrimaryTextColor() {
    return currentMode == AppThemeMode.dark ? Colors.white : AppColors.darkText;
  }

  /// Get secondary text color based on current theme
  static Color getSecondaryTextColor() {
    return currentMode == AppThemeMode.dark
        ? Colors.white.withOpacity(0.7)
        : AppColors.slateGray;
  }

  /// Get card background color based on current theme
  static Color getCardBackgroundColor() {
    return currentMode == AppThemeMode.dark
        ? AppColors.primary.withOpacity(0.5)
        : Colors.white;
  }

  /// Get border color based on current theme
  static Color getBorderColor() {
    return currentMode == AppThemeMode.dark
        ? Colors.white.withOpacity(0.1)
        : AppColors.softGray;
  }
}
