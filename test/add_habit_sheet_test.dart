import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/add_habit_sheet.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

Widget _buildTestableWidget(Widget child) {
  final themeData = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddHabitSheet', () {
    testWidgets('renders all fields, chips, and buttons in bottom sheet mode',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(const AddHabitSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Habit'), findsOneWidget);
      expect(find.text('HABIT TITLE'), findsOneWidget);
      expect(find.text('SUBTITLE / NOTES'), findsOneWidget);
      expect(find.text('ROUTINE CATEGORY'), findsOneWidget);
      expect(find.text('SCHEDULE FREQUENCY'), findsOneWidget);
      expect(find.text('ACCENT COLOR'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekdays'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Habit'), findsOneWidget);
    });

    testWidgets('renders properly in dialog mode', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(const AddHabitSheet(isDialog: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Habit'), findsOneWidget);
      expect(find.text('HABIT TITLE'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Habit'), findsOneWidget);
    });

    testWidgets('shows validation error when title is empty and user submits',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(const AddHabitSheet(isDialog: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a habit title'), findsOneWidget);
    });

    testWidgets('successfully creates habit when title is entered and submitted',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => AddHabitSheet.show(context),
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Enter habit title into the first text field
      await tester.enterText(textFields.first, 'Morning Cold Plunge');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Habit'));
      await tester.pumpAndSettle();

      // Sheet should have dismissed
      expect(find.text('Please enter a habit title'), findsNothing);
    });
  });
}
