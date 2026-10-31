import 'package:shared_preferences/shared_preferences.dart';

/// Per-device bookkeeping that keeps automatic update prompts polite: at most
/// one check a day, and a version the user declined is not offered again.
class AppUpdatePreferences {
  static const String _lastCheckedKey = 'habit_tracker_update_last_checked_v1';
  static const String _dismissedKey = 'habit_tracker_update_dismissed_v1';

  const AppUpdatePreferences();

  Future<DateTime?> lastChecked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_lastCheckedKey);
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastChecked(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckedKey, time.millisecondsSinceEpoch);
    } catch (_) {
      // Worst case the next launch checks again.
    }
  }

  Future<int?> dismissedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_dismissedKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDismissedVersion(int? versionCode) async {
    if (versionCode == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dismissedKey, versionCode);
    } catch (_) {
      // Worst case the user is asked once more.
    }
  }
}
