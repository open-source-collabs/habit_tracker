import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/habits/data/models/habit_model.dart';
import 'reminder_schedule.dart';

/// Offline alarm & notification service powered by [FlutterLocalNotificationsPlugin].
/// Schedules habit reminders and daily digests on-device; no server involved.
///
/// Reminder *planning* (which ids, which days) lives in [ReminderSchedule];
/// this class only talks to the platform.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Ids below this were produced by builds that derived ids from
  /// `String.hashCode`, which isn't stable across runs; they are cleaned up
  /// on the next full reschedule.
  static const int _legacyIdCeiling = 100000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();
  Future<void>? _initFuture;
  bool _isInitialized = false;
  bool _launchPayloadTaken = false;

  /// Global switch from notification settings. When false, habit reminders
  /// are cancelled instead of scheduled.
  bool remindersEnabled = true;

  /// Payloads of notifications the user taps while the app is running.
  Stream<String> get notificationTaps => _taps.stream;

  /// Initializes the plugin and sets the local time zone so reminders fire at
  /// the user's wall-clock time. Safe to call repeatedly.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      tz.initializeTimeZones();
      await _configureLocalTimeZone();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open Track Free',
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'Track Free',
        appUserModelId: 'co.trackfree.solforge',
        guid: '6b0f7c1e-4a8e-4d55-9a3b-2f1e9c7d5a10',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) _taps.add(payload);
        },
      );

      _isInitialized = true;
    } catch (e) {
      // Unsupported platform or test environment: every call stays a no-op.
      _initFuture = null;
      debugPrint('NotificationService init notice (safe fallback): $e');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      // Leaves tz.local as UTC; reminders would fire at the UTC wall time.
      debugPrint('NotificationService: could not resolve local time zone: $e');
    }
  }

  /// Payload of the notification that launched the app, if any. Returned
  /// once per process so it isn't handled twice.
  Future<String?> takeLaunchPayload() async {
    if (_launchPayloadTaken) return null;
    _launchPayloadTaken = true;
    try {
      await init();
      if (!_isInitialized) return null;
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      return details?.notificationResponse?.payload;
    } catch (_) {
      return null;
    }
  }

  /// Requests notification permission on platforms where runtime consent is
  /// required (Android 13+, iOS, macOS).
  Future<bool> requestPermission() async {
    try {
      await init();

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final macImpl = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macImpl != null) {
        final granted = await macImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
      return false;
    }
  }

  /// Checks if notification permissions are currently enabled on the device.
  Future<bool> checkPermissionStatus() async {
    try {
      await init();

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final enabled = await androidImpl.areNotificationsEnabled();
        return enabled ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('NotificationService checkPermissionStatus error: $e');
      return true;
    }
  }

  /// Brings [habit]'s scheduled reminders in line with its current state:
  /// scheduled per [ReminderSchedule.slotsFor] when reminders are enabled,
  /// cancelled otherwise.
  Future<void> syncHabitReminder(HabitModel habit) async {
    await cancelHabitReminder(habit.id);
    if (!remindersEnabled) return;
    final slots = ReminderSchedule.slotsFor(habit);
    if (slots.isEmpty) return;

    final mode = await _androidScheduleMode();
    for (final slot in slots) {
      await _scheduleSlot(slot, habit, mode);
    }
  }

  /// Reconciles every pending habit reminder with [habits]: schedules what
  /// should exist and cancels anything stale (deleted habits, legacy ids).
  /// Digest and test notifications are left untouched.
  Future<void> rescheduleAll(List<HabitModel> habits) async {
    try {
      await init();
      if (!_isInitialized) return;

      final wanted = <int>{
        if (remindersEnabled)
          for (final habit in habits)
            ...ReminderSchedule.slotsFor(habit).map((s) => s.id),
      };
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        final isHabitReminder = request.id >= ReminderSchedule.reservedIdCeiling;
        final isLegacy = request.id < _legacyIdCeiling;
        if ((isHabitReminder && !wanted.contains(request.id)) || isLegacy) {
          await _plugin.cancel(id: request.id);
        }
      }

      for (final habit in habits) {
        await syncHabitReminder(habit);
      }
    } catch (e) {
      debugPrint('NotificationService rescheduleAll notice: $e');
    }
  }

  /// Cancels every reminder slot belonging to [habitId].
  Future<void> cancelHabitReminder(String habitId) async {
    try {
      await init();
      if (!_isInitialized) return;
      for (final id in ReminderSchedule.allIds(habitId)) {
        await _plugin.cancel(id: id);
      }
    } catch (e) {
      debugPrint('NotificationService cancelHabitReminder error: $e');
    }
  }

  Future<void> _scheduleSlot(
    ReminderSlot slot,
    HabitModel habit,
    AndroidScheduleMode mode,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Reminders for the habits you set a time on',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.zonedSchedule(
        id: slot.id,
        title: 'Time for ${habit.title}',
        body: 'Tap to check it off and keep your streak going.',
        scheduledDate: _nextInstance(
          hour: slot.hour,
          minute: slot.minute,
          weekday: slot.weekday,
        ),
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: slot.weekday == null
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
        payload: habit.id,
      );
    } catch (e) {
      debugPrint('NotificationService schedule notice: $e');
    }
  }

  /// Exact alarms when the user has allowed them (Android 12+ requires the
  /// "Alarms & reminders" permission); otherwise inexact, which Android may
  /// delay by a few minutes but always delivers.
  Future<AndroidScheduleMode> _androidScheduleMode() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return AndroidScheduleMode.exactAllowWhileIdle;
      final canExact = await androidImpl.canScheduleExactNotifications();
      return canExact == true
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  tz.TZDateTime _nextInstance({
    required int hour,
    required int minute,
    int? weekday,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final next = ReminderSchedule.nextOccurrence(
      DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second),
      hour: hour,
      minute: minute,
      weekday: weekday,
    );
    return tz.TZDateTime(tz.local, next.year, next.month, next.day, hour, minute);
  }

  /// Displays an immediate notification (useful for testing delivery).
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int id = 999999,
  }) async {
    try {
      await init();
      if (!_isInitialized) return;

      const androidDetails = AndroidNotificationDetails(
        'habit_instant',
        'Instant Alerts',
        channelDescription: 'Immediate feedback and test notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService showInstantNotification notice: $e');
    }
  }

  /// Schedules a recurring daily digest notification at [time].
  Future<void> scheduleDailyDigest({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      await init();
      if (!_isInitialized) return;

      const androidDetails = AndroidNotificationDetails(
        'habit_digests',
        'Daily Digests',
        channelDescription: 'Morning kickoffs and evening streak-saver digests',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstance(hour: time.hour, minute: time.minute),
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: await _androidScheduleMode(),
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleDailyDigest notice: $e');
    }
  }

  /// Cancels an existing digest notification by [id].
  Future<void> cancelDigest(int id) async {
    try {
      await init();
      if (!_isInitialized) return;
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('NotificationService cancelDigest error: $e');
    }
  }

  /// Cancels every scheduled notification (reminders and digests).
  Future<void> cancelAll() async {
    try {
      await init();
      if (!_isInitialized) return;
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService cancelAll error: $e');
    }
  }
}

/// Injectable access to [NotificationService], so callers can be tested with
/// a fake instead of the platform plugin.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);
