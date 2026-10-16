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

  /// e.g. "Friday, 17 October".
  static String longDay(DateTime date) =>
      '${weekdayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]}';
}
