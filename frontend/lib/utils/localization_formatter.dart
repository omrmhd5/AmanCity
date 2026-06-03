import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shared utility for localizing distance, duration, and time ago strings.
/// Keeps numbers as ASCII digits.
class LocalizationFormatter {
  /// Localizes a distance string like "1.2 km", "1.2km", or "500 m"
  static String formatDistance(BuildContext context, String distance) {
    final isArabic = context.locale.languageCode == 'ar';
    if (!isArabic) return distance;

    // Handle "km" (with or without space before it)
    String display = distance
        .replaceAll(' km', ' كم')
        .replaceAll('km', ' كم');

    // Handle "m" suffix (metres) — only if not already replaced
    if (display.endsWith(' m')) {
      display = '${display.substring(0, display.length - 2)} م';
    } else if (display.endsWith('m') && !display.contains('كم')) {
      display = '${display.substring(0, display.length - 1)} م';
    }

    return display;
  }

  /// Localizes a duration string like "25 mins", "1 hour", "1 hour 25 mins"
  static String formatDuration(BuildContext context, String duration) {
    final isArabic = context.locale.languageCode == 'ar';
    if (!isArabic) return duration;

    return duration
        .replaceAll('hours', 'ساعة')
        .replaceAll('hour', 'ساعة')
        .replaceAll('mins', 'دقيقة')
        .replaceAll('min', 'دقيقة');
  }

  /// Formats age of DateTime to localized "time ago" string
  static String formatTimeAgo(BuildContext context, DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'incidents.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return 'incidents.minutes_ago'.tr(namedArgs: {'n': '${difference.inMinutes}'});
    } else if (difference.inHours < 24) {
      return 'incidents.hours_ago'.tr(namedArgs: {'n': '${difference.inHours}'});
    } else {
      return 'incidents.days_ago'.tr(namedArgs: {'n': '${difference.inDays}'});
    }
  }
}
