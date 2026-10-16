import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../settings/presentation/providers/profile_provider.dart';
import '../../../themes/data/models/app_payload_model.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../domain/merge_engine.dart';
import '../providers/data_portability_provider.dart';

/// Modal dialog for 1-tap manual JSON export, conflict-free import/restore,
/// for manual backups and moving data between devices. Automatic cloud sync
/// lives in the Sync tab.
class DataPortabilityDialog extends ConsumerStatefulWidget {
  const DataPortabilityDialog({super.key});

  /// Displays the [DataPortabilityDialog].
  static Future<void> show(BuildContext context) {
    AppHaptics.mediumImpact();
    return showAppDialog(
      context: context,
      builder: (ctx) => const DataPortabilityDialog(),
    );
  }

  @override
  ConsumerState<DataPortabilityDialog> createState() =>
      _DataPortabilityDialogState();
}

class _DataPortabilityDialogState extends ConsumerState<DataPortabilityDialog> {
  final TextEditingController _jsonInputController = TextEditingController();

  @override
  void dispose() {
    _jsonInputController.dispose();
    super.dispose();
  }

  AppPayloadModel _buildCurrentPayload() {
    final habits = ref.read(habitListProvider).valueOrNull ?? [];
    final themeState = ref.read(themeProvider);

    return AppPayloadModel(
      version: AppPayloadModel.currentSchemaVersion,
      lastModifiedBy: 'manual_portability',
      lastModifiedAt: DateTime.now(),
      activeThemeId: themeState.activeThemeId,
      userThemes: themeState.allThemes,
      habits: habits,
      displayName: ref.read(displayNameProvider),
    );
  }

  Future<void> _handleExportCopy() async {
    AppHaptics.selectionClick();
    final payload = _buildCurrentPayload();
    final jsonString = payload.toRawJson(pretty: true);

    await Clipboard.setData(ClipboardData(text: jsonString));

    if (mounted) {
      ref
          .read(dataPortabilityProvider.notifier)
          .setExportSuccess(
            'Database JSON copied! (${payload.habits.length} habits, ${utf8.encode(jsonString).length} bytes)',
          );
    }
  }

  Future<void> _handlePasteFromClipboard() async {
    AppHaptics.selectionClick();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();

    if (text == null || text.isEmpty) {
      ref
          .read(dataPortabilityProvider.notifier)
          .setImportError('Clipboard is empty or does not contain text.');
      return;
    }

    _jsonInputController.text = text;
    ref.read(dataPortabilityProvider.notifier).validateAndParseJson(text);
  }

