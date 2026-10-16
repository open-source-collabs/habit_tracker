import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/dynamic_theme_model.dart';

/// Horizontally scrolling theme selector chips plus a "New Custom" action.
class ThemeStudioChipsBar extends StatelessWidget {
  final List<UserThemeModel> themes;
  final UserThemeModel workingTheme;
  final ValueChanged<UserThemeModel> onSelectTheme;
  final VoidCallback onCreateNew;

  const ThemeStudioChipsBar({
    super.key,
    required this.themes,
    required this.workingTheme,
    required this.onSelectTheme,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...themes.map((theme) {
            final isSelected = workingTheme.id == theme.id;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ChoiceChip(
                label: Text(theme.name),
                selected: isSelected,
                onSelected: (_) => onSelectTheme(theme),
                selectedColor: workingTheme.cardBg,
                backgroundColor: workingTheme.scaffoldBg,
                labelStyle: context.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? workingTheme.textPrimary
                      : workingTheme.textPrimary.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: AppFontSizes.caption,
                ),
                side: BorderSide(
                  color: isSelected
                      ? (workingTheme.accentPalette.isNotEmpty
                            ? workingTheme.accentPalette.first
                            : workingTheme.cardBorder)
                      : workingTheme.cardBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            );
          }),
          ActionChip(
            avatar: Icon(
              Icons.add,
              size: AppIconSizes.sm,
              color: workingTheme.textPrimary,
            ),
            label: const Text('New Custom'),
            onPressed: onCreateNew,
            backgroundColor: workingTheme.cardBg,
            labelStyle: context.textTheme.labelMedium?.copyWith(
              color: workingTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSizes.caption,
            ),
            side: BorderSide(
              color: workingTheme.cardBorder,
              width: AppSizes.borderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }
}
