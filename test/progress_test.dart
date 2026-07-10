// Progress-analysis tests (T-108): mastery buckets, weakness ordering,
// due forecast, retention, and neutral activity counting.

import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/domain/fsrs.dart';
import 'package:sensei_app/domain/progress.dart';

({ScheduledCard card, String word, String meaningBn}) entry(
  String id, {
  CardState state = CardState.review,
  double stability = 10,
  double difficulty = 5,
  int reps = 3,
  int lapses = 0,
  DateTime? due,
}) =>
    (
      card: ScheduledCard(
        id: id,
        state: state,
        stability: stability,
        difficulty: difficulty,
        reps: reps,
        lapses: lapses,
        due: due ?? DateTime(2026, 7, 10),
      ),
      word: id,
      meaningBn: 'অর্থ-$id',
    );

void main() {
  final now = DateTime(2026, 7, 10, 12, 0);

  group('mastery buckets', () {
    test('classification follows state + stability', () {
      expect(bucketOf(entry('a', state: CardState.newCard, reps: 0).card),
          MasteryBucket.newCard);
      expect(bucketOf(entry('b', state: CardState.learning).card),
          MasteryBucket.learning);
      expect(bucketOf(entry('c', state: CardState.relearning).card),
          MasteryBucket.learning);
      expect(bucketOf(entry('d', stability: 3).card), MasteryBucket.young);
      expect(bucketOf(entry('e', stability: 8).card), MasteryBucket.retained);
    });
  });

  group('weakness', () {
    test('lapses dominate the score; low stability adds to it', () {
      final lapsed = weaknessScore(entry('x', lapses: 3, stability: 2).card);
      final stable = weaknessScore(entry('y', lapses: 0, stability: 20).card);
      expect(lapsed, greaterThan(stable));
    });
  });

  group('buildProgressReport', () {
    test('counts, forecast, retention, and activity are correct', () {
      final cards = [
        entry('new1', state: CardState.newCard, reps: 0),
        entry('learn1', state: CardState.learning, due: now),
        entry('young1', stability: 2, due: now.add(const Duration(days: 2))),
        entry('ret1', stability: 30, due: now.add(const Duration(days: 6))),
        entry('overdue',
            stability: 1,
            lapses: 4,
            due: now.subtract(const Duration(days: 3))),
        entry('far', stability: 40, due: now.add(const Duration(days: 30))),
      ];
      final report = buildProgressReport(
        cards: cards,
        recentRatings: [3, 3, 1, 4, 3], // one "again" in five
        activityDays: [
          DateTime(2026, 7, 10),
          DateTime(2026, 7, 8),
          DateTime(2026, 5, 1), // outside the 30-day window
        ],
        now: now,
      );

      expect(report.total, 6);
      expect(report.newCount, 1);
      expect(report.learning, 1);
      expect(report.young, 2); // young1 + overdue (stability < 7)
      expect(report.retained, 2);

      expect(report.retention, closeTo(0.8, 1e-9));

      // Forecast: overdue + today's learn1 + new1 (default due = today) land
      // on index 0; young1 on 2; ret1 on 6; 'far' beyond the window is out.
      expect(report.dueForecast[0], 3);
      expect(report.dueForecast[2], 1);
      expect(report.dueForecast[6], 1);
      expect(report.dueForecast.reduce((a, b) => a + b), 5);

      expect(report.activeDaysLast30, 2);

      // Weakest first: the much-lapsed overdue card tops the list; the
      // never-reviewed card is excluded (nothing to diagnose yet).
      expect(report.weakest.first.id, 'overdue');
      expect(report.weakest.any((w) => w.id == 'new1'), isFalse);
    });

    test('empty store yields a calm empty report', () {
      final report = buildProgressReport(
          cards: const [], recentRatings: const [], activityDays: const [], now: now);
      expect(report.isEmpty, isTrue);
      expect(report.retention, 1.0);
      expect(report.weakest, isEmpty);
    });
  });
}
