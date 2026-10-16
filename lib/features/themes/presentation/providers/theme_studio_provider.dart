import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/dynamic_theme_model.dart';
import 'theme_provider.dart';

/// Auto-disposing notifier managing the active theme draft inside Theme Studio.
class ThemeStudioWorkingThemeNotifier
    extends AutoDisposeNotifier<UserThemeModel> {
  /// Seeds the draft from the active theme once. Read (not watched) so that
  /// switching or saving themes doesn't discard edits in progress; the sheet
  /// updates the draft explicitly via [setWorkingTheme].
  @override
  UserThemeModel build() {
    return ref.read(themeProvider).activeTheme;
  }

  void setWorkingTheme(UserThemeModel theme) {
    state = theme;
  }

  void updateFont(String font) {
    state = state.copyWith(fontFamily: font);
  }

  void updateScaffoldBg(Color color) {
    state = state.copyWith(scaffoldBgHex: AppColors.colorToHex(color));
  }

  void updateCardBg(Color color) {
    state = state.copyWith(cardBgHex: AppColors.colorToHex(color));
  }

  void updateCardBorder(Color color) {
    state = state.copyWith(cardBorderHex: AppColors.colorToHex(color));
  }

  void updateTextPrimary(Color color) {
    state = state.copyWith(textPrimaryHex: AppColors.colorToHex(color));
  }

  void updatePaletteColor(int index, Color color) {
    final hexList = List<String>.from(state.accentPaletteHex);
    if (index >= 0 && index < hexList.length) {
      hexList[index] = AppColors.colorToHex(color);
      state = state.copyWith(accentPaletteHex: hexList);
    }
  }

  void resetPalette() {
    state = state.copyWith(
      accentPaletteHex:
          AppColors.habitPalette.map(AppColors.colorToHex).toList(),
    );
  }

  void updateTheme(UserThemeModel Function(UserThemeModel current) updater) {
    state = updater(state);
  }
}

/// Provider exposing the reactive working theme in Theme Studio.
final themeStudioWorkingThemeNotifierProvider = AutoDisposeNotifierProvider<
    ThemeStudioWorkingThemeNotifier, UserThemeModel>(
  ThemeStudioWorkingThemeNotifier.new,
);
