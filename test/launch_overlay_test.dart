import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/splash/presentation/launch_overlay.dart';

Widget _host(Future<void> ready, {bool reduceMotion = false}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: LaunchOverlay(
            ready: ready,
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('App content'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('covers the app until the intro is done and data is ready',
      (tester) async {
    final ready = Completer<void>();
    await tester.pumpWidget(_host(ready.future));

    // Intro plays; the app underneath is built but not reachable.
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('Track Free'), findsOneWidget);
    expect(find.text('App content'), findsOneWidget);
    expect(find.text('App content').hitTestable(), findsNothing);

    // Data arrives: the overlay fades out and is removed.
    ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('Track Free'), findsNothing);
    expect(find.text('App content').hitTestable(), findsOneWidget);
  });

  testWidgets('waits for the intro even when data is ready at once',
      (tester) async {
    await tester.pumpWidget(_host(Future<void>.value()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Track Free'), findsOneWidget, reason: 'still intro');
    await tester.pumpAndSettle();
    expect(find.text('Track Free'), findsNothing);
  });

  testWidgets('reduce motion skips the intro and only fades',
      (tester) async {
    await tester.pumpWidget(_host(Future<void>.value(), reduceMotion: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Track Free'), findsNothing);
    expect(find.text('App content').hitTestable(), findsOneWidget);
  });
}
