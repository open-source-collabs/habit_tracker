import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auto-disposing notifier tracking open/close state of an AppDropdown.
class AppDropdownOpenNotifier extends Notifier<bool> {
  AppDropdownOpenNotifier(this.arg);

  final String arg;

  @override
  bool build() => false;

  void setOpen(bool isOpen) {
    state = isOpen;
  }
}

/// Provider exposing whether an AppDropdown instance's selection sheet is open.
final appDropdownOpenProvider =
    NotifierProvider.autoDispose.family<AppDropdownOpenNotifier, bool, String>(
  AppDropdownOpenNotifier.new,
);
