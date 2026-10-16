import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets/widgets.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

Widget _buildTestableNavBar({
  required int currentIndex,
  required ValueChanged<int> onTap,
  VoidCallback? onCenterActionPressed,
  UserThemeModel? themeModel,
  List<AppFloatingNavBarItem>? customItems,
  double maxWidth = 480.0,
}) {
  final activeTheme = themeModel ?? UserThemeModel.obsidianTwilight;
  final themeData = ThemeFactory.createTheme(activeTheme);

  final defaultItems = [
    const AppFloatingNavBarItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Today',
      tooltip: 'Today Dashboard',
    ),
    const AppFloatingNavBarItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Analytics',
      tooltip: 'Habit Analytics',
    ),
    const AppFloatingNavBarItem(
      icon: Icons.palette_outlined,
      activeIcon: Icons.palette_rounded,
      label: 'Themes',
      tooltip: 'Themes Studio',
    ),
    const AppFloatingNavBarItem(
      icon: Icons.cloud_sync_outlined,
      activeIcon: Icons.cloud_sync_rounded,
      label: 'Sync',
      tooltip: 'Cloud Sync',
    ),
  ];

  return ProviderScope(
    child: AppScreenUtilInit(
      builder: (context) => MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: AppFloatingNavBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: customItems ?? defaultItems,
            onCenterActionPressed: onCenterActionPressed,
            maxWidth: maxWidth,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppFloatingNavBar Widget Tests', () {
    testWidgets('renders all 4 tabs and center quick-add button', (tester) async {
      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 0,
          onTap: (_) {},
          onCenterActionPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Themes'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tabs are tapped', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 0,
          onTap: (idx) => tappedIndex = idx,
          onCenterActionPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      // Tap Analytics tab (index 1)
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(1));

      // Tap Themes tab (index 2)
      await tester.tap(find.text('Themes'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(2));

      // Tap Sync tab (index 3)
      await tester.tap(find.text('Sync'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(3));

      // Tap Today tab (index 0)
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(0));
    });

    testWidgets('triggers onCenterActionPressed when central + button is pressed',
        (tester) async {
      bool centerPressed = false;

      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 0,
          onTap: (_) {},
          onCenterActionPressed: () => centerPressed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(centerPressed, isTrue);
    });

    testWidgets('renders active icon on selected tab and inactive on unselected',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 1, // Analytics is active
          onTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Active Analytics tab should display activeIcon (Icons.insights_rounded)
      expect(find.byIcon(Icons.insights_rounded), findsOneWidget);

      // Inactive Today tab should display icon (Icons.grid_view_outlined)
      expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    });

    testWidgets('renders badge counter correctly when item has badgeCount',
        (tester) async {
      final itemsWithBadge = [
        const AppFloatingNavBarItem(
          icon: Icons.grid_view_outlined,
          label: 'Today',
          badgeCount: 5,
        ),
        const AppFloatingNavBarItem(
          icon: Icons.insights_outlined,
          label: 'Analytics',
        ),
      ];

      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 0,
          onTap: (_) {},
          customItems: itemsWithBadge,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders with light theme (Nordic Serenity) without error',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 0,
          onTap: (_) {},
          themeModel: UserThemeModel.nordicSerenity,
          onCenterActionPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('clamps max width on desktop viewport to maxWidth constraint',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestableNavBar(
          currentIndex: 0,
          onTap: (_) {},
          maxWidth: 480.0,
          onCenterActionPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      // Find ConstrainedBox in AppFloatingNavBar
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byWidgetPredicate((w) =>
            w is ConstrainedBox &&
            w.constraints.maxWidth == 480.0),
      );
      expect(constrainedBoxes.isNotEmpty, isTrue);
    });
  });
}
