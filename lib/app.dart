import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/routes/routes.dart';
import 'core/widgets_kit/habit_widget_sync_service.dart';
import 'core/widgets_kit/widgets_kit_interop.dart';
import 'features/habits/presentation/providers/habit_provider.dart';
import 'features/themes/presentation/providers/theme_provider.dart';

/// Root application widget configuring screen utilities, dynamic theme switching,
/// named route navigation, and the responsive Bento dashboard.
class HabitTrackerApp extends ConsumerStatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  ConsumerState<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends ConsumerState<HabitTrackerApp> {
  @override
  void initState() {
    super.initState();
    // Subscribe once for the app's lifetime, not on every rebuild.
    WidgetsKitInterop.initialize(ref);
  }

  @override
  void dispose() {
    WidgetsKitInterop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    // Sync home screen widget when active theme changes
    ref.listen(themeProvider, (prev, next) {
      if (prev?.activeThemeId != next.activeThemeId) {
        final habits = ref.read(habitListProvider).valueOrNull ?? [];
        ref.read(habitWidgetSyncServiceProvider).syncHabits(
          habits: habits,
          activeTheme: next.activeTheme,
        );
      }
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Habit Tracker',
          debugShowCheckedModeBanner: false,
          theme: themeState.themeData,
          navigatorKey: AppRouter.navigatorKey,
          initialRoute: AppRoutes.dashboard,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onUnknownRoute: AppRouter.onUnknownRoute,
        );
      },
    );
  }
}
