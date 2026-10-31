import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/app_review/data/review_gateway.dart';
import 'package:habit_tracker/features/app_review/data/review_prompt_preferences.dart';
import 'package:habit_tracker/features/app_review/presentation/providers/review_prompt_service.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGateway implements ReviewGateway {
  bool available = true;
  int reviews = 0;
  int storePages = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => reviews++;

  @override
  Future<void> openStoreListing() async => storePages++;
}

void main() {
  late _FakeGateway gateway;
  late DateTime now;
  late ReviewPromptService service;

  /// A daily habit checked on the last [streak] days, ending today.
  HabitModel habit({int streak = 7, bool archived = false}) => HabitModel(
        id: 'h$streak$archived',
        title: 'Read',
        frequency: const HabitFrequency(type: HabitFrequencyType.daily),
        createdAt: now.subtract(const Duration(days: 30)),
        isArchived: archived,
        checkIns: {
          for (var i = 0; i < streak; i++)
            HabitModel.formatDate(now.subtract(Duration(days: i))): true,
        },
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    gateway = _FakeGateway();
    now = DateTime.utc(2026, 3, 1, 12);
    service = ReviewPromptService(
      gateway: gateway,
      prefs: const ReviewPromptPreferences(),
      now: () => now,
    );
    await service.registerFirstUse();
    now = now.add(const Duration(days: 10)); // past the first-week grace
  });

  test('asks a regular user who is on a streak', () async {
    expect(await service.shouldAsk([habit(streak: 8)]), isTrue);
  });

  test('never asks a brand-new user', () async {
    now = DateTime.utc(2026, 3, 3);
    expect(await service.shouldAsk([habit(streak: 8)]), isFalse);
  });

  test('needs enough distinct active days', () async {
    expect(await service.shouldAsk([habit(streak: 2)]), isFalse);
  });

  test('needs a good moment: no streak and habits left undone', () async {
    final done = habit(streak: 4);
    final pending = habit(streak: 0);
    expect(await service.shouldAsk([done, pending]), isFalse);
  });

  test('finishing every habit today counts as a good moment', () async {
    expect(await service.shouldAsk([habit(streak: 4)]), isTrue);
  });

  test('ignores archived habits', () async {
    expect(
      await service.shouldAsk([habit(streak: 4), habit(streak: 0, archived: true)]),
      isTrue,
    );
  });

  test('waits 60 days between asks and stops after three', () async {
    final habits = [habit(streak: 8)];
    await service.recordAsked();
    expect(await service.shouldAsk(habits), isFalse);

    now = now.add(ReviewPromptService.minGapBetweenAsks);
    final later = [habit(streak: 8)];
    expect(await service.shouldAsk(later), isTrue);

    await service.recordAsked();
    now = now.add(ReviewPromptService.minGapBetweenAsks);
    await service.recordAsked();
    now = now.add(ReviewPromptService.minGapBetweenAsks);
    expect(await service.shouldAsk([habit(streak: 8)]), isFalse);
  });

  test('a user who rated or opted out is never asked again', () async {
    await service.markFinished();
    expect(await service.shouldAsk([habit(streak: 8)]), isFalse);
  });

  test('uses the native sheet, falling back to the store page', () async {
    await service.requestReview();
    expect(gateway.reviews, 1);

    gateway.available = false;
    await service.requestReview();
    expect(gateway.storePages, 1);
  });
}
