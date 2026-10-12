import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgets_kit/widgets_kit.dart';

import '../../features/habits/data/models/habit_model.dart';
import '../../features/themes/data/models/dynamic_theme_model.dart';

/// Provider for [HabitWidgetSyncService].
final habitWidgetSyncServiceProvider = Provider<HabitWidgetSyncService>((ref) {
  return HabitWidgetSyncService();
});

/// Service responsible for projecting habit tracking state to native Home Screen
/// AppWidgets (Android RemoteViews/Glance & iOS WidgetKit) using [WidgetsKit].
class HabitWidgetSyncService {
  static const String defaultAndroidProviderName = 'HabitWidgetProvider';
  static const String defaultQualifiedAndroidName =
      'com.example.habit_tracker.HabitWidgetProvider';
  static const String defaultIOSWidgetKind = 'HabitWidget';

  /// Key constants persisted in shared widget preferences.
  static const String keyTotalCount = 'habit_total_count';
  static const String keyCompletedCount = 'habit_completed_count';
  static const String keyCompletionRate = 'habit_completion_rate';
  static const String keyCompletionRatio = 'habit_completion_ratio';
  static const String keyActiveStreak = 'habit_active_streak';
  static const String keyTopPendingTitle = 'habit_top_pending_title';
  static const String keyTopPendingEmoji = 'habit_top_pending_emoji';
  static const String keyDateStr = 'habit_date_str';
  static const String keyAllCompleted = 'habit_all_completed';
  static const String keyActiveThemeId = 'habit_active_theme_id';

  /// Synchronizes current habit data to native home screen widgets.
  Future<bool> syncHabits({
    required List<HabitModel> habits,
    UserThemeModel? activeTheme,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final normalizedDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // Calculate metrics for the target date
    final scheduledHabits =
        habits.where((h) => h.frequency.isScheduledFor(normalizedDate)).toList();
    final totalCount = scheduledHabits.length;

    final completedHabits = scheduledHabits
        .where((h) => h.isCompletedOn(normalizedDate))
        .toList();
    final completedCount = completedHabits.length;

    final ratio = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final percentInt = (ratio * 100).round();
    final completionRateStr = '$percentInt%';
    final allCompleted = totalCount > 0 && completedCount == totalCount;

    // Highest active streak
    int highestStreak = 0;
    for (final habit in habits) {
      final s = habit.calculateCurrentStreak(asOf: normalizedDate);
      if (s > highestStreak) {
        highestStreak = s;
      }
    }

    // Identify next pending habit for today
    final pendingHabits = scheduledHabits
        .where((h) => !h.isCompletedOn(normalizedDate))
        .toList();
    final topPending = pendingHabits.isNotEmpty ? pendingHabits.first : null;
    final topPendingTitle = topPending?.title ??
        (totalCount == 0 ? 'No habits today' : 'All done today! 🎉');
    final topPendingEmoji = topPending?.emoji ?? (allCompleted ? '🏆' : '✨');

    final dateStr = _formatDate(normalizedDate);

    try {
      // 1. Write primitive key-values to native widget storage
      await WidgetsKit.saveWidgetData<int>(keyTotalCount, totalCount);
      await WidgetsKit.saveWidgetData<int>(keyCompletedCount, completedCount);
      await WidgetsKit.saveWidgetData<String>(keyCompletionRate, completionRateStr);
      await WidgetsKit.saveWidgetData<double>(keyCompletionRatio, ratio);
      await WidgetsKit.saveWidgetData<int>(keyActiveStreak, highestStreak);
      await WidgetsKit.saveWidgetData<String>(keyTopPendingTitle, topPendingTitle);
      await WidgetsKit.saveWidgetData<String>(keyTopPendingEmoji, topPendingEmoji);
      await WidgetsKit.saveWidgetData<String>(keyDateStr, dateStr);
      await WidgetsKit.saveWidgetData<bool>(keyAllCompleted, allCompleted);

      if (activeTheme != null) {
        await WidgetsKit.saveWidgetData<String>(
          keyActiveThemeId,
          activeTheme.id,
        );
      }

      // 2. Request native widget refresh
      await WidgetsKit.updateWidget(
        name: defaultAndroidProviderName,
        qualifiedAndroidName: defaultQualifiedAndroidName,
        iOSName: defaultIOSWidgetKind,
      );

      return true;
    } catch (e) {
      debugPrint('HabitWidgetSyncService: Error syncing to widgets_kit: $e');
      return false;
    }
  }

  /// Formats date for widget header (e.g., "Monday, Oct 12").
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final weekdayName = weekdays[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$weekdayName, $monthName ${date.day}';
  }
}
