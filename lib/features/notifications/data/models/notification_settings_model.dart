import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Represents a past or recent notification alert in the activity history log.
@immutable
class NotificationAlertRecord {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'habit', 'digest', 'streak', 'test'

  const NotificationAlertRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = 'habit',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  factory NotificationAlertRecord.fromJson(Map<String, dynamic> json) {
    return NotificationAlertRecord(
      id: json['id'] as String? ?? 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Reminder',
      body: json['body'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      type: json['type'] as String? ?? 'habit',
    );
  }
}

/// Immutable configuration model managing global notification & reminder preferences.
@immutable
class NotificationSettingsModel {
  final bool masterEnabled;
  final bool morningKickoffEnabled;
  final int morningHour;
  final int morningMinute;
  final bool eveningStreakSaverEnabled;
  final int eveningHour;
  final int eveningMinute;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final List<NotificationAlertRecord> history;

  const NotificationSettingsModel({
    this.masterEnabled = true,
    this.morningKickoffEnabled = true,
    this.morningHour = 8,
    this.morningMinute = 0,
    this.eveningStreakSaverEnabled = true,
    this.eveningHour = 20,
    this.eveningMinute = 30,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.history = const [],
  });

  TimeOfDay get morningTime => TimeOfDay(hour: morningHour, minute: morningMinute);
  TimeOfDay get eveningTime => TimeOfDay(hour: eveningHour, minute: eveningMinute);

  NotificationSettingsModel copyWith({
    bool? masterEnabled,
    bool? morningKickoffEnabled,
    int? morningHour,
    int? morningMinute,
    bool? eveningStreakSaverEnabled,
    int? eveningHour,
    int? eveningMinute,
    bool? soundEnabled,
    bool? hapticsEnabled,
    List<NotificationAlertRecord>? history,
  }) {
    return NotificationSettingsModel(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      morningKickoffEnabled:
          morningKickoffEnabled ?? this.morningKickoffEnabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningStreakSaverEnabled:
          eveningStreakSaverEnabled ?? this.eveningStreakSaverEnabled,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'masterEnabled': masterEnabled,
        'morningKickoffEnabled': morningKickoffEnabled,
        'morningHour': morningHour,
        'morningMinute': morningMinute,
        'eveningStreakSaverEnabled': eveningStreakSaverEnabled,
        'eveningHour': eveningHour,
        'eveningMinute': eveningMinute,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as List<dynamic>?;
    final parsedHistory = rawHistory != null
        ? rawHistory
            .map((e) => NotificationAlertRecord.fromJson(e as Map<String, dynamic>))
            .toList()
        : const <NotificationAlertRecord>[];

    return NotificationSettingsModel(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      morningKickoffEnabled: json['morningKickoffEnabled'] as bool? ?? true,
      morningHour: (json['morningHour'] as num?)?.toInt() ?? 8,
      morningMinute: (json['morningMinute'] as num?)?.toInt() ?? 0,
      eveningStreakSaverEnabled:
          json['eveningStreakSaverEnabled'] as bool? ?? true,
      eveningHour: (json['eveningHour'] as num?)?.toInt() ?? 20,
      eveningMinute: (json['eveningMinute'] as num?)?.toInt() ?? 30,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      history: parsedHistory,
    );
  }
}
