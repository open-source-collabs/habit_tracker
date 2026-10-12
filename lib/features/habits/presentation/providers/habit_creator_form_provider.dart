import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/habit_model.dart';
import '../widgets/habit_extensions.dart';

/// Immutable form state for the full Habit Creator Studio.
@immutable
class HabitCreatorFormState {
  final String? titleError;
  final String selectedRoutine;
  final bool isCreatingCustomRoutine;
  final int selectedAccentIndex;
  final Color? customColor;
  final bool isEmojiSelected;
  final String selectedEmoji;
  final String? selectedIconCode;
  final HabitFrequencyType frequencyType;
  final List<int> selectedDaysOfWeek;
  final int targetTimesPerWeek;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;

  const HabitCreatorFormState({
    this.titleError,
    this.selectedRoutine = 'Morning Routine',
    this.isCreatingCustomRoutine = false,
    this.selectedAccentIndex = 0,
    this.customColor,
    this.isEmojiSelected = true,
    this.selectedEmoji = '☀️',
    this.selectedIconCode,
    this.frequencyType = HabitFrequencyType.daily,
    this.selectedDaysOfWeek = const [1, 2, 3, 4, 5],
    this.targetTimesPerWeek = 3,
    this.reminderEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
  });

  HabitCreatorFormState copyWith({
    String? Function()? titleError,
    String? selectedRoutine,
    bool? isCreatingCustomRoutine,
    int? selectedAccentIndex,
    Color? Function()? customColor,
    bool? isEmojiSelected,
    String? selectedEmoji,
    String? Function()? selectedIconCode,
    HabitFrequencyType? frequencyType,
    List<int>? selectedDaysOfWeek,
    int? targetTimesPerWeek,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
  }) {
    return HabitCreatorFormState(
      titleError: titleError != null ? titleError() : this.titleError,
      selectedRoutine: selectedRoutine ?? this.selectedRoutine,
      isCreatingCustomRoutine:
          isCreatingCustomRoutine ?? this.isCreatingCustomRoutine,
      selectedAccentIndex: selectedAccentIndex ?? this.selectedAccentIndex,
      customColor: customColor != null ? customColor() : this.customColor,
      isEmojiSelected: isEmojiSelected ?? this.isEmojiSelected,
      selectedEmoji: selectedEmoji ?? this.selectedEmoji,
      selectedIconCode:
          selectedIconCode != null ? selectedIconCode() : this.selectedIconCode,
      frequencyType: frequencyType ?? this.frequencyType,
      selectedDaysOfWeek: selectedDaysOfWeek ?? this.selectedDaysOfWeek,
      targetTimesPerWeek: targetTimesPerWeek ?? this.targetTimesPerWeek,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

/// Auto-disposing family notifier managing comprehensive habit creation studio form state.
class HabitCreatorFormNotifier
    extends AutoDisposeFamilyNotifier<HabitCreatorFormState, HabitModel?> {
  @override
  HabitCreatorFormState build(HabitModel? initialHabit) {
    if (initialHabit == null) {
      return const HabitCreatorFormState();
    }

    final initialColor = initialHabit.customColorValue != null
        ? Color(initialHabit.customColorValue!)
        : null;

    final isIcon = initialHabit.iconCode != null &&
        HabitIconRegistry.icons.containsKey(initialHabit.iconCode);

    TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);
    bool reminderEnabled = false;
    if (initialHabit.reminderTime != null) {
      reminderEnabled = true;
      final parts = initialHabit.reminderTime!.split(':');
      if (parts.length == 2) {
        reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return HabitCreatorFormState(
      selectedRoutine: initialHabit.routineGroup,
      selectedAccentIndex: initialHabit.accentIndex,
      customColor: initialColor,
      isEmojiSelected: !isIcon,
      selectedEmoji: initialHabit.emoji ?? '☀️',
      selectedIconCode: initialHabit.iconCode,
      frequencyType: initialHabit.frequency.type,
      selectedDaysOfWeek: initialHabit.frequency.daysOfWeek.isNotEmpty
          ? List.from(initialHabit.frequency.daysOfWeek)
          : const [1, 2, 3, 4, 5],
      targetTimesPerWeek: initialHabit.frequency.targetTimesPerWeek,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
    );
  }

  void setTitleError(String? error) {
    state = state.copyWith(titleError: () => error);
  }

  void clearTitleError() {
    state = state.copyWith(titleError: () => null);
  }

  void setRoutine(String routine) {
    state = state.copyWith(selectedRoutine: routine);
  }

  void toggleCustomRoutine() {
    state = state.copyWith(
      isCreatingCustomRoutine: !state.isCreatingCustomRoutine,
    );
  }

  void setAccentIndex(int index) {
    state = state.copyWith(
      selectedAccentIndex: index,
      customColor: () => null,
    );
  }

  void setCustomColor(Color color) {
    state = state.copyWith(
      customColor: () => color,
      selectedAccentIndex: -1,
    );
  }

  void setIsEmojiSelected(bool isEmoji) {
    state = state.copyWith(isEmojiSelected: isEmoji);
  }

  void selectEmoji(String emoji) {
    state = state.copyWith(
      selectedEmoji: emoji,
      selectedIconCode: () => null,
      isEmojiSelected: true,
    );
  }

  void selectIcon(String iconCode) {
    state = state.copyWith(
      selectedIconCode: () => iconCode,
      isEmojiSelected: false,
    );
  }

  void setFrequencyType(HabitFrequencyType type) {
    state = state.copyWith(frequencyType: type);
  }

  void setSelectedDaysOfWeek(List<int> days) {
    state = state.copyWith(selectedDaysOfWeek: List.from(days));
  }

  void toggleDayOfWeek(int day) {
    final current = List<int>.from(state.selectedDaysOfWeek);
    if (current.contains(day)) {
      if (current.length > 1) {
        current.remove(day);
      }
    } else {
      current.add(day);
      current.sort();
    }
    state = state.copyWith(selectedDaysOfWeek: current);
  }

  void incrementTargetTimesPerWeek() {
    if (state.targetTimesPerWeek < 7) {
      state = state.copyWith(targetTimesPerWeek: state.targetTimesPerWeek + 1);
    }
  }

  void decrementTargetTimesPerWeek() {
    if (state.targetTimesPerWeek > 1) {
      state = state.copyWith(targetTimesPerWeek: state.targetTimesPerWeek - 1);
    }
  }

  void setReminderEnabled(bool enabled) {
    state = state.copyWith(reminderEnabled: enabled);
  }

  void setReminderTime(TimeOfDay time) {
    state = state.copyWith(reminderTime: time);
  }
}

/// Family provider exposing the comprehensive habit creator studio form state.
final habitCreatorFormProvider = AutoDisposeNotifierProvider.family<
    HabitCreatorFormNotifier, HabitCreatorFormState, HabitModel?>(
  HabitCreatorFormNotifier.new,
);