  Future<void> _applyPayload({
    required AppPayloadModel payloadToApply,
    required String successDescription,
  }) async {
    ref.read(dataPortabilityProvider.notifier).setProcessing(true);
    try {
      // Each notifier updates its slice and persists it through the app data
      // repository, which serializes the writes.
      await ref
          .read(habitListProvider.notifier)
          .restoreHabits(payloadToApply.habits);
      await ref
          .read(themeProvider.notifier)
          .restoreThemes(
            themes: payloadToApply.userThemes,
            activeThemeId: payloadToApply.activeThemeId,
          );
      // Older exports have no name; keep the current one rather than wipe it.
      if (payloadToApply.displayName.isNotEmpty) {
        await ref
            .read(displayNameProvider.notifier)
            .setDisplayName(payloadToApply.displayName);
      }

      AppHaptics.heavyImpact();

      if (mounted) {
        ref.read(dataPortabilityProvider.notifier).setProcessing(false);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successDescription,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: context.cardBackgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              side: BorderSide(
                color: context.primaryAccent,
                width: AppSizes.borderWidth,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(dataPortabilityProvider.notifier)
            .setImportError('Failed to apply database: $e');
        ref.read(dataPortabilityProvider.notifier).setProcessing(false);
      }
    }
  }

  Future<void> _handleMerge() async {
    final parsedPayload = ref.read(dataPortabilityProvider).parsedImportPayload;
    if (parsedPayload == null) return;
    AppHaptics.mediumImpact();

    final localPayload = _buildCurrentPayload();
    final merged = mergePayloads(local: localPayload, incoming: parsedPayload);

    await _applyPayload(
      payloadToApply: merged,
      successDescription:
          'Data merged conflict-free! (${merged.habits.length} habits, ${merged.userThemes.length} themes)',
    );
  }

  Future<void> _handleOverwrite() async {
    final parsedPayload = ref.read(dataPortabilityProvider).parsedImportPayload;
    if (parsedPayload == null) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Overwrite Local Database?',
      message: 'This will replace your current habits and custom themes with the imported JSON.',
      confirmText: 'Restore & Replace',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _applyPayload(
        payloadToApply: parsedPayload,
        successDescription: 'Database fully restored from JSON backup!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final portabilityState = ref.watch(dataPortabilityProvider);
    final currentPayload = _buildCurrentPayload();
    final totalCheckIns = currentPayload.habits.fold<int>(
      0,
      (sum, h) => sum + h.checkIns.values.where((v) => v).length,
    );
    final customThemesCount = currentPayload.userThemes
        .where((t) => !t.isBuiltIn)
        .length;

    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      shadowColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Material(
        color: AppColors.transparent,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: AppSizes.dialogMaxWidth,
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: context.cardBorderColor,
                width: AppSizes.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Bar
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: context.primaryAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sync_rounded,
                          color: context.primaryAccent,
                          size: AppIconSizes.lg,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Portability & Sync',
                              style: AppTextStyles.titleMedium(context)
                                  .copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: AppFontSizes.subtitle,
                                  ),
                            ),
                            Text(
                              'Export, restore, or merge your data as JSON',
                              style: AppTextStyles.labelSmall(
                                context,
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        color: context.textSecondaryColor,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Local Database Stats Card
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: context.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: context.cardBorderColor,
                        width: AppSizes.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          label: 'HABITS',
                          value: '${currentPayload.habits.length}',
                        ),
                        _buildStatItem(
                          label: 'CHECK-INS',
                          value: '$totalCheckIns',
                        ),
                        _buildStatItem(
                          label: 'CUSTOM THEMES',
                          value: '$customThemesCount',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Section 1: 1-Tap Manual JSON Export
                  Text(
                    '1-TAP DATABASE EXPORT',
                    style: AppTextStyles.labelSmall(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.textMutedColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AppButton(
                    text: 'Copy Database JSON to Clipboard',
                    leadingIcon: const Icon(Icons.copy_rounded),
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.md,
                    glow: true,
                    onPressed: _handleExportCopy,
                  ),
                  if (portabilityState.exportSuccessMessage != null) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: context.primaryAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: context.primaryAccent,
                            size: AppIconSizes.sm,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              portabilityState.exportSuccessMessage!,
                              style: AppTextStyles.labelSmall(
                                context,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),

                  // Section 2: 1-Tap Manual JSON Import
                  Text(
                    '1-TAP DATABASE IMPORT / RESTORE',
                    style: AppTextStyles.labelSmall(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.textMutedColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AppButton(
                    text: 'Paste JSON from Clipboard',
                    leadingIcon: const Icon(Icons.paste_rounded),
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.md,
                    onPressed: _handlePasteFromClipboard,
                  ),
                  SizedBox(height: 8.h),
                  AppTextField(
                    controller: _jsonInputController,
                    labelText: 'OR PASTE RAW JSON PAYLOAD',
                    hintText: '{\n  "version": 1,\n  "habits": [...]\n}',
                    maxLines: 4,
                    onChanged: (text) => ref
                        .read(dataPortabilityProvider.notifier)
                        .validateAndParseJson(text),
                  ),

                  // Parse status / validation feedback
                  if (portabilityState.importErrorMessage != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      portabilityState.importErrorMessage!,
                      style: AppTextStyles.labelSmall(
                        context,
                        color: context.colorScheme.error,
                      ),
                    ),
                  ],

                  if (portabilityState.parsedImportPayload != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: context.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: context.primaryAccent,
                          width: AppSizes.borderWidth,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AppBadge(
                                  label: 'VALID DATABASE PAYLOAD',
                                  color: context.primaryAccent,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'v${portabilityState.parsedImportPayload!.version}',
                                style: AppTextStyles.labelSmall(
                                  context,
                                  color: context.textMutedColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Contains ${portabilityState.parsedImportPayload!.habits.length} habits and ${portabilityState.parsedImportPayload!.userThemes.where((t) => !t.isBuiltIn).length} custom themes.',
                            style: AppTextStyles.bodySmall(context),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Merge (Zero Loss)',
                                  variant: AppButtonVariant.primary,
                                  size: AppButtonSize.sm,
                                  isLoading: portabilityState.isProcessing,
                                  onPressed: _handleMerge,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: AppButton(
                                  text: 'Overwrite All',
                                  variant: AppButtonVariant.danger,
                                  size: AppButtonSize.sm,
                                  isLoading: portabilityState.isProcessing,
                                  onPressed: _handleOverwrite,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium(context).copyWith(
            fontWeight: FontWeight.w800,
            color: context.primaryAccent,
            fontSize: AppFontSizes.titleMedium,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style:
              AppTextStyles.labelSmall(
                context,
                color: context.textMutedColor,
              ).copyWith(
                fontSize: AppFontSizes.micro,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
