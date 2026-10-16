import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/dynamic_theme_model.dart';
import 'theme_studio_section_label.dart';

/// Bundled (offline) font families the Theme Studio can switch between.
abstract final class ThemeStudioFonts {
  static const String plusJakartaSans = 'PlusJakartaSans';
  static const String inter = 'Inter';

  static const List<String> registry = [plusJakartaSans, inter];

  static String displayName(String font) =>
      font == plusJakartaSans ? 'Plus Jakarta Sans' : 'Inter';

  static String tagline(String font) => font == plusJakartaSans
      ? 'Tactile Geometric Sans'
      : 'Modern Precision Sans';
}

/// Side-by-side font cards; each previews itself in its own family.
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

  @override
  Widget build(BuildContext context) {
    const fonts = ThemeStudioFonts.registry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemeStudioSectionLabel(
          text: 'OFFLINE FONT REGISTRY (2 PROFESSIONAL FONTS)',
          theme: theme,
          previewTheme: previewTheme,
        ),
        SizedBox(height: 10.h),
        Row(
          children: fonts.map((font) {
            final isSelected = theme.fontFamily == font;
            return Expanded(
              child: GestureDetector(
                onTap: () => onFontSelected(font),
                child: Container(
                  margin: EdgeInsets.only(
                    right: font == fonts.first ? 10.w : 0,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isSelected
                          ? (theme.accentPalette.isNotEmpty
                                ? theme.accentPalette.first
                                : theme.cardBorder)
                          : theme.cardBorder,
                      width: isSelected ? 1.8 : AppSizes.borderWidth,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              ThemeStudioFonts.displayName(font),
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelMedium?.copyWith(
                                fontFamily: font,
                                fontSize: AppFontSizes.caption,
                                fontWeight: FontWeight.w700,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              size: AppIconSizes.sm,
                              color: theme.accentPalette.isNotEmpty
                                  ? theme.accentPalette.first
                                  : AppColors.neonLavender,
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        ThemeStudioFonts.tagline(font),
                        style: context.textTheme.labelSmall?.copyWith(
                          fontFamily: font,
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
          }).toList(),
        ),
      ],
    );
  }
}
