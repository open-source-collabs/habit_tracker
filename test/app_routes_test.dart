import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/routes/routes.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:habit_tracker/presentation/widgets/data_portability_dialog.dart';
import 'package:habit_tracker/presentation/widgets/habit_creator_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHabitStorage implements HabitStorage {
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

Widget _wrapWithApp(Widget child) {
  final themeData = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

  return ProviderScope(
    overrides: [habitStorageProvider.overrideWithValue(_FakeHabitStorage())],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        theme: themeData,
        home: child,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onUnknownRoute: AppRouter.onUnknownRoute,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppRoutes & AppRouter Unit Tests', () {
    testWidgets(
      'onGenerateRoute resolves dashboard root and tabs with correct initial index',
      (tester) async {
        late BuildContext testContext;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (ctx) {
                testContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final rootRoute = AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.dashboard),
        ) as MaterialPageRoute;
        final rootScreen = rootRoute.builder(testContext) as DashboardScreen;
        expect(rootScreen.initialTabIndex, equals(0));

        final analyticsRoute = AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.analytics),
        ) as MaterialPageRoute;
        final analyticsScreen =
            analyticsRoute.builder(testContext) as DashboardScreen;
        expect(analyticsScreen.initialTabIndex, equals(1));

        final themesRoute = AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.themes),
        ) as MaterialPageRoute;
        final themesScreen =
            themesRoute.builder(testContext) as DashboardScreen;
        expect(themesScreen.initialTabIndex, equals(2));

        final syncRoute = AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.sync),
        ) as MaterialPageRoute;
        final syncScreen = syncRoute.builder(testContext) as DashboardScreen;
        expect(syncScreen.initialTabIndex, equals(3));
      },
    );

    test('onGenerateRoute resolves editHabit with typed HabitRouteArgs', () {
      final sampleHabit = HabitModel(
        id: 'habit-123',
        title: 'Morning Yoga',
        routineGroup: 'Morning',
        accentIndex: 1,
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 1, 1),
      );

      final route = AppRouter.onGenerateRoute(
        RouteSettings(
          name: AppRoutes.editHabit,
          arguments: HabitRouteArgs(habit: sampleHabit),
        ),
      );

      expect(route, isNotNull);
      expect(route.settings.name, equals(AppRoutes.editHabit));
    });

    testWidgets('onUnknownRoute returns NotFoundScreen route', (tester) async {
      late BuildContext testContext;
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (ctx) {
              testContext = ctx;
              return const SizedBox();
            },
          ),
        ),
      );

      final unknownRoute = AppRouter.onUnknownRoute(
        const RouteSettings(name: '/invalid-path-123'),
      ) as MaterialPageRoute;

      final screen = unknownRoute.builder(testContext) as NotFoundScreen;
      expect(screen.routeName, equals('/invalid-path-123'));
    });
  });

  group('Named Route Integration Widget Tests', () {
    testWidgets('NotFoundScreen renders 404 message and Back button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(const NotFoundScreen(routeName: '/test/broken/link')),
      );
      await tester.pumpAndSettle();

      expect(find.text('404 - Route Not Found'), findsOneWidget);
      expect(find.textContaining('/test/broken/link'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });

    testWidgets('AppNavigator.toCreateHabit pushes HabitCreatorSheet route', (
      tester,
    ) async {
      late BuildContext navContext;

      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) {
              navContext = context;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => AppNavigator.toCreateHabit(context),
                  child: const Text('Open Creator'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Creator'));
      await tester.pumpAndSettle();

      expect(find.byType(HabitCreatorSheet), findsOneWidget);

      AppNavigator.pop(navContext);
      await tester.pumpAndSettle();
      expect(find.byType(HabitCreatorSheet), findsNothing);
    });

    testWidgets(
      'AppNavigator.toDataPortability pushes DataPortabilityDialog route',
      (tester) async {
        late BuildContext navContext;

        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) {
                navContext = context;
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => AppNavigator.toDataPortability(context),
                    child: const Text('Open Sync'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sync'));
        await tester.pumpAndSettle();

        expect(find.byType(DataPortabilityDialog), findsOneWidget);

        AppNavigator.pop(navContext);
        await tester.pumpAndSettle();
        expect(find.byType(DataPortabilityDialog), findsNothing);
      },
    );
  });
}
