import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:habit_tracker/presentation/widgets/data_portability_dialog.dart';

class _FakeHabitStorage implements HabitStorage {
  AppPayloadModel? storedPayload;

  @override
  Future<AppPayloadModel?> loadPayload() async => storedPayload;

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    storedPayload = payload;
  }

  @override
  Future<List<String>> listBackups() async => [];

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async =>
      storedPayload;

  @override
  Future<void> clear() async {
    storedPayload = null;
  }
}

Widget _buildTestWidget(Widget child, {required _FakeHabitStorage storage}) {
  final themeData = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

  return ProviderScope(
    overrides: [habitStorageProvider.overrideWithValue(storage)],
    child: AppScreenUtilInit(
      builder: (context) => MaterialApp(
        theme: themeData,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHabitStorage fakeStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeStorage = _FakeHabitStorage();
  });

  group('DataPortabilityDialog Widget Tests', () {
    testWidgets('renders all export, import, and cloud sync controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestWidget(const DataPortabilityDialog(), storage: fakeStorage),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Portability & Sync'), findsOneWidget);
      expect(find.text('1-TAP DATABASE EXPORT'), findsOneWidget);
      expect(find.text('Copy Database JSON to Clipboard'), findsOneWidget);
      expect(find.text('1-TAP DATABASE IMPORT / RESTORE'), findsOneWidget);
      expect(find.text('Paste JSON from Clipboard'), findsOneWidget);
      expect(find.text('Cloud Sync (iCloud & Google Drive)'), findsNothing,
          reason: 'cloud sync moved to the Sync tab');
    });

    testWidgets(
      'export button copies JSON payload to clipboard and displays confirmation',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        String? clipboardContents;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (
              methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                clipboardContents =
                    (methodCall.arguments as Map)['text'] as String?;
                return null;
              }
              return null;
            });

        await tester.pumpWidget(
          _buildTestWidget(const DataPortabilityDialog(), storage: fakeStorage),
        );
        await tester.pumpAndSettle();

        // Tap Copy button
        await tester.tap(find.text('Copy Database JSON to Clipboard'));
        await tester.pumpAndSettle();

        expect(clipboardContents, isNotNull);
        final decoded = jsonDecode(clipboardContents!) as Map<String, dynamic>;
        expect(decoded.containsKey('habits'), isTrue);
        expect(decoded.containsKey('userThemes'), isTrue);

        expect(find.textContaining('Database JSON copied!'), findsOneWidget);
      },
    );

    testWidgets('validates raw JSON text and allows zero-loss merge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestWidget(const DataPortabilityDialog(), storage: fakeStorage),
      );
      await tester.pumpAndSettle();

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'remote_device',
        lastModifiedAt: DateTime(2026, 10, 12, 12, 0),
        activeThemeId: UserThemeModel.nordicSerenity.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [
          HabitModel(
            id: 'habit_remote_imported',
            title: 'Imported Remote Habit',
            frequency: const HabitFrequency.daily(),
            createdAt: DateTime(2026, 10, 1),
            checkIns: const {'2026-10-12': true},
          ),
        ],
      );

      final rawJson = incomingPayload.toRawJson();

      // Enter into TextField
      final textField = find.byType(TextField);
      await tester.enterText(textField, rawJson);
      await tester.pumpAndSettle();

      expect(find.text('VALID DATABASE PAYLOAD'), findsOneWidget);
      expect(find.text('Merge (Zero Loss)'), findsOneWidget);
      expect(find.text('Overwrite All'), findsOneWidget);

      // Tap Merge
      await tester.ensureVisible(find.text('Merge (Zero Loss)'));
      await tester.tap(find.text('Merge (Zero Loss)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Saved payload contains the imported habit
      expect(fakeStorage.storedPayload, isNotNull);
      final savedHabits = fakeStorage.storedPayload!.habits;
      expect(savedHabits.any((h) => h.id == 'habit_remote_imported'), isTrue);
    });

    testWidgets('displays error message for invalid JSON', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestWidget(const DataPortabilityDialog(), storage: fakeStorage),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '{ invalid_json: 123');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Invalid JSON database format'),
        findsOneWidget,
      );
    });
  });
}
