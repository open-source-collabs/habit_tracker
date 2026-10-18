/// Calendar-day arithmetic that is safe across daylight-saving changes.
///
/// `date.subtract(Duration(days: 1))` moves back 24 *hours*, which on the day
/// after clocks spring forward lands on 23:00 two days earlier and silently
/// skips a day (breaking streaks). These helpers move by calendar days
/// instead and always return local midnight.
abstract final class CalendarDays {
  /// Local midnight of [date].
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Local midnight [days] calendar days after [date] (negative = before).
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// Whole calendar days from [from] to [to], ignoring time of day and DST.
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  /// Monday of [date]'s week, at local midnight.
  static DateTime mondayOf(DateTime date) =>
      addDays(date, -(date.weekday - DateTime.monday));

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
