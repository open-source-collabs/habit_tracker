import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable form state for the quick habit creation sheet.
@immutable
class AddHabitFormState {
  final String selectedRoutine;
  final int selectedAccent;
  final String? titleError;
  final int selectedFrequencyIndex; // 0: Daily, 1: Weekdays, 2: 3x/week, 3: 5x/week

  const AddHabitFormState({
    this.selectedRoutine = 'General',
    this.selectedAccent = 0,
    this.titleError,
    this.selectedFrequencyIndex = 0,
  });

  AddHabitFormState copyWith({
    String? selectedRoutine,
    int? selectedAccent,
    String? Function()? titleError,
    int? selectedFrequencyIndex,
  }) {
    return AddHabitFormState(
      selectedRoutine: selectedRoutine ?? this.selectedRoutine,
      selectedAccent: selectedAccent ?? this.selectedAccent,
      titleError: titleError != null ? titleError() : this.titleError,
      selectedFrequencyIndex:
          selectedFrequencyIndex ?? this.selectedFrequencyIndex,
    );
  }
}

/// Auto-disposing notifier managing quick habit form state and validation.
class AddHabitFormNotifier extends AutoDisposeNotifier<AddHabitFormState> {
  @override
  AddHabitFormState build() => const AddHabitFormState();

  void setRoutine(String routine) {
    state = state.copyWith(selectedRoutine: routine);
  }

  void setAccent(int accentIndex) {
    state = state.copyWith(selectedAccent: accentIndex);
  }

  void setFrequencyIndex(int index) {
    state = state.copyWith(selectedFrequencyIndex: index);
  }

  void setTitleError(String? error) {
    state = state.copyWith(titleError: () => error);
  }

  void clearError() {
    state = state.copyWith(titleError: () => null);
  }

  void reset() {
    state = const AddHabitFormState();
  }
}

/// Provider exposing the reactive quick habit form state.
final addHabitFormProvider =
    AutoDisposeNotifierProvider<AddHabitFormNotifier, AddHabitFormState>(
  AddHabitFormNotifier.new,
);
