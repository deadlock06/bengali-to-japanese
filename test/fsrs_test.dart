// Dart mirror of tools/fsrs_reference.mjs property tests. Run: flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/domain/fsrs.dart';

void main() {
  const fsrs = Fsrs();

  test('retrievability: R(0)=1 and decreases with time', () {
    expect(fsrs.retrievability(0, 5), closeTo(1.0, 1e-9));
    expect(fsrs.retrievability(1, 5), greaterThan(fsrs.retrievability(10, 5)));
  });

  test('interval grows with stability and is >= 1 day', () {
    expect(fsrs.nextInterval(2), lessThan(fsrs.nextInterval(20)));
    expect(fsrs.nextInterval(0.01), greaterThanOrEqualTo(1));
  });

  ScheduledCard newCard() => ScheduledCard(id: 'x');

  test('new-card first review: Again<Hard<Good<Easy stability', () {
    final now = DateTime.now();
    final s1 = fsrs.review(newCard(), Rating.again, now: now).stability;
    final s2 = fsrs.review(newCard(), Rating.hard, now: now).stability;
    final s3 = fsrs.review(newCard(), Rating.good, now: now).stability;
    final s4 = fsrs.review(newCard(), Rating.easy, now: now).stability;
    expect(s1 < s2 && s2 < s3 && s3 < s4, isTrue);
  });

  test('difficulty stays within [1,10]', () {
    for (final r in Rating.values) {
      final d = fsrs.review(newCard(), r).difficulty;
      expect(d, inInclusiveRange(1.0, 10.0));
    }
  });

  test('Again on a review card lowers stability and adds a lapse', () {
    final now = DateTime.now();
    final card = ScheduledCard(
      id: 'y',
      stability: 10,
      difficulty: 5,
      state: CardState.review,
      lastReview: now.subtract(const Duration(days: 12)),
    );
    final after = fsrs.review(card, Rating.again, now: now);
    expect(after.stability, lessThan(card.stability));
    expect(after.lapses, equals(1));
  });
}
