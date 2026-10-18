import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_contrast.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_fonts.dart';
import '../../../data/models/dynamic_theme_model.dart';
import 'theme_studio_section_label.dart';

/// Opens a color picker titled [title] seeded with [currentColor] and reports
/// the chosen color through [onSelected].
typedef ThemeStudioColorPicker = void Function({
  required String title,
  required Color currentColor,
  required ValueChanged<Color> onSelected,
});

/// Editable tiles for the scaffold, card, border and primary text colors.
class ThemeStudioSurfacesPalette extends StatelessWidget {
  final UserThemeModel theme;
  final ThemeData previewTheme;
  final ThemeStudioColorPicker onPickColor;
  final ValueChanged<Color> onScaffoldBgChanged;
  final ValueChanged<Color> onCardBgChanged;
  final ValueChanged<Color> onCardBorderChanged;
  final ValueChanged<Color> onTextPrimaryChanged;

  const ThemeStudioSurfacesPalette({
    super.key,
    required this.theme,
    required this.previewTheme,
    required this.onPickColor,
    required this.onScaffoldBgChanged,
    required this.onCardBgChanged,
    required this.onCardBorderChanged,
    required this.onTextPrimaryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        'Scaffold Background',
        theme.scaffoldBgHex,
        theme.scaffoldBg,
        onScaffoldBgChanged,
      ),
      ('Card Surface', theme.cardBgHex, theme.cardBg, onCardBgChanged),
      (
        'Card Border Tint',
        theme.cardBorderHex,
        theme.cardBorder,
        onCardBorderChanged,
      ),
      (
        'Text Primary',
        theme.textPrimaryHex,
        theme.textPrimary,
        onTextPrimaryChanged,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemeStudioSectionLabel(
          text: 'SURFACES & BORDER PALETTE',
          theme: theme,
          previewTheme: previewTheme,
        ),
        SizedBox(height: 10.h),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          _ColorTile(
            theme: theme,
            previewTheme: previewTheme,
            title: entries[i].$1,
            subtitle: entries[i].$2,
            color: entries[i].$3,
            onTap: () => onPickColor(
              title: entries[i].$1,
              currentColor: entries[i].$3,
              onSelected: entries[i].$4,
            ),
          ),
        ],
        _ContrastWarning(theme: theme, previewTheme: previewTheme),
      ],
    );
  }
}

/// Flags text colors that would be hard to read on the chosen surfaces.
class _ContrastWarning extends StatelessWidget {
  final UserThemeModel theme;
  final ThemeData previewTheme;

  const _ContrastWarning({required this.theme, required this.previewTheme});

  @override
  Widget build(BuildContext context) {
    final onCard = AppContrast.ratio(theme.textPrimary, theme.cardBg);
    final onScaffold = AppContrast.ratio(theme.textPrimary, theme.scaffoldBg);
    final worst = onCard < onScaffold ? onCard : onScaffold;
    if (worst >= AppContrast.minTextRatio) return const SizedBox.shrink();

    final error = previewTheme.colorScheme.error;
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: AppIconSizes.sm,
              color: error,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Text may be hard to read: contrast is '
                '${worst.toStringAsFixed(1)}:1 (aim for at least '
                '${AppContrast.minTextRatio}:1). Try a darker or lighter '
                'text colour.',
                style: previewTheme.textTheme.labelSmall?.copyWith(
                  fontFamily: theme.fontFamily,
                  fontSize: AppFontSizes.labelSmall,
                  color: error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  final UserThemeModel theme;
  final ThemeData previewTheme;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ColorTile({
    required this.theme,
    required this.previewTheme,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.cardBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.textPrimary.withValues(alpha: 0.2),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: previewTheme.textTheme.labelMedium?.copyWith(
                      fontFamily: theme.fontFamily,
                      fontSize: AppFontSizes.caption,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: previewTheme.textTheme.labelSmall?.copyWith(
                      fontFamily: AppFonts.inter,
                      fontSize: AppFontSizes.labelSmall,
                      fontWeight: FontWeight.w400,
                      color: theme.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              size: AppIconSizes.sm,
              color: theme.textPrimary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
