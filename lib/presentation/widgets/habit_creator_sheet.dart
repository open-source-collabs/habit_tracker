import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_font_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/widgets.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/habits/presentation/providers/habit_creator_form_provider.dart';
import '../../features/habits/presentation/providers/habit_provider.dart';
import '../../features/habits/presentation/widgets/habit_extensions.dart';
import '../../features/themes/presentation/providers/theme_provider.dart';
import '../../features/themes/presentation/widgets/color_picker_dialog.dart';

/// Interactive Habit Creation Studio modal sheet and dialog.
/// Supports active theme font styling, dynamic theme palette or custom Hex/HSL color picking,
/// tabbed Material icon and emoji selectors, flexible frequency configuration,
/// dynamic routine groupings, and offline native notification alarm scheduling.
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

class _HabitCreatorSheetState extends ConsumerState<HabitCreatorSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _customRoutineController;
  late final TextEditingController _customEmojiController;

  late TabController _iconTabController;

  static const List<String> _curatedEmojis = [
    '☀️',
    '💧',
    '🏃',
    '🧘',
    '⚡',
    '📖',
    '💪',
    '🌙',
    '🥑',
    '🎯',
    '⏰',
    '🧠',
    '🎨',
    '🌿',
    '☕',
    '🍎',
    '🏆',
    '🔥',
    '🚀',
    '📚',
    '🚴',
    '🏊',
    '✍️',
    '🎵',
  ];

  static const List<String> _defaultRoutines = [
    'Morning Routine',
    'Health',
    'Focus',
    'Evening Calm',
    'Fitness',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;

    _titleController = TextEditingController(text: initial?.title ?? '');
    _subtitleController = TextEditingController(text: initial?.subtitle ?? '');
    _customRoutineController = TextEditingController();
    _customEmojiController = TextEditingController();

    final isIcon =
        initial?.iconCode != null &&
        HabitIconRegistry.icons.containsKey(initial?.iconCode);

    _iconTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isIcon ? 1 : 0,
    );

    _iconTabController.addListener(() {
      if (_iconTabController.indexIsChanging) {
        AppHaptics.selectionClick();
        ref
            .read(habitCreatorFormProvider(widget.initialHabit).notifier)
            .setIsEmojiSelected(_iconTabController.index == 0);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _customRoutineController.dispose();
    _customEmojiController.dispose();
    _iconTabController.dispose();
    super.dispose();
  }

  Color _getActiveSelectedColor(BuildContext context) {
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    if (formState.customColor != null) return formState.customColor!;
    final palette = context.accentPalette;
    if (palette.isNotEmpty && formState.selectedAccentIndex >= 0) {
      return palette[formState.selectedAccentIndex % palette.length];
    }
    return context.primaryAccent;
  }

  HabitFrequency _buildFrequency() {
    final formState = ref.read(habitCreatorFormProvider(widget.initialHabit));
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
      frequency: _buildFrequency(),
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
    if (widget.initialHabit != null) {
      ref.read(habitListProvider.notifier).updateHabit(habit);
    } else {
      ref.read(habitListProvider.notifier).createHabit(habit);
    }

    AppHaptics.heavyImpact();
    Navigator.of(context).pop(habit);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogLayout(context);
    }
    return _buildBottomSheetLayout(context);
  }

  Widget _buildBottomSheetLayout(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        border: Border(
          top: BorderSide(
            color: context.cardBorderColor,
            width: AppSizes.borderWidth,
          ),
          left: BorderSide(
            color: context.cardBorderColor,
            width: AppSizes.borderWidth,
          ),
          right: BorderSide(
            color: context.cardBorderColor,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8.h, bottom: 6.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.textMutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildFormContent(context),
            ),
          ),
          _buildFooterButtons(context),
        ],
      ),
    );
  }

  Widget _buildDialogLayout(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardBackgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildFormContent(context),
              ),
            ),
            _buildFooterButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final activeTheme = ref.watch(themeProvider).activeTheme;
    final activeColor = _getActiveSelectedColor(context);
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 14.w, 10.h),
      child: Row(
        children: [
          // Visual Avatar Preview
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: AppColors.pastelSurface(
                activeColor,
                isDark: context.isDarkMode,
                opacity: 0.22,
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Center(
              child: formState.isEmojiSelected
                  ? Text(
                      formState.selectedEmoji,
                      style: TextStyle(fontSize: AppFontSizes.headlineLarge),
                    )
                  : Icon(
                      HabitIconRegistry.getIcon(formState.selectedIconCode) ??
                          Icons.star_rounded,
                      color: activeColor,
                      size: 22.r,
                    ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialHabit != null ? 'Edit Habit' : 'New Habit',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontFamily: activeTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Configure identity, frequency & alarms',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: context.textMutedColor,
              size: AppIconSizes.lg,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final activeTheme = ref.watch(themeProvider).activeTheme;
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Habit Title with active theme font
        AppTextField(
          controller: _titleController,
          labelText: 'HABIT TITLE',
          hintText: 'e.g. 20 Minutes Deep Work',
          autofocus: widget.initialHabit == null,
          showClearButton: true,
          errorText: formState.titleError,
          style: context.textTheme.titleSmall?.copyWith(
            fontFamily: activeTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (val) {
            if (formState.titleError != null && val.trim().isNotEmpty) {
              ref
                  .read(habitCreatorFormProvider(widget.initialHabit).notifier)
                  .clearTitleError();
            }
          },
        ),
        SizedBox(height: 10.h),

        // Subtitle / Notes
        AppTextField(
          controller: _subtitleController,
          labelText: 'SUBTITLE / NOTES',
          hintText: 'e.g. Turn off notifications & focus',
          showClearButton: true,
        ),
        SizedBox(height: 12.h),

        // Section: Color Picker
        _buildColorPickerSection(context),
        SizedBox(height: 12.h),

        // Section: Icon & Emoji Picker
        _buildIconAndEmojiSection(context),
        SizedBox(height: 12.h),

        // Section: Frequency Configurator
        _buildFrequencySection(context),
        SizedBox(height: 12.h),

        // Section: Routine & Grouping
        _buildRoutineSection(context),
        SizedBox(height: 12.h),

        // Section: Reminder Alarm
        _buildReminderSection(context),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildColorPickerSection(BuildContext context) {
    final palette = context.accentPalette;
    final activeColor = _getActiveSelectedColor(context);
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );

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
            // Theme palette swatches
            ...List.generate(palette.length, (idx) {
              final color = palette[idx];
              final isSelected =
                  formState.customColor == null &&
                  formState.selectedAccentIndex == idx;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  formNotifier.setAccentIndex(idx);
                },
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
                            color:
                                ThemeData.estimateBrightnessForColor(color) ==
                                    Brightness.dark
                                ? AppColors.white
                                : AppColors.obsidianTwilight,
                          ),
                        )
                      : null,
                ),
              );
            }),

            // Custom Hex/HSL Picker button
            GestureDetector(
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
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: formState.customColor != null
                      ? formState.customColor!.withValues(alpha: 0.18)
                      : context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: formState.customColor ?? context.cardBorderColor,
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
                        gradient: const SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                        border: Border.all(
                          color: context.cardBorderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      formState.customColor != null
                          ? '#${AppColors.colorToHex(formState.customColor!).toUpperCase()}'
                          : 'Custom',
                      style: context.textTheme.labelSmall?.copyWith(
                        color:
                            formState.customColor ?? context.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconAndEmojiSection(BuildContext context) {
    final activeColor = _getActiveSelectedColor(context);
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ICON & EMOJI GLYPH', style: AppTextStyles.labelSmall(context)),
        SizedBox(height: 10.h),
        // Tab Header
        Container(
          height: 38.w,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? context.surfaceElevatedColor
                : context.cardBorderColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.cardBorderColor, width: 1.0),
          ),
          child: TabBar(
            controller: _iconTabController,
            indicator: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: context.cardBorderColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            labelColor: context.textPrimaryColor,
            unselectedLabelColor: context.textMutedColor,
            labelStyle: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.transparent,
            tabs: const [
              Tab(text: 'Emoji Glyph'),
              Tab(text: 'Material Icon'),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Tab Content
        SizedBox(
          height: 130.w,
          child: TabBarView(
            controller: _iconTabController,
            children: [
              // Emoji Tab
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _curatedEmojis.map((emoji) {
                          final isSelected =
                              formState.isEmojiSelected &&
                              formState.selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () {
                              AppHaptics.selectionClick();
                              formNotifier.selectEmoji(emoji);
                            },
                            child: Container(
                              width: 36.r,
                              height: 36.r,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.22)
                                    : context.cardBackgroundColor,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : context.cardBorderColor,
                                  width: isSelected
                                      ? AppSizes.borderWidthFocused
                                      : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: TextStyle(
                                    fontSize: AppFontSizes.titleLarge,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 34.w,
                          child: TextField(
                            controller: _customEmojiController,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.textPrimaryColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type any custom emoji...',
                              hintStyle: context.textTheme.bodySmall?.copyWith(
                                color: context.textMutedColor,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              filled: true,
                              fillColor: context.cardBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                borderSide: BorderSide(
                                  color: context.cardBorderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                borderSide: BorderSide(
                                  color: context.cardBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                borderSide: BorderSide(color: activeColor),
                              ),
                            ),
                            onChanged: (val) {
                              final text = val.trim();
                              if (text.isNotEmpty) {
                                formNotifier.selectEmoji(text);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Material Icon Tab
              SingleChildScrollView(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: HabitIconRegistry.icons.entries.map((entry) {
                    final code = entry.key;
                    final iconData = entry.value;
                    final isSelected =
                        !formState.isEmojiSelected &&
                        formState.selectedIconCode == code;
                    return GestureDetector(
                      onTap: () {
                        AppHaptics.selectionClick();
                        formNotifier.selectIcon(code);
                      },
                      child: Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.22)
                              : context.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isSelected
                                ? activeColor
                                : context.cardBorderColor,
                            width: isSelected
                                ? AppSizes.borderWidthFocused
                                : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            iconData,
                            size: 19.r,
                            color: isSelected
                                ? activeColor
                                : context.textPrimaryColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(BuildContext context) {
    final activeColor = _getActiveSelectedColor(context);
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUENCY CONFIGURATOR',
          style: AppTextStyles.labelSmall(context),
        ),
        SizedBox(height: 10.h),
        // Mode Selector: Every Day | Specific Days | Times per Week
        Row(
          children: [
            Expanded(
              child: _buildFrequencyModePill(
                title: 'Every Day',
                type: HabitFrequencyType.daily,
                activeColor: activeColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildFrequencyModePill(
                title: 'Specific Days',
                type: HabitFrequencyType.specificWeekdays,
                activeColor: activeColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildFrequencyModePill(
                title: 'Times / Week',
                type: HabitFrequencyType.timesPerWeek,
                activeColor: activeColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Sub-configurator depending on type
        if (formState.frequencyType == HabitFrequencyType.specificWeekdays) ...[
          _buildSpecificWeekdaysSelector(context, activeColor),
        ] else if (formState.frequencyType ==
            HabitFrequencyType.timesPerWeek) ...[
          _buildTimesPerWeekStepper(context, activeColor),
        ],
      ],
    );
  }

  Widget _buildFrequencyModePill({
    required String title,
    required HabitFrequencyType type,
    required Color activeColor,
  }) {
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );
    final isSelected = formState.frequencyType == type;

    return GestureDetector(
      onTap: () {
        AppHaptics.selectionClick();
        formNotifier.setFrequencyType(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pastelSurface(
                  activeColor,
                  isDark: context.isDarkMode,
                  opacity: 0.22,
                )
              : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? activeColor : context.cardBorderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                title,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : context.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificWeekdaysSelector(
    BuildContext context,
    Color activeColor,
  ) {
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );
    const dayLabels = [
      {'val': 1, 'name': 'Mon'},
      {'val': 2, 'name': 'Tue'},
      {'val': 3, 'name': 'Wed'},
      {'val': 4, 'name': 'Thu'},
      {'val': 5, 'name': 'Fri'},
      {'val': 6, 'name': 'Sat'},
      {'val': 7, 'name': 'Sun'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select active days:',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textMutedColor,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    formNotifier.setSelectedDaysOfWeek([1, 2, 3, 4, 5]);
                  },
                  child: Text(
                    'Weekdays',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: activeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    formNotifier.setSelectedDaysOfWeek([6, 7]);
                  },
                  child: Text(
                    'Weekends',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: activeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: dayLabels.map((d) {
            final val = d['val'] as int;
            final name = d['name'] as String;
            final isDaySelected = formState.selectedDaysOfWeek.contains(val);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    formNotifier.toggleDayOfWeek(val);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDaySelected
                          ? activeColor
                          : context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDaySelected
                            ? activeColor
                            : context.cardBorderColor,
                        width: AppSizes.borderWidth,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDaySelected
                              ? (ThemeData.estimateBrightnessForColor(
                                          activeColor,
                                        ) ==
                                        Brightness.dark
                                    ? AppColors.white
                                    : AppColors.obsidianTwilight)
                              : context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimesPerWeekStepper(BuildContext context, Color activeColor) {
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Target frequency:',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: formState.targetTimesPerWeek > 1
                    ? () {
                        AppHaptics.selectionClick();
                        formNotifier.decrementTargetTimesPerWeek();
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: activeColor,
                iconSize: AppIconSizes.xl,
              ),
              Container(
                constraints: BoxConstraints(minWidth: 44.w),
                child: Center(
                  child: Text(
                    '${formState.targetTimesPerWeek} × / wk',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: formState.targetTimesPerWeek < 6
                    ? () {
                        AppHaptics.selectionClick();
                        formNotifier.incrementTargetTimesPerWeek();
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: activeColor,
                iconSize: AppIconSizes.xl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(BuildContext context) {
    final activeColor = _getActiveSelectedColor(context);
    final userGroups = ref.watch(routineGroupsProvider);
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );
    final allGroups = <String>{
      ..._defaultRoutines,
      ...userGroups,
    }.where((g) => g != 'All').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GROUP / ROUTINE', style: AppTextStyles.labelSmall(context)),
            GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                formNotifier.toggleCustomRoutine();
              },
              child: Text(
                formState.isCreatingCustomRoutine
                    ? 'Choose from list'
                    : '+ Custom Group',
                style: context.textTheme.labelSmall?.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (formState.isCreatingCustomRoutine) ...[
          AppTextField(
            controller: _customRoutineController,
            hintText: 'e.g. Evening Wind Down',
            labelText: 'CUSTOM ROUTINE NAME',
            autofocus: true,
          ),
        ] else ...[
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: allGroups.map((group) {
              final isSelected = formState.selectedRoutine == group;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  formNotifier.setRoutine(group);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.pastelSurface(
                            activeColor,
                            isDark: context.isDarkMode,
                            opacity: 0.22,
                          )
                        : context.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? activeColor : context.cardBorderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    group,
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? activeColor
                          : context.textPrimaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSection(BuildContext context) {
    final activeColor = _getActiveSelectedColor(context);
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: AppIconSizes.lg,
                    color: formState.reminderEnabled
                        ? activeColor
                        : context.textMutedColor,
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder Alarm',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Native offline notifications',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: formState.reminderEnabled,
                activeTrackColor: activeColor,
                onChanged: (val) {
                  AppHaptics.selectionClick();
                  formNotifier.setReminderEnabled(val);
                  // Ask at the moment it matters, not on first launch.
                  if (val) {
                    ref.read(notificationServiceProvider).requestPermission();
                  }
                },
              ),
            ],
          ),
          if (formState.reminderEnabled) ...[
            Divider(color: context.cardBorderColor, height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily alarm time:',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    AppHaptics.mediumImpact();
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: formState.reminderTime,
                      builder: (ctx, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: activeColor,
                              onPrimary: AppColors.white,
                              surface: context.cardBackgroundColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      formNotifier.setReminderTime(picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pastelSurface(
                        activeColor,
                        isDark: context.isDarkMode,
                        opacity: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: activeColor,
                        width: AppSizes.borderWidth,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: AppIconSizes.sm,
                          color: activeColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          formState.reminderTime.format(context),
                          style: context.textTheme.labelLarge?.copyWith(
                            color: activeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        border: Border(
          top: BorderSide(color: context.cardBorderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.md,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: AppButton(
              text: widget.initialHabit != null
                  ? 'Update Habit'
                  : 'Create Habit',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.md,
              glow: true,
              leadingIcon: const Icon(Icons.check_rounded),
              onPressed: _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
