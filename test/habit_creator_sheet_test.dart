import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:habit_tracker/core/widgets/app_switch.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/habit_creator_sheet.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
  final themeData = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

  return ProviderScope(
    overrides: overrides,
    child: AppScreenUtilInit(
      builder: (context) => MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HabitCreatorSheet Studio Widget Tests', () {
    testWidgets('renders all studio sections in bottom sheet mode',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Habit'), findsOneWidget);
      expect(find.text('HABIT TITLE'), findsOneWidget);
      expect(find.text('SUBTITLE / NOTES'), findsOneWidget);
      expect(find.text('COLOR ACCENT'), findsOneWidget);
      expect(find.text('ICON & EMOJI GLYPH'), findsOneWidget);
      expect(find.text('Emoji Glyph'), findsOneWidget);
      expect(find.text('Material Icon'), findsOneWidget);
      expect(find.text('FREQUENCY CONFIGURATOR'), findsOneWidget);
      expect(find.text('Every Day'), findsOneWidget);
      expect(find.text('Specific Days'), findsOneWidget);
      expect(find.text('Times / Week'), findsOneWidget);
      expect(find.text('GROUP / ROUTINE'), findsOneWidget);
      expect(find.text('Reminder Alarm'), findsOneWidget);
      expect(find.text('Create Habit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders in dialog mode on desktop viewport', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('New Habit'), findsOneWidget);
      expect(find.text('HABIT TITLE'), findsOneWidget);
      expect(find.text('Create Habit'), findsOneWidget);
    });

    testWidgets('validates required title and shows error', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a habit title'), findsOneWidget);
    });

    testWidgets('switches icon & emoji tabs and selects icons', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      // Default tab is Emoji
      expect(find.text('Emoji Glyph'), findsOneWidget);

      // Tap on Material Icon tab
      await tester.tap(find.text('Material Icon'));
      await tester.pumpAndSettle();

      // Find icons in registry, e.g. fitness_center
      expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);

      // Tap an icon
      await tester.tap(find.byIcon(Icons.fitness_center_rounded));
      await tester.pumpAndSettle();

      // Switch back to Emoji tab
      await tester.tap(find.text('Emoji Glyph'));
      await tester.pumpAndSettle();

      // Tap water drop emoji
      await tester.tap(find.text('💧'));
      await tester.pumpAndSettle();
    });

    testWidgets('configures frequency modes (Specific Days and Times/Week stepper)',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      // Ensure frequency configurator is visible
      await tester.ensureVisible(find.text('Specific Days'));
      await tester.tap(find.text('Specific Days'));
      await tester.pumpAndSettle();

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Weekdays'), findsOneWidget);
      expect(find.text('Weekends'), findsOneWidget);

      // Tap Weekends preset
      await tester.tap(find.text('Weekends'));
      await tester.pumpAndSettle();

      // Switch to Times / Week
      await tester.tap(find.text('Times / Week'));
      await tester.pumpAndSettle();

      expect(find.text('3 × / wk'), findsOneWidget);

      // Increment stepper
      await tester.tap(find.byIcon(Icons.add_circle_rounded));
      await tester.pumpAndSettle();
      expect(find.text('4 × / wk'), findsOneWidget);

      // Decrement stepper
      await tester.tap(find.byIcon(Icons.remove_circle_rounded));
      await tester.pumpAndSettle();
      expect(find.text('3 × / wk'), findsOneWidget);
    });

    testWidgets('toggles custom routine group entry', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      // Scroll to routine group
      await tester.ensureVisible(find.text('+ Custom Group'));
      await tester.tap(find.text('+ Custom Group'));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM ROUTINE NAME'), findsOneWidget);

      // Toggle back to list
      await tester.tap(find.text('Choose from list'));
      await tester.pumpAndSettle();

      expect(find.text('Morning Routine'), findsOneWidget);
    });

    testWidgets('toggles reminder alarm switch', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _buildTestableWidget(const HabitCreatorSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(AppSwitch);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Daily alarm time:'), findsOneWidget);
    });

    testWidgets('creates a new habit and updates habitListProvider',
        (tester) async {
      _setTallViewport(tester);
      HabitModel? createdHabit;

      await tester.pumpWidget(
        _buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  createdHabit = await HabitCreatorSheet.show(context);
                },
                child: const Text('Open Creator'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Creator'));
      await tester.pumpAndSettle();

      // Enter title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Ice Bath Recovery');
      await tester.pumpAndSettle();

      // Select Health group
      await tester.ensureVisible(find.text('Health'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Create Habit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Habit'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed and habit returned
      expect(createdHabit, isNotNull);
      expect(createdHabit!.title, 'Ice Bath Recovery');
      expect(createdHabit!.routineGroup, 'Health');
    });
  });
}
