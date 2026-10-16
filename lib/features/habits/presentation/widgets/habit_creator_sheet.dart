import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/habit_model.dart';
import '../providers/habit_creator_form_provider.dart';
import '../providers/habit_provider.dart';
import 'habit_creator/habit_creator_color_section.dart';
import 'habit_creator/habit_creator_footer.dart';
import 'habit_creator/habit_creator_frame.dart';
import 'habit_creator/habit_creator_frequency_section.dart';
import 'habit_creator/habit_creator_header.dart';
import 'habit_creator/habit_creator_icon_section.dart';
import 'habit_creator/habit_creator_identity_section.dart';
import 'habit_creator/habit_creator_reminder_section.dart';
import 'habit_creator/habit_creator_routine_section.dart';

/// Interactive Habit Creation Studio modal sheet and dialog.
/// Supports active theme font styling, dynamic theme palette or custom Hex/HSL color picking,
/// tabbed Material icon and emoji selectors, flexible frequency configuration,
/// dynamic routine groupings, and offline native notification alarm scheduling.
///
/// The individual studio sections live in `habit_creator/`; this widget owns
/// the text controllers, assembles the form and builds the [HabitModel] on submit.
class HabitCreatorSheet extends ConsumerStatefulWidget {
  final HabitModel? initialHabit;
  final bool isDialog;

  const HabitCreatorSheet({
    super.key,
    this.initialHabit,
    this.isDialog = false,
  });

  /// Displays the habit creation studio adaptively based on screen width.
  static Future<HabitModel?> show(
    BuildContext context, {
    HabitModel? initialHabit,
  }) {
    AppHaptics.mediumImpact();
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return showDialog<HabitModel>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) =>
            HabitCreatorSheet(initialHabit: initialHabit, isDialog: true),
      );
    } else {
      return showAppBottomSheet<HabitModel>(
        context: context,
        builder: (ctx) =>
            HabitCreatorSheet(initialHabit: initialHabit, isDialog: false),
      );
    }
  }

  @override
  ConsumerState<HabitCreatorSheet> createState() => _HabitCreatorSheetState();
}

class _HabitCreatorSheetState extends ConsumerState<HabitCreatorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _customRoutineController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _subtitleController = TextEditingController(text: initial?.subtitle ?? '');
    _customRoutineController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _customRoutineController.dispose();
    super.dispose();
  }

  HabitFrequency _buildFrequency(HabitCreatorFormState formState) {
    switch (formState.frequencyType) {
      case HabitFrequencyType.daily:
        return const HabitFrequency.daily();
      case HabitFrequencyType.specificWeekdays:
        final days = List<int>.from(formState.selectedDaysOfWeek)..sort();
        return HabitFrequency.specificWeekdays(
          days.isEmpty ? const [1, 2, 3, 4, 5] : days,
        );
      case HabitFrequencyType.timesPerWeek:
        return HabitFrequency.timesPerWeek(formState.targetTimesPerWeek);
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final formState = ref.read(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );

    if (title.isEmpty) {
      AppHaptics.heavyImpact();
      formNotifier.setTitleError('Please enter a habit title');
      return;
    }

    final routine =
        formState.isCreatingCustomRoutine &&
            _customRoutineController.text.trim().isNotEmpty
        ? _customRoutineController.text.trim()
        : formState.selectedRoutine;

    final habitId =
        widget.initialHabit?.id ??
        'habit_${DateTime.now().millisecondsSinceEpoch}';

    final reminderStr = formState.reminderEnabled
        ? '${formState.reminderTime.hour.toString().padLeft(2, '0')}:${formState.reminderTime.minute.toString().padLeft(2, '0')}'
        : null;

    final habit = HabitModel(
      id: habitId,
      title: title,
      subtitle: _subtitleController.text.trim(),
      frequency: _buildFrequency(formState),
      routineGroup: routine,
      accentIndex: formState.selectedAccentIndex >= 0
          ? formState.selectedAccentIndex
          : 0,
      customColorValue: formState.customColor?.toARGB32(),
      emoji: formState.isEmojiSelected ? formState.selectedEmoji : null,
      iconCode: !formState.isEmojiSelected ? formState.selectedIconCode : null,
      reminderTime: reminderStr,
      createdAt: widget.initialHabit?.createdAt ?? DateTime.now(),
      checkIns: widget.initialHabit?.checkIns ?? const {},
      isArchived: widget.initialHabit?.isArchived ?? false,
    );

    // The habit notifier schedules or cancels the reminder to match.
    // Saving is fire-and-forget: the sheet closes immediately and the notifier
    // already shows the change optimistically.
    final habits = ref.read(habitListProvider.notifier);
    unawaited(
      widget.initialHabit != null
          ? habits.updateHabit(habit)
          : habits.createHabit(habit),
    );

    AppHaptics.heavyImpact();
    Navigator.of(context).pop(habit);
  }

  @override
  Widget build(BuildContext context) {
    final header = HabitCreatorHeader(initialHabit: widget.initialHabit);
    final body = _buildFormContent();
    final footer = HabitCreatorFooter(
      isEditing: widget.initialHabit != null,
      onSubmit: _handleSubmit,
    );

    if (widget.isDialog) {
      return HabitCreatorDialogFrame(
        header: header,
        body: body,
        footer: footer,
      );
    }
    return HabitCreatorBottomSheetFrame(
      header: header,
      body: body,
      footer: footer,
    );
  }

  Widget _buildFormContent() {
    final initialHabit = widget.initialHabit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HabitCreatorIdentitySection(
          initialHabit: initialHabit,
          titleController: _titleController,
          subtitleController: _subtitleController,
        ),
        SizedBox(height: 12.h),
        HabitCreatorColorSection(initialHabit: initialHabit),
        SizedBox(height: 12.h),
        HabitCreatorIconSection(initialHabit: initialHabit),
        SizedBox(height: 12.h),
        HabitCreatorFrequencySection(initialHabit: initialHabit),
        SizedBox(height: 12.h),
        HabitCreatorRoutineSection(
          initialHabit: initialHabit,
          customRoutineController: _customRoutineController,
        ),
        SizedBox(height: 12.h),
        HabitCreatorReminderSection(initialHabit: initialHabit),
        SizedBox(height: 10.h),
      ],
    );
  }
}
