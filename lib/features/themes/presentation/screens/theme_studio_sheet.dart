import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_factory.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/dynamic_theme_model.dart';
import '../providers/theme_provider.dart';
import '../providers/theme_studio_provider.dart';
import '../widgets/color_picker_dialog.dart';

/// Interactive bottom sheet for creating, customizing, duplicating, and saving themes.
class ThemeStudioSheet extends ConsumerStatefulWidget {
  const ThemeStudioSheet({super.key});

  /// Displays the Theme Studio modal bottom sheet
  static Future<void> show(BuildContext context) {
    AppHaptics.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => const ThemeStudioSheet(),
    );
  }

  @override
  ConsumerState<ThemeStudioSheet> createState() => _ThemeStudioSheetState();
}

class _ThemeStudioSheetState extends ConsumerState<ThemeStudioSheet> {
  UserThemeModel get _workingTheme =>
      ref.watch(themeStudioWorkingThemeNotifierProvider);
  late TextEditingController _nameController;

  static const List<String> _fontRegistry = [
    'PlusJakartaSans',
    'Inter',
  ];

  @override
  void initState() {
    super.initState();
    final active = ref.read(themeProvider).activeTheme;
    _nameController = TextEditingController(text: active.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSelectTheme(UserThemeModel theme) {
    AppHaptics.selectionClick();
    ref
        .read(themeStudioWorkingThemeNotifierProvider.notifier)
        .setWorkingTheme(theme);
    _nameController.text = theme.name;
    ref.read(themeProvider.notifier).setActiveTheme(theme.id);
  }

  void _updateFont(String font) {
    AppHaptics.selectionClick();
    ref.read(themeStudioWorkingThemeNotifierProvider.notifier).updateFont(font);
  }

  Future<void> _pickColor({
    required String title,
    required Color currentColor,
    required void Function(Color newColor) onSelected,
  }) async {
    final picked = await ColorPickerDialog.show(
      context,
      title: title,
      initialColor: currentColor,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _saveTheme() async {
    AppHaptics.heavyImpact();
    final updatedTheme = _workingTheme.copyWith(
      name: _nameController.text.trim().isEmpty
          ? 'Custom Theme'
          : _nameController.text.trim(),
      isBuiltIn: false,
    );

    await ref.read(themeProvider.notifier).saveCustomTheme(updatedTheme);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Theme "${updatedTheme.name}" saved & applied!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: updatedTheme.accentPalette.isNotEmpty
              ? updatedTheme.accentPalette.first
              : AppColors.emeraldMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    }
  }

  Future<void> _duplicateTheme() async {
    AppHaptics.mediumImpact();
    final duplicated =
        await ref.read(themeProvider.notifier).duplicateTheme(_workingTheme);
    ref
        .read(themeStudioWorkingThemeNotifierProvider.notifier)
        .setWorkingTheme(duplicated);
    _nameController.text = duplicated.name;
  }

  Future<void> _deleteTheme() async {
    if (_workingTheme.isBuiltIn) return;
    AppHaptics.mediumImpact();
    final idToDelete = _workingTheme.id;
    await ref.read(themeProvider.notifier).deleteTheme(idToDelete);
    final nextActive = ref.read(themeProvider).activeTheme;
    ref
        .read(themeStudioWorkingThemeNotifierProvider.notifier)
        .setWorkingTheme(nextActive);
    _nameController.text = nextActive.name;
  }

  void _createNewTheme() {
    AppHaptics.lightImpact();
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newTheme = _workingTheme.copyWith(
      id: newId,
      name: 'My New Theme',
      isBuiltIn: false,
    );
    ref
        .read(themeStudioWorkingThemeNotifierProvider.notifier)
        .setWorkingTheme(newTheme);
    _nameController.text = newTheme.name;
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final previewThemeData = ThemeFactory.createTheme(_workingTheme);
    final activeAccent = _workingTheme.accentPalette.isNotEmpty
        ? _workingTheme.accentPalette.first
        : AppColors.neonLavender;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _workingTheme.scaffoldBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border.all(color: _workingTheme.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlay50,
                blurRadius: 30.r,
                offset: Offset(0, -6.h),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 44.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: _workingTheme.textPrimary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Studio',
                          style: previewThemeData.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Design, customize, and persist dynamic themes',
                          style: previewThemeData.textTheme.bodySmall?.copyWith(
                            color: _workingTheme.textPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _workingTheme.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w.clamp(14.0, 20.0), vertical: 6.h),
                  children: [
                    // Theme Selector Chips & New Button
                    _buildThemeChipsBar(themeState),
                    SizedBox(height: 10.h),

                    // LIVE PREVIEW CARD
                    _buildLivePreviewCard(previewThemeData, activeAccent),
                    SizedBox(height: 12.h),

                    // Theme Name Field
                    _buildThemeNameField(previewThemeData),
                    SizedBox(height: 10.h),

                    // OFFLINE FONT SELECTOR
                    _buildFontSelector(previewThemeData),
                    SizedBox(height: 12.h),

                    // SURFACES & BORDER PALETTE
                    _buildSurfacesPalette(previewThemeData),
                    SizedBox(height: 12.h),

                    // CUSTOM HABIT ACCENT PALETTE
                    _buildHabitAccentsSection(previewThemeData),
                    SizedBox(height: 14.h),

                    // ACTION BUTTONS
                    _buildActionButtons(activeAccent),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeChipsBar(UserThemeState themeState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...themeState.allThemes.map((theme) {
            final isSelected = _workingTheme.id == theme.id;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ChoiceChip(
                label: Text(theme.name),
                selected: isSelected,
                onSelected: (_) => _onSelectTheme(theme),
                selectedColor: _workingTheme.cardBg,
                backgroundColor: _workingTheme.scaffoldBg,
                labelStyle: TextStyle(
                  color: isSelected
                      ? _workingTheme.textPrimary
                      : _workingTheme.textPrimary.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.sp,
                ),
                side: BorderSide(
                  color: isSelected
                      ? (_workingTheme.accentPalette.isNotEmpty
                          ? _workingTheme.accentPalette.first
                          : _workingTheme.cardBorder)
                      : _workingTheme.cardBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            );
          }),
          ActionChip(
            avatar: Icon(Icons.add, size: 16.sp, color: _workingTheme.textPrimary),
            label: const Text('New Custom'),
            onPressed: _createNewTheme,
            backgroundColor: _workingTheme.cardBg,
            labelStyle: TextStyle(
              color: _workingTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
            side: BorderSide(color: _workingTheme.cardBorder, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(ThemeData previewTheme, Color activeAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LIVE PREVIEW',
              style: TextStyle(
                fontFamily: _workingTheme.fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: _workingTheme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: activeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: activeAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                _workingTheme.fontFamily,
                style: TextStyle(
                  fontFamily: _workingTheme.fontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: activeAccent,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        Container(
          padding: EdgeInsets.all(14.r.clamp(12.0, 16.0)),
          decoration: BoxDecoration(
            color: _workingTheme.cardBg,
            borderRadius: BorderRadius.circular(18.r.clamp(14.0, 20.0)),
            border: Border.all(
              color: activeAccent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: activeAccent.withValues(alpha: 0.35),
                blurRadius: 16.r,
                spreadRadius: 0,
                offset: Offset(0, 3.h),
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: activeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 15.sp, color: activeAccent),
                        SizedBox(width: 4.w),
                        Text(
                          '14 DAY STREAK',
                          style: TextStyle(
                            fontFamily: _workingTheme.fontFamily,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: activeAccent,
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
                          blurRadius: 6.r,
                        ),
                      ],
                    ),
                    child: Icon(Icons.check, color: previewTheme.colorScheme.onPrimary, size: 18.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Morning Mindfulness & Flow',
                style: previewTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: _workingTheme.textPrimary,
                  fontSize: 18.sp.clamp(16.0, 20.0),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '20 mins • Completed today at 7:30 AM',
                style: previewTheme.textTheme.bodyMedium?.copyWith(
                  color: _workingTheme.textPrimary.withValues(alpha: 0.7),
                  fontSize: 12.sp.clamp(11.0, 13.0),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: _workingTheme.accentPalette.map((color) {
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

  Widget _buildThemeNameField(ThemeData previewTheme) {
    return AppTextField(
      controller: _nameController,
      labelText: 'Theme Name',
      accentColor: previewTheme.colorScheme.primary,
      style: TextStyle(
        fontFamily: _workingTheme.fontFamily,
        color: _workingTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onChanged: (val) {
        ref
            .read(themeStudioWorkingThemeNotifierProvider.notifier)
            .updateTheme((current) => current.copyWith(name: val));
      },
    );
  }

  Widget _buildFontSelector(ThemeData previewTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OFFLINE FONT REGISTRY (2 PROFESSIONAL FONTS)',
          style: TextStyle(
            fontFamily: _workingTheme.fontFamily,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: _workingTheme.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: _fontRegistry.map((font) {
            final isSelected = _workingTheme.fontFamily == font;
            return Expanded(
              child: GestureDetector(
                onTap: () => _updateFont(font),
                child: Container(
                  margin: EdgeInsets.only(
                    right: font == _fontRegistry.first ? 10.w : 0,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: _workingTheme.cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isSelected
                          ? (_workingTheme.accentPalette.isNotEmpty
                              ? _workingTheme.accentPalette.first
                              : _workingTheme.cardBorder)
                          : _workingTheme.cardBorder,
                      width: isSelected ? 1.8 : 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            font == 'PlusJakartaSans'
                                ? 'Plus Jakarta Sans'
                                : 'Inter',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: _workingTheme.textPrimary,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              size: 16.sp,
                              color: _workingTheme.accentPalette.isNotEmpty
                                  ? _workingTheme.accentPalette.first
                                  : AppColors.neonLavender,
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        font == 'PlusJakartaSans'
                            ? 'Tactile Geometric Sans'
                            : 'Modern Precision Sans',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 11.sp,
                          color:
                              _workingTheme.textPrimary.withValues(alpha: 0.6),
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

  Widget _buildSurfacesPalette(ThemeData previewTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SURFACES & BORDER PALETTE',
          style: TextStyle(
            fontFamily: _workingTheme.fontFamily,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: _workingTheme.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 10.h),
        _buildColorTile(
          title: 'Scaffold Background',
          subtitle: _workingTheme.scaffoldBgHex,
          color: _workingTheme.scaffoldBg,
          onTap: () => _pickColor(
            title: 'Scaffold Background',
            currentColor: _workingTheme.scaffoldBg,
            onSelected: (col) => ref
                .read(themeStudioWorkingThemeNotifierProvider.notifier)
                .updateScaffoldBg(col),
          ),
        ),
        SizedBox(height: 8.h),
        _buildColorTile(
          title: 'Card Surface',
          subtitle: _workingTheme.cardBgHex,
          color: _workingTheme.cardBg,
          onTap: () => _pickColor(
            title: 'Card Surface',
            currentColor: _workingTheme.cardBg,
            onSelected: (col) => ref
                .read(themeStudioWorkingThemeNotifierProvider.notifier)
                .updateCardBg(col),
          ),
        ),
        SizedBox(height: 8.h),
        _buildColorTile(
          title: 'Card Border Tint',
          subtitle: _workingTheme.cardBorderHex,
          color: _workingTheme.cardBorder,
          onTap: () => _pickColor(
            title: 'Card Border Tint',
            currentColor: _workingTheme.cardBorder,
            onSelected: (col) => ref
                .read(themeStudioWorkingThemeNotifierProvider.notifier)
                .updateCardBorder(col),
          ),
        ),
        SizedBox(height: 8.h),
        _buildColorTile(
          title: 'Text Primary',
          subtitle: _workingTheme.textPrimaryHex,
          color: _workingTheme.textPrimary,
          onTap: () => _pickColor(
            title: 'Text Primary',
            currentColor: _workingTheme.textPrimary,
            onSelected: (col) => ref
                .read(themeStudioWorkingThemeNotifierProvider.notifier)
                .updateTextPrimary(col),
          ),
        ),
      ],
    );
  }

  Widget _buildColorTile({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _workingTheme.cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _workingTheme.cardBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: _workingTheme.textPrimary.withValues(alpha: 0.2),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: _workingTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _workingTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.sp,
                      color: _workingTheme.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              size: 16.sp,
              color: _workingTheme.textPrimary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitAccentsSection(ThemeData previewTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HABIT ACCENT PALETTE',
              style: TextStyle(
                fontFamily: _workingTheme.fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: _workingTheme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.lightImpact();
                ref
                    .read(themeStudioWorkingThemeNotifierProvider.notifier)
                    .resetPalette();
              },
              child: Text(
                'Reset to Preset',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _workingTheme.accentPalette.isNotEmpty
                      ? _workingTheme.accentPalette.first
                      : AppColors.neonLavender,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: List.generate(_workingTheme.accentPalette.length, (index) {
            final color = _workingTheme.accentPalette[index];
            return InkWell(
              onTap: () => _pickColor(
                title: 'Accent Color #${index + 1}',
                currentColor: color,
                onSelected: (newColor) {
                  ref
                      .read(themeStudioWorkingThemeNotifierProvider.notifier)
                      .updatePaletteColor(index, newColor);
                },
              ),
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _workingTheme.textPrimary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(Icons.colorize,
                    color: AppColors.white.withValues(alpha: 0.8), size: 16.sp),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Color activeAccent) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 42.h.clamp(38.0, 46.0),
          child: FilledButton.icon(
            icon: const Icon(Icons.palette),
            label: Text(
              'Save & Apply Theme',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: activeAccent,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: _saveTheme,
          ),
        ),
        SizedBox(height: 10.h),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.copy, size: 16.sp),
                label: const Text('Duplicate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _workingTheme.textPrimary,
                  side: BorderSide(color: _workingTheme.cardBorder, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: _duplicateTheme,
              ),
            ),
            if (!_workingTheme.isBuiltIn) ...[
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.delete_outline,
                      size: 16.sp, color: Theme.of(context).colorScheme.error),
                  label: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: _deleteTheme,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
