import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../data/models/notification_settings_model.dart';
import '../../data/storage/notification_storage.dart';

/// Digest IDs for recurring system alarms.
abstract final class DigestNotificationIds {
  static const int morningKickoff = 888001;
  static const int eveningStreakSaver = 888002;
  static const int testNotification = 999999;
}

/// Provider querying the platform's active notification permission status.
final notificationPermissionStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await NotificationService.instance.checkPermissionStatus();
});

/// Computes all user habits that currently have a scheduled reminder time.
final scheduledHabitRemindersProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(habitListProvider).valueOrNull ?? [];
  return habits.where((h) => h.reminderTime != null && h.reminderTime!.isNotEmpty).toList();
});

/// Computes the total number of active recurring reminders for badge counters.
final activeRemindersCountProvider = Provider<int>((ref) {
  final settings = ref.watch(notificationSettingsProvider).value;
  if (settings == null || !settings.masterEnabled) return 0;

  final habitReminders = ref.watch(scheduledHabitRemindersProvider).length;
  final morning = settings.morningKickoffEnabled ? 1 : 0;
  final evening = settings.eveningStreakSaverEnabled ? 1 : 0;

  return habitReminders + morning + evening;
});

/// State notifier managing global notification preferences and digest scheduling.
class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettingsModel> {
  @override
  Future<NotificationSettingsModel> build() async {
    final storage = ref.watch(notificationStorageProvider);
    final settings = await storage.loadSettings();

    // Schedule digests if master and individual flags are enabled
    if (settings.masterEnabled) {
      if (settings.morningKickoffEnabled) {
        _scheduleMorningKickoff(settings.morningTime);
      }
      if (settings.eveningStreakSaverEnabled) {
        _scheduleEveningStreakSaver(settings.eveningTime);
      }
    }

    return settings;
  }

  /// Toggles master notification switch. When false, cancels all digests & alarms.
  Future<void> toggleMaster(bool enabled) async {
    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(masterEnabled: enabled);
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);

    if (!enabled) {
      await NotificationService.instance.cancelAll();
    } else {
      // Re-schedule enabled digests and habit reminders
      if (updated.morningKickoffEnabled) {
        _scheduleMorningKickoff(updated.morningTime);
      }
      if (updated.eveningStreakSaverEnabled) {
        _scheduleEveningStreakSaver(updated.eveningTime);
      }
      _rescheduleAllHabits();
    }
  }

  /// Toggles and optionally sets time for the morning motivation digest.
  Future<void> updateMorningKickoff({bool? enabled, TimeOfDay? time}) async {
    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(
      morningKickoffEnabled: enabled ?? current.morningKickoffEnabled,
      morningHour: time?.hour ?? current.morningHour,
      morningMinute: time?.minute ?? current.morningMinute,
    );
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);

    if (updated.masterEnabled && updated.morningKickoffEnabled) {
      _scheduleMorningKickoff(updated.morningTime);
    } else {
      await NotificationService.instance.cancelDigest(DigestNotificationIds.morningKickoff);
    }
  }

  /// Toggles and optionally sets time for the evening streak-saver warning.
  Future<void> updateEveningStreakSaver({bool? enabled, TimeOfDay? time}) async {
    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(
      eveningStreakSaverEnabled: enabled ?? current.eveningStreakSaverEnabled,
      eveningHour: time?.hour ?? current.eveningHour,
      eveningMinute: time?.minute ?? current.eveningMinute,
    );
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);

    if (updated.masterEnabled && updated.eveningStreakSaverEnabled) {
      _scheduleEveningStreakSaver(updated.eveningTime);
    } else {
      await NotificationService.instance.cancelDigest(DigestNotificationIds.eveningStreakSaver);
    }
  }

  /// Toggles sound alerts.
  Future<void> toggleSound(bool enabled) async {
    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(soundEnabled: enabled);
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);
  }

  /// Toggles tactile haptics.
  Future<void> toggleHaptics(bool enabled) async {
    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(hapticsEnabled: enabled);
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);
  }

  /// Dispatches an immediate test notification to verify delivery on device.
  Future<void> sendTestNotification() async {
    await NotificationService.instance.showInstantNotification(
      id: DigestNotificationIds.testNotification,
      title: 'Habit Tracker Test Alert 🔔',
      body: 'Offline alarms are active and delivering perfectly on your device!',
      payload: 'test_notification',
    );

    // Record in history log
    final record = NotificationAlertRecord(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Habit Tracker Test Alert 🔔',
      body: 'Verified local offline notifications.',
      timestamp: DateTime.now(),
      type: 'test',
    );

    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(
      history: [record, ...current.history].take(30).toList(),
    );
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);
  }

  /// Clears the past notification activity log.
  Future<void> clearHistory() async {
    final current = state.value ?? const NotificationSettingsModel();
    final updated = current.copyWith(history: const []);
    state = AsyncData(updated);
    await ref.read(notificationStorageProvider).saveSettings(updated);
  }

  /// Prompts the user for notification permissions and refreshes provider.
  Future<bool> requestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    ref.invalidate(notificationPermissionStatusProvider);
    return granted;
  }

  // --- Internal Scheduling Helpers ---

  void _scheduleMorningKickoff(TimeOfDay time) {
    unawaited(
      NotificationService.instance.scheduleDailyDigest(
        id: DigestNotificationIds.morningKickoff,
        title: 'Morning Kickoff 🌅',
        body: 'Check your scheduled habits and seize today\'s momentum!',
        time: time,
        payload: 'digest_morning',
      ),
    );
  }

  void _scheduleEveningStreakSaver(TimeOfDay time) {
    unawaited(
      NotificationService.instance.scheduleDailyDigest(
        id: DigestNotificationIds.eveningStreakSaver,
        title: 'Streak Saver Alert 🔥',
        body: 'Don\'t break the chain! Review your uncompleted habits before tonight.',
        time: time,
        payload: 'digest_evening',
      ),
    );
  }

  void _rescheduleAllHabits() {
    final habits = ref.read(habitListProvider).valueOrNull ?? [];
    for (final habit in habits) {
      if (habit.reminderTime != null && habit.reminderTime!.isNotEmpty) {
        final parts = habit.reminderTime!.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]) ?? 8;
          final m = int.tryParse(parts[1]) ?? 0;
          NotificationService.instance.scheduleHabitReminder(
            habitId: habit.id,
            habitTitle: habit.title,
            time: TimeOfDay(hour: h, minute: m),
            frequency: habit.frequency,
          );
        }
      }
    }
  }
}

/// Provider exposing [NotificationSettingsModel] and actions.
final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettingsModel>(() {
  return NotificationSettingsNotifier();
});
