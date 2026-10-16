import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/models/dynamic_theme_model.dart';
import 'theme_studio_section_label.dart';
import 'theme_studio_surfaces_palette.dart';

/// Editable habit accent swatches with a "Reset to Preset" action.
class ThemeStudioAccentPalette extends StatelessWidget {
  final UserThemeModel theme;
  final ThemeData previewTheme;
  final ThemeStudioColorPicker onPickColor;
  final void Function(int index, Color color) onAccentChanged;
  final VoidCallback onResetPalette;

  const ThemeStudioAccentPalette({
    super.key,
    required this.theme,
    required this.previewTheme,
    required this.onPickColor,
    required this.onAccentChanged,
    required this.onResetPalette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: ThemeStudioSectionLabel(
                text: 'HABIT ACCENT PALETTE',
                theme: theme,
                previewTheme: previewTheme,
              ),
            ),
            // AppButton fires its own light-impact haptic on tap.
            AppButton(
              text: 'Reset to Preset',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              customColor: theme.accentPalette.isNotEmpty
                  ? theme.accentPalette.first
                  : AppColors.neonLavender,
              onPressed: onResetPalette,
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: List.generate(theme.accentPalette.length, (index) {
            final color = theme.accentPalette[index];
            return InkWell(
              onTap: () => onPickColor(
                title: 'Accent Color #${index + 1}',
                currentColor: color,
                onSelected: (newColor) => onAccentChanged(index, newColor),
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: theme.textPrimary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.colorize,
                  color: AppColors.white.withValues(alpha: 0.8),
                  size: AppIconSizes.sm,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
