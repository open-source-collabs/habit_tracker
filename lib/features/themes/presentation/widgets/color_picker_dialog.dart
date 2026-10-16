import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/color_picker_provider.dart';

/// Interactive modal for selecting colors via Hue/Saturation/Lightness sliders,
/// direct Hex input, and curated quick-select palettes.
class ColorPickerDialog extends ConsumerStatefulWidget {
  final Color initialColor;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'Select Color',
  });

  /// Static helper to display the dialog
  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String title = 'Select Color',
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) =>
          ColorPickerDialog(initialColor: initialColor, title: title),
    );
  }

  @override
  ConsumerState<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends ConsumerState<ColorPickerDialog> {
  late TextEditingController _hexController;

  static const List<Color> _curatedSwatches = [
    // Surfaces
    AppColors.nordicTeal,
    AppColors.nordicMist,
    AppColors.peachMist,
    AppColors.obsidianTwilight,
    AppColors.cardSurface,
    AppColors.white,
    // Vibrant Accents
    AppColors.sunsetCoral,
    AppColors.neonLavender,
    AppColors.emeraldMint,
    AppColors.cyanGlow,
    AppColors.mangoSunrise,
    AppColors.roseQuartz,
  ];

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(
      text: AppColors.colorToHex(widget.initialColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateHsl(HSLColor newHsl) {
    ref
        .read(colorPickerProvider(widget.initialColor).notifier)
        .updateHsl(newHsl);
    _hexController.text = AppColors.colorToHex(newHsl.toColor());
    AppHaptics.selectionClick();
  }

  void _onHexSubmitted(String hex) {
    ref
        .read(colorPickerProvider(widget.initialColor).notifier)
        .updateFromHex(hex);
    final current = ref
        .read(colorPickerProvider(widget.initialColor))
        .toColor();
    _hexController.text = AppColors.colorToHex(current);
  }

  @override
  Widget build(BuildContext context) {
    final hslColor = ref.watch(colorPickerProvider(widget.initialColor));
    final currentColor = hslColor.toColor();

    return Dialog(
      backgroundColor: context.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontSize: AppFontSizes.titleMedium,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: AppIconSizes.lg),
                    onPressed: () => Navigator.of(context).pop(),
                    color: context.textMutedColor,
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Preview Box & Hex Field
              Row(
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: context.cardBorderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppTextField(
                      controller: _hexController,
                      labelText: 'Hex Code',
                      hintText: '#RRGGBB',
                      borderRadius: AppRadius.md,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                      onSubmitted: _onHexSubmitted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Hue Slider
              Text(
                'Hue (${hslColor.hue.round()}°)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: AppFontSizes.labelMedium,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.r,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                ),
                child: Slider(
                  value: hslColor.hue,
                  min: 0,
                  max: 360,
                  activeColor: currentColor,
                  onChanged: (val) => _updateHsl(hslColor.withHue(val)),
                ),
              ),

              // Saturation Slider
              Text(
                'Saturation (${(hslColor.saturation * 100).round()}%)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: AppFontSizes.labelMedium,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.r,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                ),
                child: Slider(
                  value: hslColor.saturation,
                  min: 0,
                  max: 1,
                  activeColor: currentColor,
                  onChanged: (val) => _updateHsl(hslColor.withSaturation(val)),
                ),
              ),

              // Lightness Slider
              Text(
                'Lightness (${(hslColor.lightness * 100).round()}%)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: AppFontSizes.labelMedium,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.r,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                ),
                child: Slider(
                  value: hslColor.lightness,
                  min: 0,
                  max: 1,
                  activeColor: currentColor,
                  onChanged: (val) => _updateHsl(hslColor.withLightness(val)),
                ),
              ),
              SizedBox(height: 8.h),

              // Quick Swatches
              Text(
                'Curated Presets',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: AppFontSizes.labelMedium,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: _curatedSwatches.map((color) {
                  final isSelected =
                      currentColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () {
                      ref
                          .read(
                            colorPickerProvider(widget.initialColor).notifier,
                          )
                          .updateColor(color);
                      _hexController.text = AppColors.colorToHex(color);
                      AppHaptics.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isSelected
                              ? context.textPrimaryColor
                              : context.cardBorderColor,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),

              // Confirm / Cancel Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: currentColor,
                      foregroundColor: hslColor.lightness > 0.6
                          ? context.textPrimaryColor
                          : context.onPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                    onPressed: () {
                      AppHaptics.lightImpact();
                      Navigator.of(context).pop(currentColor);
                    },
                    child: const Text('Apply Color'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
