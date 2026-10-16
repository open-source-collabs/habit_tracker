import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../themes/presentation/widgets/color_picker_dialog.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';
import 'habit_creator_accent.dart';

/// Theme palette swatches plus a custom Hex/HSL color entry point.
class HabitCreatorColorSection extends ConsumerWidget {
  final HabitModel? initialHabit;

  const HabitCreatorColorSection({super.key, required this.initialHabit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.accentPalette;
    final formState = ref.watch(habitCreatorFormProvider(initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(initialHabit).notifier,
    );
    final activeColor = resolveHabitCreatorAccent(context, formState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COLOR ACCENT', style: AppTextStyles.labelSmall(context)),
            Text(
              formState.customColor != null
                  ? 'Custom Hex / HSL'
                  : 'Theme Palette',
              style: context.textTheme.labelSmall?.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 10.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...List.generate(palette.length, (idx) {
              return _PaletteSwatch(
                color: palette[idx],
                isSelected:
                    formState.customColor == null &&
                    formState.selectedAccentIndex == idx,
                onTap: () {
                  AppHaptics.selectionClick();
                  formNotifier.setAccentIndex(idx);
                },
              );
            }),
            _CustomColorButton(
              customColor: formState.customColor,
              onTap: () async {
                AppHaptics.mediumImpact();
                final initialColor =
                    formState.customColor ??
                    palette.firstOrNull ??
                    context.primaryAccent;
                final picked = await ColorPickerDialog.show(
                  context,
                  initialColor: initialColor,
                  title: 'Custom Habit Color',
                );
                if (picked != null) {
                  formNotifier.setCustomColor(picked);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? context.textPrimaryColor
                : AppColors.transparent,
            width: 2.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check_rounded,
                  size: AppIconSizes.md,
                  color: habitCreatorOnColor(color),
                ),
              )
            : null,
      ),
    );
  }
}

/// Pill showing a hue-wheel dot and either "Custom" or the picked hex code.
class _CustomColorButton extends StatelessWidget {
  final Color? customColor;
  final VoidCallback onTap;

  const _CustomColorButton({required this.customColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final custom = customColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: custom != null
              ? custom.withValues(alpha: 0.18)
              : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: custom ?? context.cardBorderColor,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: AppColors.hueSpectrum),
                border: Border.all(color: context.cardBorderColor, width: 1),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              custom != null
                  ? '#${AppColors.colorToHex(custom).toUpperCase()}'
                  : 'Custom',
              style: context.textTheme.labelSmall?.copyWith(
                color: custom ?? context.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
