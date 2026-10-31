import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What this device remembers about asking for a review.
@immutable
class ReviewPromptRecord {
  final DateTime? firstUse;
  final DateTime? lastAsked;
  final int timesAsked;

  /// The user rated, or asked never to be asked again.
  final bool finished;

  const ReviewPromptRecord({
    this.firstUse,
    this.lastAsked,
    this.timesAsked = 0,
    this.finished = false,
  });
}

class ReviewPromptPreferences {
  static const String _firstUseKey = 'habit_tracker_review_first_use_v1';
  static const String _lastAskedKey = 'habit_tracker_review_last_asked_v1';
  static const String _timesAskedKey = 'habit_tracker_review_times_asked_v1';
  static const String _finishedKey = 'habit_tracker_review_finished_v1';

  const ReviewPromptPreferences();

  static DateTime? _date(int? millis) => millis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

  Future<ReviewPromptRecord> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ReviewPromptRecord(
        firstUse: _date(prefs.getInt(_firstUseKey)),
        lastAsked: _date(prefs.getInt(_lastAskedKey)),
        timesAsked: prefs.getInt(_timesAskedKey) ?? 0,
        finished: prefs.getBool(_finishedKey) ?? false,
      );
    } catch (_) {
      // Unreadable storage: never nag.
      return const ReviewPromptRecord(finished: true);
    }
  }

  Future<void> saveFirstUse(DateTime time) => _write(
        (prefs) => prefs.setInt(_firstUseKey, time.millisecondsSinceEpoch),
      );

  Future<void> saveAsked(DateTime time, int timesAsked) => _write((prefs) async {
        await prefs.setInt(_lastAskedKey, time.millisecondsSinceEpoch);
        await prefs.setInt(_timesAskedKey, timesAsked);
      });

  Future<void> saveFinished() =>
      _write((prefs) => prefs.setBool(_finishedKey, true));

  Future<void> _write(Future<void> Function(SharedPreferences) body) async {
    try {
      await body(await SharedPreferences.getInstance());
    } catch (_) {
      // Worst case the user is asked a little differently next time.
    }
  }
}
