import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/app.dart';
import 'package:habit_tracker/core/theme/app_contrast.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<WebHabitStorage> _storageWithHabits() async {
  final storage = WebHabitStorage(InMemoryWebStore());
  await storage.savePayload(
    AppPayloadModel.initial(lastModifiedBy: 'a11y').copyWith(
      habits: [
        HabitModel(
          id: 'read',
          title: 'Read 20 pages',
          frequency: const HabitFrequency.daily(),
          createdAt: DateTime(2026, 1, 1),
          reminderTime: '21:00',
        ),
        HabitModel(
          id: 'walk',
          title: 'Evening walk',
          frequency: const HabitFrequency.daily(),
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    ),
  );
  return storage;
}

Future<void> _pumpApp(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final storage = await tester.runAsync(_storageWithHabits);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [habitStorageProvider.overrideWithValue(storage!)],
      child: const HabitTrackerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('dashboard: tappable things are labelled', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('dashboard: tap targets meet the 48dp guideline',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('dashboard renders at 2x text size without overflow',
      (tester) async {
    await _pumpApp(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Read 20 pages'), findsOneWidget);
  });

  group('built-in themes have readable text', () {
    for (final preset in UserThemeModel.builtInPresets) {
      test(preset.name, () {
        expect(
          AppContrast.ratio(preset.textPrimary, preset.cardBg),
          greaterThanOrEqualTo(AppContrast.minTextRatio),
        );
        expect(
          AppContrast.ratio(preset.textPrimary, preset.scaffoldBg),
          greaterThanOrEqualTo(AppContrast.minTextRatio),
        );
      });
    }
  });

  test('AppContrast matches the WCAG reference values', () {
    expect(
      AppContrast.ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      AppContrast.ratio(const Color(0xFF777777), const Color(0xFFFFFFFF)),
      closeTo(4.48, 0.05),
    );
  });
}
