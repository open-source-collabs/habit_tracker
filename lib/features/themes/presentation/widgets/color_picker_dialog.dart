import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    AppColors.porcelainCard,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF181924) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF262837) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview Box & Hex Field
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Hex Code',
                        hintText: '#RRGGBB',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: _onHexSubmitted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hue Slider
              Text(
                'Hue (${_hslColor.hue.round()}°)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 9),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 9),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  value: _hslColor.lightness,
                  min: 0,
                  max: 1,
                  activeColor: currentColor,
                  onChanged: (val) => _updateHsl(_hslColor.withLightness(val)),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Swatches
              Text(
                'Curated Presets',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _curatedSwatches.map((color) {
                  final isSelected = currentColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () {
                      _updateHsl(HSLColor.fromColor(color));
                      AppHaptics.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.white24,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Confirm / Cancel Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: currentColor,
                      foregroundColor: _hslColor.lightness > 0.6
                          ? Colors.black87
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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
