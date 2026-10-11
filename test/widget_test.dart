import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HabitTrackerApp renders home screen with active theme on mobile',
      (WidgetTester tester) async {
    // Mobile screen resolution: 390x844 (dp)
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dusk & Dawn Tracker'), findsOneWidget);
    expect(find.text('Theme Studio'), findsOneWidget);
    expect(find.text('ACTIVE HABITS'), findsOneWidget);
    expect(find.text('PROGRESS OVERVIEW'), findsOneWidget);
    expect(find.text('New Habit'), findsOneWidget);
  });

  testWidgets('HabitTrackerApp renders Bento multi-column layout on desktop',
      (WidgetTester tester) async {
    // Desktop screen resolution: 1200x900 (dp)
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dusk & Dawn Tracker'), findsOneWidget);
    expect(find.text('Theme Studio'), findsOneWidget);
    expect(find.text('ACTIVE HABITS'), findsOneWidget);
    expect(find.text('PROGRESS OVERVIEW'), findsOneWidget);
    // On desktop, the Bento Streak Champion tile is rendered
    expect(find.text('STREAK CHAMPION'), findsOneWidget);
  });
}
