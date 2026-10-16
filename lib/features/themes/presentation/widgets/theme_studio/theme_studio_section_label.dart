import 'package:flutter/material.dart';

import '../../../../../core/theme/app_font_sizes.dart';
import '../../../data/models/dynamic_theme_model.dart';

/// Uppercase, tracked section caption rendered in the working theme's font and
/// text color so it previews exactly how the draft theme will look.
class ThemeStudioSectionLabel extends StatelessWidget {
  final String text;
  final UserThemeModel theme;
  final ThemeData previewTheme;
  final double letterSpacing;

  const ThemeStudioSectionLabel({
    super.key,
    required this.text,
    required this.theme,
    required this.previewTheme,
    this.letterSpacing = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: previewTheme.textTheme.labelSmall?.copyWith(
        fontFamily: theme.fontFamily,
        fontSize: AppFontSizes.labelSmall,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacing,
        color: theme.textPrimary.withValues(alpha: 0.5),
      ),
    );
  }
}
