import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_kit/widgets_kit.dart';

import '../../../core/widgets_kit/habit_widget_sync_service.dart';

final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => const HomeWidgetService(),
);

/// Adding and detecting the "Today's progress" home-screen widget.
///
/// Android only for now: iOS has no widget extension yet, and iOS doesn't let
/// apps place widgets anyway. Every call is safe on other platforms (and in
/// tests, where the plugin is absent).
class HomeWidgetService {
  const HomeWidgetService();

  static const String _tipDismissedKey = 'home_widget_tip_dismissed_v1';

  /// Whether this platform has the widget at all.
  bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the launcher can show the system "Add to home screen" dialog
  /// (Android 8+, most launchers).
  Future<bool> canRequestPin() async {
    if (!isAvailable) return false;
    try {
      return await WidgetsKit.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the launcher's "Add widget" dialog. Returns `false` if it couldn't
  /// be shown, so the caller can explain how to add it manually.
  Future<bool> requestPin() async {
    if (!await canRequestPin()) return false;
    try {
      await WidgetsKit.requestPinWidget(
        qualifiedAndroidName: HabitWidgetSyncService.defaultQualifiedAndroidName,
        androidName: HabitWidgetSyncService.defaultAndroidProviderName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// How many copies of the widget are on the home screen.
  Future<int> installedCount() async {
    if (!isAvailable) return 0;
    try {
      final widgets = await WidgetsKit.getInstalledWidgets();
      return widgets
          .where(
            (w) => (w.androidClassName ?? '').endsWith(
              HabitWidgetSyncService.defaultAndroidProviderName,
            ),
          )
          .length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> isTipDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tipDismissedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> dismissTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tipDismissedKey, true);
    } catch (_) {}
  }
}
