import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../data/models/dynamic_theme_model.dart';
import 'theme_studio_section_label.dart';

/// Sample habit card rendered entirely from the working (draft) theme.
class ThemeStudioPreviewCard extends StatelessWidget {
  final UserThemeModel theme;
  final ThemeData previewTheme;
  final Color activeAccent;

  const ThemeStudioPreviewCard({
    super.key,
    required this.theme,
    required this.previewTheme,
    required this.activeAccent,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = previewTheme.textTheme.labelSmall?.copyWith(
      fontFamily: theme.fontFamily,
      fontSize: AppFontSizes.labelSmall,
      color: activeAccent,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ThemeStudioSectionLabel(
              text: 'LIVE PREVIEW',
              theme: theme,
              previewTheme: previewTheme,
              letterSpacing: 1.2,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: activeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: activeAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                theme.fontFamily,
                style: labelStyle?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: activeAccent,
              width: AppSizes.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: activeAccent.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: activeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 15.r,
                          color: activeAccent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '14 DAY STREAK',
                          style: labelStyle?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeAccent,
                      boxShadow: [
                        BoxShadow(
                          color: activeAccent.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: previewTheme.colorScheme.onPrimary,
                      size: AppIconSizes.md,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Morning Mindfulness & Flow',
                style: previewTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: theme.textPrimary,
                  fontSize: AppFontSizes.headlineSmall,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '20 mins • Completed today at 7:30 AM',
                style: previewTheme.textTheme.bodyMedium?.copyWith(
                  color: theme.textPrimary.withValues(alpha: 0.7),
                  fontSize: AppFontSizes.bodySmall,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: theme.accentPalette.map((color) {
                  return Container(
                    margin: EdgeInsets.only(right: 6.w),
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
