import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:habit_tracker/presentation/widgets/heatmap_grid.dart';

Widget _buildTestableHeatmap(Widget child) {
  final themeData = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

  return ProviderScope(
    child: AppScreenUtilInit(
      builder: (context) => MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeatmapGrid 30-90 Day Calendar Tests', () {
    final refDate = DateTime(2026, 10, 11);
    final yesterday = DateTime(2026, 10, 10);
    final twoDaysAgo = DateTime(2026, 10, 9);

    final checkIns = {
      HabitModel.formatDate(refDate): true,
      HabitModel.formatDate(yesterday): true,
      HabitModel.formatDate(twoDaysAgo): true,
    };

    testWidgets('renders rounded day squares with 10x10 dp and 3px radius',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableHeatmap(
          HeatmapGrid(
            checkIns: checkIns,
            activeColor: AppColors.emeraldMint,
            initialRangeDays: 30,
            referenceDate: refDate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVITY HEATMAP'), findsOneWidget);
      expect(find.text('3 / 30 days completed (10%)'), findsOneWidget);

      // Verify Tooltips are present for days
      final tooltips = find.byType(Tooltip);
      expect(tooltips, findsWidgets);

      // Verify square container sizing
      final squareContainers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return widget.constraints?.minWidth == 10.0 ||
              (box.borderRadius == BorderRadius.circular(3.0));
        }
        return false;
      });

      expect(squareContainers, findsWidgets);
    });

    testWidgets('completed squares illuminate with activeColor',
        (tester) async {
      const activeColor = AppColors.sunsetCoral;

      await tester.pumpWidget(
        _buildTestableHeatmap(
          HeatmapGrid(
            checkIns: checkIns,
            activeColor: activeColor,
            initialRangeDays: 30,
            referenceDate: refDate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find 10x10 day squares decorated with the activeColor and 3px border radius
      final completedSquares = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == activeColor &&
              box.borderRadius == BorderRadius.circular(3.0);
        }
        return false;
      });

      // Exactly 3 completed check-ins within the range
      expect(completedSquares, findsNWidgets(3));
    });

    testWidgets('tooltip shows date and completion status on hover',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableHeatmap(
          HeatmapGrid(
            checkIns: checkIns,
            activeColor: AppColors.emeraldMint,
            initialRangeDays: 30,
            referenceDate: refDate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that at least one tooltip contains "Completed ✅"
      final completedTooltip = find.byWidgetPredicate((widget) {
        return widget is Tooltip &&
            widget.message != null &&
            widget.message!.contains('Completed ✅');
      });
      expect(completedTooltip, findsWidgets);

      // Check that at least one tooltip contains "Incomplete"
      final incompleteTooltip = find.byWidgetPredicate((widget) {
        return widget is Tooltip &&
            widget.message != null &&
            widget.message!.contains('Incomplete');
      });
      expect(incompleteTooltip, findsWidgets);
    });

    testWidgets('range selector pills toggle between 30D, 60D, and 90D',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableHeatmap(
          HeatmapGrid(
            checkIns: checkIns,
            activeColor: AppColors.cyanGlow,
            initialRangeDays: 90,
            referenceDate: refDate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('90 Days'), findsOneWidget);
      expect(find.text('3 / 90 days completed (3%)'), findsOneWidget);

      // Switch to 30D
      await tester.tap(find.text('30D'));
      await tester.pumpAndSettle();

      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('3 / 30 days completed (10%)'), findsOneWidget);

      // Switch to 60D
      await tester.tap(find.text('60D'));
      await tester.pumpAndSettle();

      expect(find.text('60 Days'), findsOneWidget);
      expect(find.text('3 / 60 days completed (5%)'), findsOneWidget);
    });

    testWidgets('HeatmapGrid.fromHabit factory initializes correctly',
        (tester) async {
      final habit = HabitModel(
        id: 'habit_heatmap_factory',
        title: 'Deep Meditation',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 1, 1),
        checkIns: checkIns,
        accentIndex: 2,
      );

      await tester.pumpWidget(
        _buildTestableHeatmap(
          Builder(
            builder: (ctx) => HeatmapGrid.fromHabit(
              habit: habit,
              context: ctx,
              initialRangeDays: 60,
              referenceDate: refDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVITY HEATMAP'), findsOneWidget);
      expect(find.text('60 Days'), findsOneWidget);
    });
  });
}
