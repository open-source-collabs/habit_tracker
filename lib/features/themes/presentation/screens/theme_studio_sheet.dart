import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_factory.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/dynamic_theme_model.dart';
import '../providers/theme_provider.dart';
import '../providers/theme_studio_provider.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/theme_studio/theme_studio_accent_palette.dart';
import '../widgets/theme_studio/theme_studio_action_buttons.dart';
import '../widgets/theme_studio/theme_studio_chips_bar.dart';
import '../widgets/theme_studio/theme_studio_font_selector.dart';
import '../widgets/theme_studio/theme_studio_preview_card.dart';
import '../widgets/theme_studio/theme_studio_surfaces_palette.dart';

/// Interactive bottom sheet for creating, customizing, duplicating, and saving themes.
class ThemeStudioSheet extends ConsumerStatefulWidget {
  const ThemeStudioSheet({super.key});

  /// Displays the Theme Studio modal bottom sheet
  static Future<void> show(BuildContext context) {
    AppHaptics.mediumImpact();
    // Raw showModalBottomSheet on purpose: the studio paints its own
    // draggable surface in the *draft* theme's colors, so the modal itself
    // must stay transparent. showAppBottomSheet hard-codes the app's card
    // color, which would fill the area above the DraggableScrollableSheet.
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

  ThemeStudioWorkingThemeNotifier get _studio =>
      ref.read(themeStudioWorkingThemeNotifierProvider.notifier);

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
    final draft = _workingTheme.copyWith(
      name: _nameController.text.trim().isEmpty
          ? 'Custom Theme'
          : _nameController.text.trim(),
      isBuiltIn: false,
    );

    // Saving an edited preset yields a new custom theme with its own id;
    // keep editing that one rather than the untouched preset.
    final updatedTheme = await ref
        .read(themeProvider.notifier)
        .saveCustomTheme(draft);
    ref
        .read(themeStudioWorkingThemeNotifierProvider.notifier)
        .setWorkingTheme(updatedTheme);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Theme "${updatedTheme.name}" saved & applied!',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.onPrimaryColor,
            ),
          ),
          backgroundColor: updatedTheme.accentPalette.isNotEmpty
              ? updatedTheme.accentPalette.first
              : AppColors.emeraldMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Future<void> _duplicateTheme() async {
    AppHaptics.mediumImpact();
    final duplicated = await ref
        .read(themeProvider.notifier)
        .duplicateTheme(_workingTheme);
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
    final previewThemeData = ThemeFactory.applyScreenScale(
      ThemeFactory.createTheme(_workingTheme),
    );
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
            borderRadius: AppRadius.sheetBorderRadius,
            border: Border.all(
              color: _workingTheme.cardBorder,
              width: AppSizes.borderWidth,
            ),
            boxShadow: [
              const BoxShadow(
                color: AppColors.overlay50,
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 44.w,
                height: 4.5.w,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Studio',
                            style: previewThemeData.textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Design, customize, and persist dynamic themes',
                            style: previewThemeData.textTheme.bodySmall
                                ?.copyWith(
                                  color: _workingTheme.textPrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close,
                      tooltip: 'Close',
                      color: _workingTheme.textPrimary,
                      backgroundColor: AppColors.transparent,
                      border: false,
                      iconSize: AppIconSizes.xl,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  children: [
                    // Theme Selector Chips & New Button
                    ThemeStudioChipsBar(
                      themes: themeState.allThemes,
                      workingTheme: _workingTheme,
                      onSelectTheme: _onSelectTheme,
                      onCreateNew: _createNewTheme,
                    ),
                    SizedBox(height: 10.h),

                    // LIVE PREVIEW CARD
                    ThemeStudioPreviewCard(
                      theme: _workingTheme,
                      previewTheme: previewThemeData,
                      activeAccent: activeAccent,
                    ),
                    SizedBox(height: 12.h),

                    // Theme Name Field
                    _buildThemeNameField(previewThemeData),
                    SizedBox(height: 10.h),

                    // OFFLINE FONT SELECTOR
                    ThemeStudioFontSelector(
                      theme: _workingTheme,
                      previewTheme: previewThemeData,
                      onFontSelected: _updateFont,
                    ),
                    SizedBox(height: 12.h),

                    // SURFACES & BORDER PALETTE
                    ThemeStudioSurfacesPalette(
                      theme: _workingTheme,
                      previewTheme: previewThemeData,
                      onPickColor: _pickColor,
                      onScaffoldBgChanged: (c) => _studio.updateScaffoldBg(c),
                      onCardBgChanged: (c) => _studio.updateCardBg(c),
                      onCardBorderChanged: (c) => _studio.updateCardBorder(c),
                      onTextPrimaryChanged: (c) => _studio.updateTextPrimary(c),
                    ),
                    SizedBox(height: 12.h),

                    // CUSTOM HABIT ACCENT PALETTE
                    ThemeStudioAccentPalette(
                      theme: _workingTheme,
                      previewTheme: previewThemeData,
                      onPickColor: _pickColor,
                      onAccentChanged: (i, c) =>
                          _studio.updatePaletteColor(i, c),
                      onResetPalette: () => _studio.resetPalette(),
                    ),
                    SizedBox(height: 14.h),

                    // ACTION BUTTONS
                    ThemeStudioActionButtons(
                      previewTheme: previewThemeData,
                      activeAccent: activeAccent,
                      canDelete: !_workingTheme.isBuiltIn,
                      onSave: _saveTheme,
                      onDuplicate: _duplicateTheme,
                      onDelete: _deleteTheme,
                    ),
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

  Widget _buildThemeNameField(ThemeData previewTheme) {
    return AppTextField(
      controller: _nameController,
      labelText: 'Theme Name',
      accentColor: previewTheme.colorScheme.primary,
      // TextField merges this onto the ambient bodyLarge, as before.
      style: context.textTheme.bodyLarge?.copyWith(
        fontFamily: _workingTheme.fontFamily,
        color: _workingTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onChanged: (val) =>
          _studio.updateTheme((current) => current.copyWith(name: val)),
    );
  }
}
