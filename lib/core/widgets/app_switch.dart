import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Compact pill toggle used for every on/off setting in the app.
///
/// Draws a slim 40×22 track (vs. the 52×32 Material switch) while keeping a
/// full [AppSizes.minTapTarget] hit area for accessibility.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Track color when on. Defaults to the theme primary accent.
  final Color? activeColor;

  /// Screen-reader label; pair it with the row title.
  final String? semanticLabel;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.semanticLabel,
  });

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final accent = activeColor ?? context.primaryAccent;
    final trackWidth = 40.r;
    final trackHeight = 22.r;
    final inset = 3.r;
    final thumbSize = trackHeight - inset * 2;

    final offTrack = context.isDarkMode
        ? context.surfaceElevatedColor
        : context.cardBorderColor;

    final track = AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      width: trackWidth,
      height: trackHeight,
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: value ? accent : offTrack,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: value ? accent : context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: AnimatedAlign(
        duration: _duration,
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: thumbSize - AppSizes.borderWidth * 2,
          height: thumbSize - AppSizes.borderWidth * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value || !context.isDarkMode
                ? AppColors.white
                : context.textSecondaryColor,
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                AppHaptics.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: SizedBox(
          width: AppSizes.minTapTarget,
          height: AppSizes.minTapTarget,
          child: Center(
            child: AnimatedOpacity(
              duration: _duration,
              opacity: enabled ? 1 : 0.45,
              child: track,
            ),
          ),
        ),
      ),
    );
  }
}
