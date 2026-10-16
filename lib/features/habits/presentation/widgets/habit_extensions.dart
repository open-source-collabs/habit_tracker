import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/habit_model.dart';

/// Presentation extension for resolving dynamic theme or custom habit colors.
extension HabitPresentationX on HabitModel {
  Color resolveColor(BuildContext context) {
    if (customColorValue != null) {
      return Color(customColorValue!);
    }
    final palette = context.accentPalette;
    if (palette.isNotEmpty) {
      return palette[accentIndex % palette.length];
    }
    return context.primaryAccent;
  }
}

/// Short, human-readable schedule text, e.g. "Daily", "Weekdays",
/// "Mon, Wed, Fri" or "3x / wk".
extension HabitFrequencyLabelX on HabitFrequency {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdays = {1, 2, 3, 4, 5};

  String get label {
    switch (type) {
      case HabitFrequencyType.daily:
        return 'Daily';
      case HabitFrequencyType.specificWeekdays:
        final days = daysOfWeek.toSet();
        if (days.length == 7) return 'Daily';
        if (days.length == 5 && days.containsAll(_weekdays)) return 'Weekdays';
        return daysOfWeek.map((d) => _dayNames[(d - 1).clamp(0, 6)]).join(', ');
      case HabitFrequencyType.timesPerWeek:
        return '${targetTimesPerWeek}x / wk';
    }
  }
}

/// Curated mapping of icon identifiers to Material icons.
class HabitIconRegistry {
  HabitIconRegistry._();

  static const Map<String, IconData> icons = {
    'fitness_center': Icons.fitness_center_rounded,
    'water_drop': Icons.water_drop_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'menu_book': Icons.menu_book_rounded,
    'bedtime': Icons.bedtime_rounded,
    'bolt': Icons.bolt_rounded,
    'directions_run': Icons.directions_run_rounded,
    'alarm': Icons.alarm_rounded,
    'wb_sunny': Icons.wb_sunny_rounded,
    'spa': Icons.spa_rounded,
    'favorite': Icons.favorite_rounded,
    'psychology': Icons.psychology_rounded,
    'brush': Icons.brush_rounded,
    'code': Icons.code_rounded,
    'eco': Icons.eco_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'checklist': Icons.checklist_rounded,
    'headphones': Icons.headphones_rounded,
    'palette': Icons.palette_rounded,
    'timer': Icons.timer_rounded,
  };

  static IconData? getIcon(String? code) {
    if (code == null) return null;
    return icons[code];
  }
}
