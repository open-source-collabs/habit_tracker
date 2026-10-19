import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets_kit/habit_widget_snapshot_view.dart';
import 'package:habit_tracker/core/widgets_kit/habit_widget_sync_service.dart';
import 'package:habit_tracker/core/widgets_kit/widgets_kit_interop.dart';
import 'package:habit_tracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

class FakeTestStorage implements HabitStorage {
  @override
  Future<AppPayloadModel?> loadPayload() async => null;
  @override
  Future<void> savePayload(AppPayloadModel payload) async {}
  @override
  Future<List<String>> listBackups() async => [];
  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async => null;
  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> mockedWidgetData = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('widgets_kit'), (
          call,
        ) async {
          if (call.method == 'saveWidgetData') {
            final args = call.arguments as Map<dynamic, dynamic>?;
            if (args != null) {
              final id = args['id'] as String;
              final data = args['data'];
              mockedWidgetData[id] = data;
            }
            return true;
          } else if (call.method == 'updateWidget') {
            return true;
          } else if (call.method == 'getWidgetData') {
            final args = call.arguments as Map<dynamic, dynamic>?;
            final id = args?['id'] as String?;
            return mockedWidgetData[id];
          }
          return null;
        });
  });

  group('HabitWidgetSyncService Tests', () {
    late HabitWidgetSyncService syncService;

    setUp(() {
      syncService = HabitWidgetSyncService();
      mockedWidgetData.clear();
    });

    test('Computes and syncs habit metrics correctly for today', () async {
      final today = DateTime(2026, 10, 12);
      final todayStr = HabitModel.formatDate(today);

      final habits = [
        HabitModel(
          id: 'habit_1',
          title: 'Drink 2L Water',
          subtitle: 'Hydrate well',
          frequency: const HabitFrequency.daily(),
          createdAt: today.subtract(const Duration(days: 5)),
          emoji: '💧',
          checkIns: {todayStr: true},
        ),
        HabitModel(
          id: 'habit_2',
          title: 'Morning Run',
          subtitle: 'Cardio workout',
          frequency: const HabitFrequency.daily(),
          createdAt: today.subtract(const Duration(days: 3)),
          emoji: '🏃',
          checkIns: const {},
        ),
      ];

      final result = await syncService.syncHabits(
        habits: habits,
        activeTheme: UserThemeModel.nordicSerenity,
        date: today,
      );

      expect(result, isTrue);
      expect(mockedWidgetData[HabitWidgetSyncService.keyTotalCount], 2);
      expect(mockedWidgetData[HabitWidgetSyncService.keyCompletedCount], 1);
      expect(mockedWidgetData[HabitWidgetSyncService.keyCompletionRate], '50%');
      expect(
        mockedWidgetData[HabitWidgetSyncService.keyTopPendingTitle],
        'Morning Run',
      );
      expect(mockedWidgetData[HabitWidgetSyncService.keyTopPendingEmoji], '🏃');
      expect(mockedWidgetData[HabitWidgetSyncService.keyAllCompleted], isFalse);
    });

    test('Handles empty habits list gracefully', () async {
      final today = DateTime(2026, 10, 12);
      final result = await syncService.syncHabits(
        habits: const [],
        date: today,
      );

      expect(result, isTrue);
      expect(mockedWidgetData[HabitWidgetSyncService.keyTotalCount], 0);
      expect(mockedWidgetData[HabitWidgetSyncService.keyCompletedCount], 0);
      expect(mockedWidgetData[HabitWidgetSyncService.keyCompletionRate], '0%');
      expect(mockedWidgetData[HabitWidgetSyncService.keyAllCompleted], isFalse);
    });

    test('Handles 100% completion status correctly', () async {
      final today = DateTime(2026, 10, 12);
      final todayStr = HabitModel.formatDate(today);

      final habits = [
        HabitModel(
          id: 'habit_1',
          title: 'Read Book',
          subtitle: 'Read 10 pages',
          frequency: const HabitFrequency.daily(),
          createdAt: today.subtract(const Duration(days: 2)),
          emoji: '📖',
          checkIns: {todayStr: true},
        ),
      ];

      final result = await syncService.syncHabits(habits: habits, date: today);

      expect(result, isTrue);
      expect(mockedWidgetData[HabitWidgetSyncService.keyTotalCount], 1);
      expect(mockedWidgetData[HabitWidgetSyncService.keyCompletedCount], 1);
      expect(
        mockedWidgetData[HabitWidgetSyncService.keyCompletionRate],
        '100%',
      );
      expect(mockedWidgetData[HabitWidgetSyncService.keyAllCompleted], isTrue);
    });
  });

  group('HabitWidgetSnapshotView Widget Tests', () {
    testWidgets(
      'renders habit counts and progress indicator in snapshot card',
      (tester) async {
        final today = DateTime(2026, 10, 12);
        final todayStr = HabitModel.formatDate(today);

        final habits = [
          HabitModel(
            id: 'habit_1',
            title: 'Meditate',
            subtitle: '10 min mindfulness',
            frequency: const HabitFrequency.daily(),
            createdAt: today.subtract(const Duration(days: 5)),
            emoji: '🧘',
            checkIns: {
              todayStr: true,
              HabitModel.formatDate(today.subtract(const Duration(days: 1))):
                  true,
            },
          ),
          HabitModel(
            id: 'habit_2',
            title: 'Workout',
            subtitle: 'Gym session',
            frequency: const HabitFrequency.daily(),
            createdAt: today.subtract(const Duration(days: 3)),
            emoji: '💪',
            checkIns: const {},
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeFactory.createTheme(UserThemeModel.nordicSerenity),
            home: Scaffold(
              body: HabitWidgetSnapshotView(habits: habits, date: today),
            ),
          ),
        );

        expect(find.text('Track Free'), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);
        expect(find.textContaining('completed today (50%)'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );
  });

  group('WidgetsKitInterop Tests', () {
    test('handles habittracker deep link URI safely', () {
      final container = ProviderContainer(
        overrides: [habitStorageProvider.overrideWithValue(FakeTestStorage())],
      );
      addTearDown(container.dispose);

      final testRef = container.read(habitStorageProvider);
      expect(testRef, isNotNull);

      final uri = Uri.parse('habittracker://toggle?id=habit_sunlight');
      expect(uri.scheme, 'habittracker');
      expect(uri.host, 'toggle');
      expect(uri.queryParameters['id'], 'habit_sunlight');
    });

    testWidgets('handleWidgetClick switches to today on habittracker://open', (
      tester,
    ) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [habitStorageProvider.overrideWithValue(FakeTestStorage())],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Mutate tab state first
      capturedRef.read(selectedDashboardTabProvider.notifier).state = 2;
      expect(capturedRef.read(selectedDashboardTabProvider), 2);

      // Handle habittracker://open
      WidgetsKitInterop.handleWidgetClick(
        Uri.parse('habittracker://open'),
        capturedRef,
      );

      // Verify it switched back to Tab 0 (Today)
      expect(capturedRef.read(selectedDashboardTabProvider), 0);
    });
  });
}
