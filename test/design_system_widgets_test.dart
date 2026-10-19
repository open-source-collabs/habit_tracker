import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_dimensions.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:habit_tracker/core/widgets/widgets.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

Widget _buildTestableWidget(
  Widget child, {
  UserThemeModel? themeModel,
}) {
  final activeTheme = themeModel ?? UserThemeModel.obsidianTwilight;
  final themeData = ThemeFactory.createTheme(activeTheme);

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

  group('AppButton & AppIconButton', () {
    testWidgets('renders AppButton with text, responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppButton(
            text: 'Save Habit',
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save Habit'), findsOneWidget);
      await tester.tap(find.text('Save Habit'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppButton disabled state ignores taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppButton(
            text: 'Disabled Button',
            isDisabled: true,
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disabled Button'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('AppButton loading state shows CircularProgressIndicator and ignores tap',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppButton(
            text: 'Loading Action',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Action'), findsOneWidget);

      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('AppButton renders leading and trailing icons', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          AppButton(
            text: 'With Icons',
            leadingIcon: const Icon(Icons.star, key: Key('leading_star')),
            trailingIcon: const Icon(Icons.arrow_forward, key: Key('trailing_arrow')),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('leading_star')), findsOneWidget);
      expect(find.byKey(const Key('trailing_arrow')), findsOneWidget);
      expect(find.text('With Icons'), findsOneWidget);
    });

    testWidgets('AppButton icons match the label color in every variant', (
      tester,
    ) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _buildTestableWidget(
            AppButton(
              text: 'Sync',
              variant: variant,
              leadingIcon: const Icon(Icons.sync_rounded),
              trailingIcon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final labelColor = tester.widget<Text>(find.text('Sync')).style?.color;
        for (final icon in [Icons.sync_rounded, Icons.chevron_right_rounded]) {
          final iconColor = IconTheme.of(tester.element(find.byIcon(icon))).color;
          expect(iconColor, labelColor, reason: '$variant $icon');
        }
      }
    });

    testWidgets('AppIconButton triggers callback and renders icon', (tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppIconButton(
            icon: Icons.favorite,
            tooltip: 'Favorite',
            onPressed: () => clicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });
  });

  group('AppTextField', () {
    testWidgets('allows text entry and emits onChanged', (tester) async {
      final controller = TextEditingController();
      String changedText = '';

      await tester.pumpWidget(
        _buildTestableWidget(
          AppTextField(
            controller: controller,
            labelText: 'Habit Name',
            hintText: 'e.g. Read 20 mins',
            onChanged: (val) => changedText = val,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habit Name'), findsOneWidget);
      expect(find.text('e.g. Read 20 mins'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Morning Meditation');
      await tester.pumpAndSettle();

      expect(controller.text, 'Morning Meditation');
      expect(changedText, 'Morning Meditation');
    });

    testWidgets('clear button clears text in AppTextField', (tester) async {
      final controller = TextEditingController(text: 'Initial Text');

      await tester.pumpWidget(
        _buildTestableWidget(
          AppTextField(
            controller: controller,
            showClearButton: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial Text'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    testWidgets('password visibility toggle reveals and obscures text', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          const AppTextField(
            isPassword: true,
            hintText: 'Password',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

      final textFieldBefore = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldBefore.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.obscureText, isFalse);
    });
  });

  group('AppDropdown', () {
    testWidgets('displays selected value and triggers onChanged from modal sheet',
        (tester) async {
      String selected = 'daily';
      final items = [
        const AppDropdownItem(value: 'daily', label: 'Every Day'),
        const AppDropdownItem(value: 'weekly', label: 'Weekly Goal'),
        const AppDropdownItem(value: 'monthly', label: 'Monthly Habit'),
      ];

      await tester.pumpWidget(
        _buildTestableWidget(
          AppDropdown<String>(
            labelText: 'Frequency',
            value: selected,
            items: items,
            onChanged: (val) => selected = val,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Every Day'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);

      // Tap dropdown to open bottom sheet
      await tester.tap(find.text('Every Day'));
      await tester.pumpAndSettle();

      // Check bottom sheet options
      expect(find.text('Weekly Goal'), findsOneWidget);
      expect(find.text('Monthly Habit'), findsOneWidget);

      // Select 'Weekly Goal'
      await tester.tap(find.text('Weekly Goal'));
      await tester.pumpAndSettle();

      expect(selected, 'weekly');
    });
  });

  group('AppDialog & showAppConfirmDialog', () {
    testWidgets('renders AppDialog with title, message, and action buttons',
        (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppDialog(
            title: 'Delete Routine?',
            message: 'This will remove the routine and all habits.',
            confirmText: 'Delete',
            cancelText: 'Keep',
            isDestructive: true,
            onConfirm: () => confirmed = true,
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Routine?'), findsOneWidget);
      expect(find.text('This will remove the routine and all habits.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    testWidgets('showAppConfirmDialog returns boolean on confirmation',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        _buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showAppConfirmDialog(
                    context: context,
                    title: 'Confirm Action',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Open Confirm'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('AppBottomSheet & showAppBottomSheet', () {
    testWidgets('showAppBottomSheet opens styled bottom sheet and renders contents',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAppBottomSheet<void>(
                    context: context,
                    builder: (sheetContext) => const AppBottomSheet(
                      title: 'Theme Settings',
                      subtitle: 'Choose your visual preference',
                      child: Text('Custom Palette Content'),
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Theme Settings'), findsOneWidget);
      expect(find.text('Choose your visual preference'), findsOneWidget);
      expect(find.text('Custom Palette Content'), findsOneWidget);

      // Close button test
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Theme Settings'), findsNothing);
    });
  });

  group('AppBadge & AppStreakBadge', () {
    testWidgets('renders AppBadge with label and icon', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppBadge(
            label: 'Mindfulness',
            icon: const Icon(Icons.spa, key: Key('badge_icon')),
            color: AppColors.neonLavender,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mindfulness'), findsOneWidget);
      expect(find.byKey(const Key('badge_icon')), findsOneWidget);

      await tester.tap(find.text('Mindfulness'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('renders AppStreakBadge with flame icon and day count',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          const Column(
            children: [
              AppStreakBadge(streakCount: 1),
              AppStreakBadge(streakCount: 7),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 day streak'), findsOneWidget);
      expect(find.text('7 days streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsNWidgets(2));
    });
  });

  group('AppCard', () {
    testWidgets('renders child and responds to tap when interactive',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          AppCard(
            isInteractive: true,
            onTap: () => tapped = true,
            child: const Text('Bento Card Inner Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bento Card Inner Content'), findsOneWidget);

      await tester.tap(find.text('Bento Card Inner Content'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('AppSwitch', () {
    testWidgets('toggles on tap and exposes toggled semantics', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) => AppSwitch(
              value: value,
              semanticLabel: 'Sound',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      expect(value, isTrue);
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(AppSwitch),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, 'Sound');
      expect(semantics.properties.toggled, isTrue);
    });

    testWidgets('keeps a compact track inside a full tap target',
        (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(AppSwitch(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(AppSwitch));
      expect(size.height, AppSizes.minTapTarget);
      expect(size.width, AppSizes.minTapTarget);
    });

    testWidgets('disabled switch has no tap handler', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(const AppSwitch(value: false, onChanged: null)),
      );
      await tester.pumpAndSettle();

      final detector = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byType(AppSwitch),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(detector.onTap, isNull);
    });
  });
}
