import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/habit_card.dart';

Widget _buildTestableCard(Widget child) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('BentoHabitCard renders badges, emoji, title, and streak counter',
      (tester) async {
    final today = DateTime(2026, 10, 11);
    final yesterday = DateTime(2026, 10, 10);

    final habit = HabitModel(
      id: 'card_test_1',
      title: 'Electrolyte Hydration',
      subtitle: '3 liters throughout the day',
      frequency: const HabitFrequency.daily(),
      routineGroup: 'Health',
      accentIndex: 1,
      createdAt: DateTime(2026, 1, 1),
      emoji: '💧',
      checkIns: {
        HabitModel.formatDate(yesterday): true,
      },
    );

    bool toggled = false;

    await tester.pumpWidget(
      _buildTestableCard(
        BentoHabitCard(
          habit: habit,
          date: today,
          onToggle: () => toggled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Electrolyte Hydration'), findsOneWidget);
    expect(find.text('3 liters throughout the day'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('💧'), findsOneWidget);
    expect(find.text('1 days'), findsOneWidget);

    // Tap check button
    final checkButton = find.byType(GestureDetector).first;
    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });

  testWidgets('BentoHabitCard shows checkmark and glow when completed',
      (tester) async {
    final today = DateTime(2026, 10, 11);
    final yesterday = DateTime(2026, 10, 10);

    final habitCompleted = HabitModel(
      id: 'card_test_2',
      title: 'Completed Habit',
      frequency: const HabitFrequency.daily(),
      createdAt: DateTime(2026, 1, 1),
      checkIns: {
        HabitModel.formatDate(today): true,
        HabitModel.formatDate(yesterday): true,
      },
    );

    await tester.pumpWidget(
      _buildTestableCard(
        BentoHabitCard(
          habit: habitCompleted,
          date: today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('BentoHabitCard triggers scale spring animation on tap',
      (tester) async {
    final today = DateTime(2026, 10, 11);

    final habit = HabitModel(
      id: 'card_scale_test',
      title: 'Spring Animation Test',
      frequency: const HabitFrequency.daily(),
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      _buildTestableCard(
        BentoHabitCard(
          habit: habit,
          date: today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial scale is 1.0
    final scaleFinder = find.byType(ScaleTransition).first;
    ScaleTransition scaleWidget = tester.widget(scaleFinder);
    expect(scaleWidget.scale.value, 1.0);

    // Press down
    final gesture = await tester.startGesture(tester.getCenter(find.text('Spring Animation Test')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    scaleWidget = tester.widget(scaleFinder);
    expect(scaleWidget.scale.value, lessThan(1.0));

    // Release
    await gesture.up();
    await tester.pumpAndSettle();

    scaleWidget = tester.widget(scaleFinder);
    expect(scaleWidget.scale.value, 1.0);
  });
}
