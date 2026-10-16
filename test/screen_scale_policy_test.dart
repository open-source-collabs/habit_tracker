import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/app_dimensions.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';

void main() {
  group('AppDesign.designSizeFor', () {
    test('returns the mobile artboard for the reference phone', () {
      expect(AppDesign.designSizeFor(AppDesign.size), AppDesign.size);
    });

    test('bounds mobile scale to [minScale, maxScale]', () {
      const smallPhone = Size(320, 568);
      const foldable = Size(700, 900);

      final small = AppDesign.designSizeFor(smallPhone);
      expect(smallPhone.width / small.width, closeTo(320 / 390, 1e-9));
      expect(
        smallPhone.height / small.height,
        closeTo(AppDesign.minScale, 1e-9),
      );

      final large = AppDesign.designSizeFor(foldable);
      expect(foldable.width / large.width, closeTo(AppDesign.maxScale, 1e-9));
    });

    test('renders design units 1:1 on desktop', () {
      const desktop = Size(1440, 900);
      expect(AppDesign.designSizeFor(desktop), desktop);
    });
  });

  testWidgets('AppScreenUtilInit configures 1:1 scale on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late double width, height, radius, font;
    await tester.pumpWidget(
      AppScreenUtilInit(
        builder: (context) {
          width = 100.w;
          height = 100.h;
          radius = 100.r;
          font = 100.sp;
          return const SizedBox.shrink();
        },
      ),
    );

    expect([width, height, radius, font], everyElement(100.0));
  });

  test('no widget clamps ScreenUtil values locally', () {
    final localClamp = RegExp(r'\d(\.\d+)?\.(w|h|r|sp)\.clamp\(');
    final rawBreakpoint = RegExp(r'>=\s*768');
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (localClamp.hasMatch(lines[i]) || rawBreakpoint.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Scaling bounds live in AppDesign and the breakpoint in '
          'AppBreakpoints; use the tokens instead.',
    );
  });
}
