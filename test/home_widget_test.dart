import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:habit_tracker/core/widgets_kit/habit_widget_sync_service.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/home_widget/data/home_widget_service.dart';
import 'package:habit_tracker/features/home_widget/presentation/providers/home_widget_provider.dart';
import 'package:habit_tracker/features/home_widget/presentation/widgets/home_widget_settings_card.dart';
import 'package:habit_tracker/features/home_widget/presentation/widgets/home_widget_tip_card.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeWidgetService extends HomeWidgetService {
  _FakeHomeWidgetService({
    this.available = true,
    this.canPin = true,
    this.installed = 0,
  });

  final bool available;
  bool canPin;
  int installed;
  bool tipDismissed = false;
  int pinRequests = 0;

  @override
  bool get isAvailable => available;
  @override
  Future<bool> canRequestPin() async => available && canPin;
  @override
  Future<bool> requestPin() async {
    pinRequests++;
    return canPin;
  }

  @override
  Future<int> installedCount() async => installed;
  @override
  Future<bool> isTipDismissed() async => tipDismissed;
  @override
  Future<void> dismissTip() async => tipDismissed = true;
}

HabitModel _habit(String id) => HabitModel(
      id: id,
      title: 'Habit $id',
      frequency: const HabitFrequency.daily(),
      createdAt: DateTime(2026, 1, 1),
    );

Future<Widget> _host(
  WidgetTester tester,
  _FakeHomeWidgetService service,
  Widget child, {
  int habits = 2,
}) async {
  final storage = WebHabitStorage(InMemoryWebStore());
  await tester.runAsync(
    () => storage.savePayload(
      AppPayloadModel.initial(lastModifiedBy: 't').copyWith(
        habits: [for (var i = 0; i < habits; i++) _habit('$i')],
      ),
    ),
  );
  return ProviderScope(
    overrides: [
      habitStorageProvider.overrideWithValue(storage),
      homeWidgetServiceProvider.overrideWithValue(service),
    ],
    child: AppScreenUtilInit(
      builder: (_) => MaterialApp(
        theme: ThemeFactory.createTheme(UserThemeModel.defaultTheme),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('status is "unavailable" where the platform has no widget', () async {
    final container = ProviderContainer(
      overrides: [
        homeWidgetServiceProvider.overrideWithValue(
          _FakeHomeWidgetService(available: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    final status = await container.read(homeWidgetStatusProvider.future);
    expect(status.available, isFalse);
    expect(status.isInstalled, isFalse);
  });

  group('Settings card', () {
    testWidgets('offers "Add to home screen" and asks the launcher',
        (tester) async {
      final service = _FakeHomeWidgetService();
      await tester.pumpWidget(
        await _host(tester, service, const HomeWidgetSettingsCard()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget, reason: 'live preview');
      await tester.tap(find.text('Add to home screen'));
      await tester.pump();
      expect(service.pinRequests, 1);

      // The user accepted the system dialog; the card re-checks.
      service.installed = 1;
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text('On your home screen'), findsOneWidget);
      expect(find.text('Add another'), findsOneWidget);
    });

    testWidgets('explains manual steps when the launcher cannot pin',
        (tester) async {
      final service = _FakeHomeWidgetService(canPin: false);
      await tester.pumpWidget(
        await _host(tester, service, const HomeWidgetSettingsCard()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to home screen'));
      await tester.pumpAndSettle();
      expect(find.text('Add the widget'), findsOneWidget);
      expect(service.pinRequests, 0);
    });
  });

  group('Dashboard tip', () {
    testWidgets('shows for a routine of 2+ habits and stays dismissed',
        (tester) async {
      final service = _FakeHomeWidgetService();
      await tester.pumpWidget(
        await _host(tester, service, const HomeWidgetTipCard()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add a home screen widget'), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Add a home screen widget'), findsNothing);
      expect(service.tipDismissed, isTrue);
    });

    testWidgets('hidden with fewer than 2 habits', (tester) async {
      await tester.pumpWidget(
        await _host(
          tester,
          _FakeHomeWidgetService(),
          const HomeWidgetTipCard(),
          habits: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add a home screen widget'), findsNothing);
    });

    testWidgets('hidden once the widget is on the home screen',
        (tester) async {
      await tester.pumpWidget(
        await _host(
          tester,
          _FakeHomeWidgetService(installed: 1),
          const HomeWidgetTipCard(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add a home screen widget'), findsNothing);
    });
  });

  test('widget sync stamps the day so stale data is never shown', () async {
    final saved = <String, Object?>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('widgets_kit'),
            (call) async {
      if (call.method == 'saveWidgetData') {
        final args = (call.arguments as Map).cast<String, Object?>();
        saved[args['id']! as String] = args['data'];
      }
      return true;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('widgets_kit'), null),
    );

    await HabitWidgetSyncService().syncHabits(
      habits: [_habit('a')],
      date: DateTime(2026, 3, 9, 15),
    );

    expect(saved[HabitWidgetSyncService.keyDateKey], '2026-03-09');
    expect(saved[HabitWidgetSyncService.keyTotalCount], 1);
  });
}
