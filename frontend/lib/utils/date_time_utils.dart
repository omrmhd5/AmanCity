/// Date and time formatting utilities
class DateTimeUtils {
  /// Format DateTime to 12-hour format with date (adds 3 hours)
  /// Returns format: "YYYY-MM-DD HH:MM:SS AM/PM"
  static String formatTime12Hour(DateTime dt) {
    // Add 3 hours
    final adjustedDt = dt.add(const Duration(hours: 3));

    final hour = adjustedDt.hour % 12 == 0 ? 12 : adjustedDt.hour % 12;
    final period = adjustedDt.hour >= 12 ? 'PM' : 'AM';
    final minute = adjustedDt.minute.toString().padLeft(2, '0');
    final second = adjustedDt.second.toString().padLeft(2, '0');
    final month = adjustedDt.month.toString().padLeft(2, '0');
    final day = adjustedDt.day.toString().padLeft(2, '0');
    return '${adjustedDt.year}-$month-$day $hour:$minute:$second $period';
  }
}
