import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/dynamic_theme_model.dart';
import 'theme_studio_section_label.dart';

/// Two-column grid of font cards; each previews itself in its own family.
class ThemeStudioFontSelector extends StatelessWidget {
  final UserThemeModel theme;
  final ThemeData previewTheme;
  final ValueChanged<String> onFontSelected;

  const ThemeStudioFontSelector({
    super.key,
    required this.theme,
    required this.previewTheme,
    required this.onFontSelected,
  });

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    const fonts = AppFonts.options;
    final selectedFamily = AppFonts.resolve(theme.fontFamily);
    final gap = 10.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemeStudioSectionLabel(
          text: 'OFFLINE FONT REGISTRY (${fonts.length} PROFESSIONAL FONTS)',
          theme: theme,
          previewTheme: previewTheme,
        ),
        SizedBox(height: 10.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth =
                (constraints.maxWidth - gap * (_columns - 1)) / _columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final font in fonts)
                  SizedBox(
                    width: cardWidth,
                    child: _FontCard(
                      font: font,
                      theme: theme,
                      isSelected: font.family == selectedFamily,
                      onTap: () => onFontSelected(font.family),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FontCard extends StatelessWidget {
  final FontOption font;
  final UserThemeModel theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontCard({
    required this.font,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentPalette.isNotEmpty
        ? theme.accentPalette.first
        : AppColors.neonLavender;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${font.displayName} font',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.pastelSurface(accent, isDark: theme.isDark)
                : theme.cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? accent : theme.cardBorder,
              width: isSelected
                  ? AppSizes.borderWidthSelected
                  : AppSizes.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Aa',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontFamily: font.family,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: AppIconSizes.sm,
                      color: accent,
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                font.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  fontFamily: font.family,
                  fontSize: AppFontSizes.caption,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                font.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  fontFamily: font.family,
                  fontSize: AppFontSizes.labelSmall,
                  fontWeight: FontWeight.w400,
                  color: theme.textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
