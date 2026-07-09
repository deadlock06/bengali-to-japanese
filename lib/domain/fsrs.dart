// FSRS-4.5 spaced-repetition scheduler — pure Dart, no dependencies.
//
// Reference: Free Spaced Repetition Scheduler (FSRS) v4.5, power forgetting
// curve. 17 weights. This is the on-device memory engine for SENSEI.
//
// The math here is mirrored in tools/fsrs_reference.mjs and property-tested
// (higher rating -> longer interval; R(0)=1 and decreasing in time; interval
// grows with stability; difficulty stays within [1,10]).

import 'dart:math' as math;

/// User grade for a review.
enum Rating { again, hard, good, easy } // 1,2,3,4

extension RatingValue on Rating {
  int get g => index + 1; // again=1 ... easy=4
}

/// Card learning state.
enum CardState { newCard, learning, review, relearning }

/// Power forgetting-curve constants (FSRS-4.5).
const double kDecay = -0.5;
const double kFactor = 19.0 / 81.0; // = 0.9^(1/decay) - 1

class Fsrs {
  /// FSRS-4.5 default weights (same array frozen in the architecture spec).
  final List<double> w;

  /// Target retention when scheduling the next interval (0<r<1).
  final double requestRetention;

  /// Hard cap on interval in days.
  final int maximumInterval;

  const Fsrs({
    this.w = const [
      0.40255, 0.59854, 2.40984, 5.80984, 4.92593, 0.94123, 0.86231,
      0.01000, 1.48959, 0.14480, 0.94123, 2.18154, 0.05000, 0.34560,
      1.26000, 0.29400, 2.61000,
    ],
    this.requestRetention = 0.90,
    this.maximumInterval = 36500,
  });

  // ---- Retrievability & interval ----

  /// Probability of recall after [elapsedDays] given [stability].
  double retrievability(double elapsedDays, double stability) {
    if (stability <= 0) return 0;
    return math.pow(1 + kFactor * elapsedDays / stability, kDecay).toDouble();
  }

  /// Interval (whole days) that lands retention at [requestRetention].
  int nextInterval(double stability) {
    final ivl = (stability / kFactor) *
        (math.pow(requestRetention, 1 / kDecay).toDouble() - 1);
    return ivl.round().clamp(1, maximumInterval);
  }

  // ---- Initial values (first review of a new card) ----

  double _initStability(int g) => math.max(w[g - 1], 0.1);

  double _initDifficulty(int g) =>
      _clampD(w[4] - w[5] * (g - 3));

  double _clampD(double d) => d.clamp(1.0, 10.0);

  // ---- Difficulty update (with mean reversion toward "easy" init) ----

  double _nextDifficulty(double d, int g) {
    final delta = d - w[6] * (g - 3);
    final reverted = w[7] * _initDifficulty(4) + (1 - w[7]) * delta;
    return _clampD(reverted);
  }

  // ---- Stability updates ----

  double _stabilityAfterRecall(double d, double s, double r, int g) {
    final hardPenalty = (g == Rating.hard.g) ? w[15] : 1.0;
    final easyBonus = (g == Rating.easy.g) ? w[16] : 1.0;
    final inc = math.exp(w[8]) *
        (11 - d) *
        math.pow(s, -w[9]).toDouble() *
        (math.exp((1 - r) * w[10]).toDouble() - 1) *
        hardPenalty *
        easyBonus;
    return s * (1 + inc);
  }

  double _stabilityAfterForget(double d, double s, double r) {
    return w[11] *
        math.pow(d, -w[12]).toDouble() *
        (math.pow(s + 1, w[13]).toDouble() - 1) *
        math.exp((1 - r) * w[14]).toDouble();
  }

  /// Apply a review to [card] with [rating] at [now]; returns the updated card.
  ScheduledCard review(ScheduledCard card, Rating rating,
      {DateTime? now}) {
    now ??= DateTime.now();
    final g = rating.g;
    final elapsed = card.lastReview == null
        ? 0.0
        : now.difference(card.lastReview!).inSeconds / 86400.0;

    double stability, difficulty;
    CardState state;
    int lapses = card.lapses;

    if (card.state == CardState.newCard) {
      stability = _initStability(g);
      difficulty = _initDifficulty(g);
      state = (g == Rating.again.g) ? CardState.learning : CardState.review;
    } else {
      final r = retrievability(elapsed, card.stability);
      if (g == Rating.again.g) {
        stability = _stabilityAfterForget(card.difficulty, card.stability, r);
        difficulty = _nextDifficulty(card.difficulty, g);
        state = CardState.relearning;
        lapses += 1;
      } else {
        stability =
            _stabilityAfterRecall(card.difficulty, card.stability, r, g);
        difficulty = _nextDifficulty(card.difficulty, g);
        state = CardState.review;
      }
    }

    final intervalDays =
        (g == Rating.again.g) ? 0 : nextInterval(stability); // relearn same day
    final due = (g == Rating.again.g)
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(days: intervalDays));

    return card.copyWith(
      stability: stability,
      difficulty: difficulty,
      state: state,
      lapses: lapses,
      reps: card.reps + 1,
      lastReview: now,
      due: due,
      elapsedDays: elapsed,
    );
  }
}

/// Minimal schedulable card. Vocabulary/content fields live in the DB model.
class ScheduledCard {
  final String id;
  final double stability;
  final double difficulty;
  final CardState state;
  final int reps;
  final int lapses;
  final DateTime? lastReview;
  final DateTime due;
  final double elapsedDays;

  ScheduledCard({
    required this.id,
    this.stability = 0,
    this.difficulty = 0,
    this.state = CardState.newCard,
    this.reps = 0,
    this.lapses = 0,
    this.lastReview,
    DateTime? due,
    this.elapsedDays = 0,
  }) : due = due ?? DateTime.now();

  ScheduledCard copyWith({
    double? stability,
    double? difficulty,
    CardState? state,
    int? reps,
    int? lapses,
    DateTime? lastReview,
    DateTime? due,
    double? elapsedDays,
  }) =>
      ScheduledCard(
        id: id,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        state: state ?? this.state,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        lastReview: lastReview ?? this.lastReview,
        due: due ?? this.due,
        elapsedDays: elapsedDays ?? this.elapsedDays,
      );
}
