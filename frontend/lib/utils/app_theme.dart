import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppThemeMode { light, dark }

class AppTheme {
  static AppThemeMode currentMode = AppThemeMode.dark;

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
        ? AppColors.slateGray
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
