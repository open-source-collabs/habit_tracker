import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_error_log.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../data/review_gateway.dart';
import '../../data/review_prompt_preferences.dart';

/// Decides when asking for a store review is polite, and performs it.
///
/// Google decides whether the native sheet appears and never reports whether
/// the user rated, so the app asks rarely and only after a good moment.
class ReviewPromptService {
  /// Days since first use before the user is ever asked.
  static const int minDaysSinceFirstUse = 7;

  /// Distinct days with at least one check-in before the user is ever asked.
  static const int minActiveDays = 3;

  /// A streak this long (or finishing everything today) is a good moment.
  static const int milestoneStreak = 7;

  static const Duration minGapBetweenAsks = Duration(days: 60);
  static const int maxAsks = 3;

  final ReviewGateway gateway;
  final ReviewPromptPreferences prefs;
  final DateTime Function() _now;

  ReviewPromptService({
    required this.gateway,
    required this.prefs,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Remembers the first launch; called once at startup.
  Future<void> registerFirstUse() async {
    final record = await prefs.read();
    if (record.firstUse == null) await prefs.saveFirstUse(_now());
  }

  /// Whether to ask now, given the habits right after a check-in.
  Future<bool> shouldAsk(List<HabitModel> habits) async {
    final record = await prefs.read();
    if (record.finished || record.timesAsked >= maxAsks) return false;

    final now = _now();
    final firstUse = record.firstUse;
    if (firstUse == null ||
        now.toUtc().difference(firstUse) <
            const Duration(days: minDaysSinceFirstUse)) {
      return false;
    }
    final lastAsked = record.lastAsked;
    if (lastAsked != null &&
        now.toUtc().difference(lastAsked) < minGapBetweenAsks) {
      return false;
    }
    return _activeDays(habits) >= minActiveDays && _isGoodMoment(habits, now);
  }

  static int _activeDays(List<HabitModel> habits) => {
        for (final habit in habits)
          for (final entry in habit.checkIns.entries)
            if (entry.value) entry.key,
      }.length;

  /// Something was just completed today and the user is on a roll: a long
  /// streak, or every active habit done.
  static bool _isGoodMoment(List<HabitModel> habits, DateTime now) {
    final active = habits.where((h) => !h.isArchived).toList();
    if (active.isEmpty || !active.any((h) => h.isCompletedOn(now))) {
      return false;
    }
    final allDone = active.every((h) => h.isCompletedOn(now));
    final onStreak = active.any((h) => h.currentStreak >= milestoneStreak);
    return allDone || onStreak;
  }

  Future<void> recordAsked() async {
    final record = await prefs.read();
    await prefs.saveAsked(_now(), record.timesAsked + 1);
  }

  /// The user rated or opted out: never ask again.
  Future<void> markFinished() => prefs.saveFinished();

  /// Shows Google's native review sheet, or the store page when the sheet is
  /// unavailable (debug builds, sideloaded installs, quota reached).
  Future<void> requestReview() async {
    try {
      if (await gateway.isAvailable()) {
        await gateway.requestReview();
      } else {
        await gateway.openStoreListing();
      }
    } catch (error, stack) {
      AppErrorLog.record(error, stack, context: 'review request');
    }
  }
}

final reviewGatewayProvider = Provider<ReviewGateway>(
  (ref) => const InAppReviewGateway(),
);

final reviewPromptServiceProvider = Provider<ReviewPromptService>(
  (ref) => ReviewPromptService(
    gateway: ref.watch(reviewGatewayProvider),
    prefs: const ReviewPromptPreferences(),
  ),
);
