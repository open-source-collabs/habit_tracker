import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../habits/presentation/providers/habit_provider.dart';

bool _isShowing = false;

/// Opens onboarding when nothing has ever been saved on this device — a
/// fresh install, or right after "Delete all data". Unreadable data is not
/// a first run, so onboarding never covers the recovery screen.
Future<void> showOnboardingIfNeeded(WidgetRef ref) async {
  if (_isShowing) return;
  try {
    await ref.read(habitListProvider.future);
  } catch (_) {
    return;
  }
  if (!ref.read(appDataRepositoryProvider).hasNeverSaved) return;

  final navigator = AppRouter.navigatorKey.currentState;
  if (navigator == null) return;
  _isShowing = true;
  try {
    navigator.popUntil((route) => route.isFirst);
    await navigator.pushNamed<void>(AppRoutes.onboarding);
  } finally {
    _isShowing = false;
  }
}
