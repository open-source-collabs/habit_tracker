import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/app.dart';
import 'package:habit_tracker/core/utils/date_format.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHabitStorage implements HabitStorage {
  FakeHabitStorage({this.stored});

  /// `null` simulates a fresh install.
  AppPayloadModel? stored;

  @override
  Future<AppPayloadModel?> loadPayload() async => stored;

  @override
  Future<void> savePayload(AppPayloadModel payload) async => stored = payload;

  @override
  Future<List<String>> listBackups() async => [];

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async => null;

  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'HabitTrackerApp renders home screen with active theme on mobile',
    (WidgetTester tester) async {
      // Mobile screen resolution: 390x844 (dp)
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitStorageProvider.overrideWithValue(_returningUser()),
          ],
          child: const HabitTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppDateFormat.longDay(DateTime.now())), findsOneWidget);
      expect(find.text('Themes'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
      expect(find.text('ACTIVE HABITS'), findsOneWidget);
      expect(find.text('PROGRESS OVERVIEW'), findsOneWidget);
      expect(find.text('New Habit'), findsOneWidget);
    },
  );

  testWidgets('HabitTrackerApp renders Bento multi-column layout on desktop', (
    WidgetTester tester,
  ) async {
    // Desktop screen resolution: 1200x900 (dp)
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [habitStorageProvider.overrideWithValue(_returningUser())],
        child: const HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppDateFormat.longDay(DateTime.now())), findsOneWidget);
    expect(find.text('Themes'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('ACTIVE HABITS'), findsOneWidget);
    expect(find.text('PROGRESS OVERVIEW'), findsOneWidget);
    // On desktop, the Bento Streak Champion tile is rendered
    expect(find.text('STREAK CHAMPION'), findsOneWidget);
  });

  testWidgets('a fresh install walks through onboarding into the dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = FakeHabitStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [habitStorageProvider.overrideWithValue(storage)],
        child: const HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Track Free'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hydration Target (3L)'));
    await tester.pump();
    await tester.tap(find.text('Add 1 & continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Track Free'), findsNothing);
    expect(find.text('ACTIVE HABITS'), findsOneWidget);
    final saved = storage.stored!.habits.single;
    expect(saved.title, 'Hydration Target (3L)');
    expect(saved.checkIns, isEmpty, reason: 'no fake history');
  });
}

/// Someone who has used the app before (data exists, even if empty).
FakeHabitStorage _returningUser() => FakeHabitStorage(
      stored: AppPayloadModel.initial(lastModifiedBy: 'test'),
    );
