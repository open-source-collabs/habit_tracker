import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI state for an AppTextField instance (focus, obscureText, and clear button visibility).
class AppTextFieldUiState {
  final bool isFocused;
  final bool obscureText;
  final bool showClear;

  const AppTextFieldUiState({
    this.isFocused = false,
    this.obscureText = false,
    this.showClear = false,
  });

  AppTextFieldUiState copyWith({
    bool? isFocused,
    bool? obscureText,
    bool? showClear,
  }) {
    return AppTextFieldUiState(
      isFocused: isFocused ?? this.isFocused,
      obscureText: obscureText ?? this.obscureText,
      showClear: showClear ?? this.showClear,
    );
  }
}

/// Parameters configuring the initial state of an AppTextField instance.
class AppTextFieldParams {
  final String id;
  final bool initialObscure;
  final bool initialShowClear;

  const AppTextFieldParams({
    required this.id,
    required this.initialObscure,
    required this.initialShowClear,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTextFieldParams &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Auto-disposing notifier orchestrating focus, password toggle, and clear button state.
class AppTextFieldUiNotifier
    extends AutoDisposeFamilyNotifier<AppTextFieldUiState, AppTextFieldParams> {
  @override
  AppTextFieldUiState build(AppTextFieldParams arg) {
    return AppTextFieldUiState(
      obscureText: arg.initialObscure,
      showClear: arg.initialShowClear,
    );
  }

  void setFocused(bool isFocused) {
    state = state.copyWith(isFocused: isFocused);
  }

  void setShowClear(bool showClear) {
    state = state.copyWith(showClear: showClear);
  }

  void toggleObscure() {
    state = state.copyWith(obscureText: !state.obscureText);
  }

  void setObscure(bool obscure) {
    state = state.copyWith(obscureText: obscure);
  }
}

/// Provider exposing the reactive UI state for an AppTextField instance.
final appTextFieldUiProvider = AutoDisposeNotifierProviderFamily<
    AppTextFieldUiNotifier, AppTextFieldUiState, AppTextFieldParams>(
  AppTextFieldUiNotifier.new,
);
