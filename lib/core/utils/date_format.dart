/// Lightweight English date labels (no intl dependency until localization).
abstract final class AppDateFormat {
  static const List<String> weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// e.g. "just now", "5 min ago", "3 h ago", "yesterday", "4 days ago".
  static String relative(DateTime time, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(time);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} h ago';
    if (elapsed.inDays == 1) return 'yesterday';
    return '${elapsed.inDays} days ago';
  }

  /// e.g. "Friday, 17 October".
  static String longDay(DateTime date) =>
      '${weekdayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]}';
}
