import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';

/// Interactive modal for selecting colors via Hue/Saturation/Lightness sliders,
/// direct Hex input, and curated quick-select palettes.
class ColorPickerDialog extends StatefulWidget {
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
      builder: (context) => ColorPickerDialog(
        initialColor: initialColor,
        title: title,
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSLColor _hslColor;
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
    _hslColor = HSLColor.fromColor(widget.initialColor);
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
    setState(() {
      _hslColor = newHsl;
      _hexController.text = AppColors.colorToHex(_hslColor.toColor());
    });
    AppHaptics.selectionClick();
  }

  void _onHexSubmitted(String hex) {
    final parsed = AppColors.hexToColor(hex, fallback: _hslColor.toColor());
    setState(() {
      _hslColor = HSLColor.fromColor(parsed);
      _hexController.text = AppColors.colorToHex(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hslColor.toColor();

    return Dialog(
      backgroundColor: context.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(
          color: context.cardBorderColor,
          width: 1.2,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400.w.clamp(320.0, 440.0)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
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
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20.sp),
                    onPressed: () => Navigator.of(context).pop(),
                    color: context.textMutedColor,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Preview Box & Hex Field
              Row(
                children: [
                  Container(
                    width: 56.r,
                    height: 56.r,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: context.cardBorderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.35),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Hex Code',
                        hintText: '#RRGGBB',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onSubmitted: _onHexSubmitted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Hue Slider
              Text(
                'Hue (${_hslColor.hue.round()}°)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.h,
                  thumbShape:
                      RoundSliderThumbShape(enabledThumbRadius: 9.r),
                ),
                child: Slider(
                  value: _hslColor.hue,
                  min: 0,
                  max: 360,
                  activeColor: currentColor,
                  onChanged: (val) => _updateHsl(_hslColor.withHue(val)),
                ),
              ),

              // Saturation Slider
              Text(
                'Saturation (${(_hslColor.saturation * 100).round()}%)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.h,
                  thumbShape:
                      RoundSliderThumbShape(enabledThumbRadius: 9.r),
                ),
                child: Slider(
                  value: _hslColor.saturation,
                  min: 0,
                  max: 1,
                  activeColor: currentColor,
                  onChanged: (val) =>
                      _updateHsl(_hslColor.withSaturation(val)),
                ),
              ),

              // Lightness Slider
              Text(
                'Lightness (${(_hslColor.lightness * 100).round()}%)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.h,
                  thumbShape:
                      RoundSliderThumbShape(enabledThumbRadius: 9.r),
                ),
                child: Slider(
                  value: _hslColor.lightness,
                  min: 0,
                  max: 1,
                  activeColor: currentColor,
                  onChanged: (val) => _updateHsl(_hslColor.withLightness(val)),
                ),
              ),
              SizedBox(height: 12.h),

              // Quick Swatches
              Text(
                'Curated Presets',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _curatedSwatches.map((color) {
                  final isSelected = currentColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () {
                      _updateHsl(HSLColor.fromColor(color));
                      AppHaptics.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 28.r,
                      height: 28.r,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8.r),
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
              SizedBox(height: 24.h),

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
                      foregroundColor: _hslColor.lightness > 0.6
                          ? AppColors.black87
                          : AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 12.h),
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
