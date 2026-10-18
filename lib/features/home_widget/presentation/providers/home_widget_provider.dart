import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/presentation/providers/habit_provider.dart';
import '../../data/home_widget_service.dart';

/// What the app knows about the home-screen widget right now.
@immutable
class HomeWidgetStatus {
  /// The platform has the widget (Android).
  final bool available;

  /// The launcher can show the system "Add to home screen" dialog.
  final bool canPin;

  /// Copies currently on the home screen.
  final int installed;

  const HomeWidgetStatus({
    required this.available,
    required this.canPin,
    required this.installed,
  });

  static const HomeWidgetStatus unavailable =
      HomeWidgetStatus(available: false, canPin: false, installed: 0);

  bool get isInstalled => installed > 0;
}

/// Current widget status. Invalidate it after a pin request or when the app
/// resumes (the user may have added or removed the widget meanwhile).
final homeWidgetStatusProvider =
    FutureProvider.autoDispose<HomeWidgetStatus>((ref) async {
  final service = ref.watch(homeWidgetServiceProvider);
  if (!service.isAvailable) return HomeWidgetStatus.unavailable;
  final results = await Future.wait([
    service.canRequestPin(),
    service.installedCount(),
  ]);
  return HomeWidgetStatus(
    available: true,
    canPin: results[0] as bool,
    installed: results[1] as int,
  );
});

/// Whether the one-time dashboard tip was dismissed (or acted on).
final homeWidgetTipDismissedProvider =
    AsyncNotifierProvider<HomeWidgetTipDismissed, bool>(
  HomeWidgetTipDismissed.new,
);

class HomeWidgetTipDismissed extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(homeWidgetServiceProvider).isTipDismissed();

  Future<void> dismiss() async {
    state = const AsyncData(true);
    await ref.read(homeWidgetServiceProvider).dismissTip();
  }
}

/// The dashboard tip shows once the user has a routine worth glancing at:
/// widget available and addable, at least two active habits, none placed
/// yet, and the tip not dismissed before.
final showHomeWidgetTipProvider = Provider.autoDispose<bool>((ref) {
  final status = ref.watch(homeWidgetStatusProvider).valueOrNull;
  final dismissed = ref.watch(homeWidgetTipDismissedProvider).valueOrNull;
  if (status == null || dismissed == null || dismissed) return false;
  if (!status.available || !status.canPin || status.isInstalled) return false;
  final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
  return habits.where((h) => !h.isArchived).length >= 2;
});
