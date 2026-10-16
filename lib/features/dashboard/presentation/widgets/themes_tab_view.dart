import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../themes/data/models/dynamic_theme_model.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../../themes/presentation/screens/theme_studio_sheet.dart';

/// Interactive Themes Tab View enabling live theme switching,
/// preset gallery browsing, and launching the full Theme Studio.
class ThemesTabView extends ConsumerWidget {
  const ThemesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final activeTheme = themeState.activeTheme;
    final primaryAccent = context.primaryAccent;
    final isDesktop = MediaQuery.of(context).size.width >= 768.0;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.0 : 16.w.clamp(14.0, 20.0),
        vertical: 10.h,
      ),
      children: [
        // Section Header
        Text(
          'THEMES & PALETTES',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 11.sp.clamp(10.0, 12.0),
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 8.h),

        // Active Theme Showcase Card
        AppCard(
          padding: EdgeInsets.all(14.r.clamp(12.0, 18.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.pastelSurface(
                            primaryAccent,
                            isDark: context.isDarkMode,
                            opacity: 0.18,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.palette_rounded,
                          color: primaryAccent,
                          size: 20.sp.clamp(18.0, 22.0),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeTheme.name,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                              fontSize: 15.sp.clamp(14.0, 17.0),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Font: ${activeTheme.fontFamily}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.textMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'Open Studio',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    onPressed: () => ThemeStudioSheet.show(context),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'ACTIVE ACCENT PALETTE',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 10.sp.clamp(9.0, 11.0),
                  color: context.textMutedColor,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: context.accentPalette.map((color) {
                  return Container(
                    margin: EdgeInsets.only(right: 8.w),
                    width: 24.w.clamp(20.0, 28.0),
                    height: 24.h.clamp(20.0, 28.0),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.cardBorderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // User-created themes, then built-in presets
        if (themeState.customThemes.isNotEmpty) ...[
          _buildSectionLabel(context, 'YOUR THEMES'),
          SizedBox(height: 8.h),
          ...themeState.customThemes.map(
            (theme) => _buildThemeTile(context, ref, theme, activeTheme),
          ),
          SizedBox(height: 10.h),
        ],
        _buildSectionLabel(context, 'BUILT-IN THEME PRESETS'),
        SizedBox(height: 8.h),
        ...UserThemeModel.builtInPresets.map(
          (preset) => _buildThemeTile(context, ref, preset, activeTheme),
        ),

        // Safe spacing for floating navbar
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: context.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        fontSize: 11.sp.clamp(10.0, 12.0),
        color: context.textMutedColor,
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref,
    UserThemeModel preset,
    UserThemeModel activeTheme,
  ) {
    final primaryAccent = context.primaryAccent;
    final isSelected = preset.id == activeTheme.id;
    final presetAccent = preset.accentPalette.isNotEmpty
        ? preset.accentPalette.first
        : primaryAccent;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AppCard(
        isInteractive: true,
        onTap: () {
          AppHaptics.selectionClick();
          ref.read(themeProvider.notifier).setActiveTheme(preset.id);
        },
        borderColor: isSelected ? primaryAccent : context.cardBorderColor,
        backgroundColor: isSelected
            ? AppColors.pastelSurface(
                primaryAccent,
                isDark: context.isDarkMode,
                opacity: 0.12,
              )
            : context.cardBackgroundColor,
        padding: EdgeInsets.all(12.r.clamp(10.0, 14.0)),
        child: Row(
          children: [
            Container(
              width: 32.w.clamp(28.0, 36.0),
              height: 32.h.clamp(28.0, 36.0),
              decoration: BoxDecoration(
                color: preset.scaffoldBg,
                shape: BoxShape.circle,
                border: Border.all(color: presetAccent, width: 2.0),
              ),
              child: Center(
                child: Container(
                  width: 14.w.clamp(12.0, 16.0),
                  height: 14.h.clamp(12.0, 16.0),
                  decoration: BoxDecoration(
                    color: presetAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      fontSize: 14.sp.clamp(13.0, 16.0),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: preset.accentPalette.take(4).map((c) {
                      return Container(
                        margin: EdgeInsets.only(right: 5.w),
                        width: 12.w.clamp(10.0, 14.0),
                        height: 12.h.clamp(10.0, 14.0),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16.sp,
                  color: context.onPrimaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
