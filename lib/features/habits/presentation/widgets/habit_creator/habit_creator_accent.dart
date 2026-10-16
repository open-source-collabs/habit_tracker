import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../providers/habit_creator_form_provider.dart';

/// Resolves the accent color currently picked in the Habit Creator form:
/// the custom Hex/HSL color if set, otherwise the selected theme palette swatch.
Color resolveHabitCreatorAccent(
  BuildContext context,
  HabitCreatorFormState formState,
) {
  if (formState.customColor != null) return formState.customColor!;
  final palette = context.accentPalette;
  if (palette.isNotEmpty && formState.selectedAccentIndex >= 0) {
    return palette[formState.selectedAccentIndex % palette.length];
  }
  return context.primaryAccent;
}

/// Readable foreground (check marks, labels) drawn on top of a solid [color].
Color habitCreatorOnColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? AppColors.white
      : AppColors.obsidianTwilight;
}
