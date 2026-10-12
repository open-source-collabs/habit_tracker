import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

/// Auto-disposing notifier for managing the selected HSL color inside ColorPickerDialog.
class ColorPickerNotifier extends AutoDisposeFamilyNotifier<HSLColor, Color> {
  @override
  HSLColor build(Color arg) {
    return HSLColor.fromColor(arg);
  }

  void updateHsl(HSLColor newHsl) {
    state = newHsl;
  }

  void updateFromHex(String hex) {
    final parsed = AppColors.hexToColor(hex, fallback: state.toColor());
    state = HSLColor.fromColor(parsed);
  }

  void updateColor(Color color) {
    state = HSLColor.fromColor(color);
  }
}

/// Provider exposing the reactive HSL color selection for a given initial color.
final colorPickerProvider =
    AutoDisposeNotifierProviderFamily<ColorPickerNotifier, HSLColor, Color>(
  ColorPickerNotifier.new,
);
