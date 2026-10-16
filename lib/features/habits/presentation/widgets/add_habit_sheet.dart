import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/habit_model.dart';
import '../providers/add_habit_form_provider.dart';
import '../providers/habit_provider.dart';

/// Professional, responsive creation sheet/dialog for adding new habits.
/// - Mobile (<768px): Renders as a smooth modal bottom sheet with drag handle.
/// - Desktop (≥768px): Renders as a centered modal dialog with frosted backdrop.
class AddHabitSheet extends ConsumerStatefulWidget {
  final bool isDialog;

  const AddHabitSheet({super.key, this.isDialog = false});

  /// Displays the habit creation form adaptively based on screen width.
  static Future<HabitModel?> show(BuildContext context) {
    AppHaptics.mediumImpact();
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return showDialog<HabitModel>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => const AddHabitSheet(isDialog: true),
      );
    } else {
      return showAppBottomSheet<HabitModel>(
        context: context,
        builder: (ctx) => const AddHabitSheet(isDialog: false),
      );
    }
  }

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();

  static const _routineItems = [
    AppDropdownItem(
      value: 'General',
      label: 'General Routine',
      icon: Text('🎯'),
    ),
    AppDropdownItem(
      value: 'Morning',
      label: 'Morning Routine',
      icon: Text('☀️'),
    ),
    AppDropdownItem(value: 'Focus', label: 'Deep Focus', icon: Text('⚡')),
    AppDropdownItem(
      value: 'Health',
      label: 'Health & Hydration',
      icon: Text('💧'),
    ),
    AppDropdownItem(value: 'Evening', label: 'Evening Calm', icon: Text('🌙')),
    AppDropdownItem(value: 'Fitness', label: 'Fitness & Gym', icon: Text('💪')),
  ];

  static const _frequencyOptions = [
    {'label': 'Daily', 'desc': 'Every day'},
    {'label': 'Weekdays', 'desc': 'Mon – Fri'},
    {'label': '3x / Week', 'desc': 'Flexible target'},
    {'label': '5x / Week', 'desc': 'High intensity'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  HabitFrequency _buildSelectedFrequency(int frequencyIndex) {
    switch (frequencyIndex) {
      case 1:
        return const HabitFrequency.specificWeekdays([
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ]);
      case 2:
        return const HabitFrequency.timesPerWeek(3);
      case 3:
        return const HabitFrequency.timesPerWeek(5);
      case 0:
      default:
        return const HabitFrequency.daily();
    }
  }

  String _getCategoryEmoji(String routine) {
    switch (routine.toLowerCase()) {
      case 'morning':
        return '☀️';
      case 'focus':
        return '⚡';
      case 'health':
        return '💧';
      case 'evening':
        return '🌙';
      case 'fitness':
        return '💪';
      case 'general':
      default:
        return '🎯';
    }
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppHaptics.heavyImpact();
      ref
          .read(addHabitFormProvider.notifier)
          .setTitleError('Please enter a habit title');
      return;
    }

    final formState = ref.read(addHabitFormProvider);
    final newHabit = HabitModel(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: _subtitleController.text.trim(),
      frequency: _buildSelectedFrequency(formState.selectedFrequencyIndex),
      routineGroup: formState.selectedRoutine,
      accentIndex: formState.selectedAccent,
      createdAt: DateTime.now(),
      emoji: _getCategoryEmoji(formState.selectedRoutine),
    );

    ref.read(habitListProvider.notifier).createHabit(newHabit);
    AppHaptics.heavyImpact();
    Navigator.of(context).pop(newHabit);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogLayout(context);
    }
    return _buildBottomSheetLayout(context);
  }

  Widget _buildDialogLayout(BuildContext context) {
    return AppDialog(
      title: 'New Habit',
      message: 'Establish a new intentional routine to track daily.',
      icon: Icon(
        Icons.add_task_rounded,
        size: AppIconSizes.xl,
        color: context.primaryAccent,
      ),
      content: _buildFormFields(context),
      confirmText: 'Add Habit',
      cancelText: 'Cancel',
      onConfirm: _handleSubmit,
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildBottomSheetLayout(BuildContext context) {
    return AppBottomSheet(
      title: 'New Habit',
      subtitle: 'Establish a new intentional routine to track daily.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _buildFormFields(context),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.md,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Add Habit',
                  leadingIcon: const Icon(Icons.add_task_rounded),
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.md,
                  glow: true,
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    final palette = context.accentPalette;
    final formState = ref.watch(addHabitFormProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _titleController,
          labelText: 'HABIT TITLE',
          hintText: 'e.g. Morning Breathwork',
          errorText: formState.titleError,
          showClearButton: true,
          autofocus: true,
          prefixIcon: Icon(
            Icons.edit_note_rounded,
            size: AppIconSizes.lg,
            color: formState.titleError != null
                ? AppColors.error
                : context.primaryAccent,
          ),
          onChanged: (val) {
            if (formState.titleError != null && val.trim().isNotEmpty) {
              ref.read(addHabitFormProvider.notifier).clearError();
            }
          },
          onSubmitted: (_) => _handleSubmit(),
        ),
        SizedBox(height: 10.h),
        AppTextField(
          controller: _subtitleController,
          labelText: 'SUBTITLE / NOTES',
          hintText: 'e.g. 15 minutes outdoors',
          prefixIcon: Icon(
            Icons.notes_rounded,
            size: AppIconSizes.md,
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 10.h),
        AppDropdown<String>(
          labelText: 'ROUTINE CATEGORY',
          value: formState.selectedRoutine,
          items: _routineItems,
          onChanged: (val) {
            ref.read(addHabitFormProvider.notifier).setRoutine(val);
          },
        ),
        SizedBox(height: 10.h),
        Text('SCHEDULE FREQUENCY', style: AppTextStyles.labelSmall(context)),
        SizedBox(height: 6.h),
        _buildFrequencyChips(context, formState),
        SizedBox(height: 10.h),
        Text('ACCENT COLOR', style: AppTextStyles.labelSmall(context)),
        SizedBox(height: 6.h),
        _buildAccentColorPicker(context, palette, formState),
      ],
    );
  }

  Widget _buildFrequencyChips(
    BuildContext context,
    AddHabitFormState formState,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_frequencyOptions.length, (idx) {
          final isSelected = formState.selectedFrequencyIndex == idx;
          final option = _frequencyOptions[idx];

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                ref.read(addHabitFormProvider.notifier).setFrequencyIndex(idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: _chipDecoration(
                  context: context,
                  isSelected: isSelected,
                  accentColor: context.primaryAccent,
                ),
                child: Text(
                  option['label']!,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? context.onPrimaryColor
                        : context.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: AppFontSizes.bodySmall,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  BoxDecoration _chipDecoration({
    required BuildContext context,
    required bool isSelected,
    Color? accentColor,
  }) {
    final primary = accentColor ?? context.primaryAccent;
    return BoxDecoration(
      color: isSelected ? primary : context.cardBackgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      border: Border.all(
        color: isSelected ? primary : context.cardBorderColor,
        width: AppSizes.borderWidth,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : const [],
    );
  }

  Widget _buildAccentColorPicker(
    BuildContext context,
    List<Color> palette,
    AddHabitFormState formState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(palette.length, (idx) {
        final color = palette[idx];
        final isSelected = formState.selectedAccent == idx;
        final isBright = color.computeLuminance() > 0.55;
        final checkmarkColor = isBright
            ? AppColors.darkScaffold
            : AppColors.white;

        return GestureDetector(
          onTap: () {
            AppHaptics.selectionClick();
            ref.read(addHabitFormProvider.notifier).setAccent(idx);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: context.cardBackgroundColor, width: 2.5)
                  : null,
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
                      color: checkmarkColor,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}
