import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auto-disposing notifier tracking open/close state of an AppDropdown.
class AppDropdownOpenNotifier extends AutoDisposeFamilyNotifier<bool, String> {
  @override
  bool build(String arg) => false;

  void setOpen(bool isOpen) {
    state = isOpen;
  }
}

/// Provider exposing whether an AppDropdown instance's selection sheet is open.
final appDropdownOpenProvider =
    AutoDisposeNotifierProviderFamily<AppDropdownOpenNotifier, bool, String>(
  AppDropdownOpenNotifier.new,
);
