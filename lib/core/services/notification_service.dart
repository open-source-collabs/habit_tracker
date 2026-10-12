import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/habits/data/models/habit_model.dart';

/// Offline alarm & notification service powered by [FlutterLocalNotificationsPlugin].
/// Schedules localized daily or recurring habit alarms with zero external server dependencies.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initializes the local notification plugin and timezone database.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open Habit Tracker',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init notice (safe fallback): $e');
    }
  }

  /// Requests notification permission on platforms where runtime consent is required.
  Future<bool> requestPermission() async {
    try {
      if (!_isInitialized) await init();

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

      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
      return false;
    }
  }

  /// Schedules recurring offline alarms for the specified [habitId] and [time].
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required TimeOfDay time,
    required HabitFrequency frequency,
  }) async {
    try {
      if (!_isInitialized) await init();

      final id = (habitId.hashCode & 0x7FFFFFFF) % 100000;

      const androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Offline scheduled notifications for daily habits',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: id,
        title: 'Time for $habitTitle',
        body: 'Keep your streak glowing! Tap to check off today\'s progress.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: habitId,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleHabitReminder notice: $e');
    }
  }

  /// Cancels an existing scheduled reminder for [habitId].
  Future<void> cancelHabitReminder(String habitId) async {
    try {
      if (!_isInitialized) await init();
      final id = (habitId.hashCode & 0x7FFFFFFF) % 100000;
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('NotificationService cancelHabitReminder error: $e');
    }
  }

  /// Checks if notification permissions are currently enabled on the device.
  Future<bool> checkPermissionStatus() async {
    try {
      if (!_isInitialized) await init();

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

  /// Displays an immediate notification (useful for testing and instant milestone alerts).
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int id = 999999,
  }) async {
    try {
      if (!_isInitialized) await init();

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

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
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
      if (!_isInitialized) await init();

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

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
      if (!_isInitialized) await init();
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('NotificationService cancelDigest error: $e');
    }
  }

  /// Cancels all scheduled habit reminders.
  Future<void> cancelAll() async {
    try {
      if (!_isInitialized) await init();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService cancelAll error: $e');
    }
  }
}
