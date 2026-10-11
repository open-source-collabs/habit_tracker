import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/themes/presentation/providers/theme_provider.dart';

/// Root application widget configuring screen utilities, dynamic theme switching,
/// and the responsive Bento dashboard.
class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Habit Tracker',
          debugShowCheckedModeBanner: false,
          theme: themeState.themeData,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
