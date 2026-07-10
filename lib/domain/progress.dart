// Progress analysis (T-108) — pure functions from SRS rows to a mastery
// report: bucket counts, retention, weak points, due forecast, activity.
// No I/O, no clock reads (caller passes `now`) — fully unit-testable.
//
// Framing rule (01/D-001): everything here is NEUTRAL history and guidance.
// Weak points are "tomorrow's focus", never failures; activity is a plain
// count, never a streak to protect.

import 'fsrs.dart';

/// A card's memory is "retained" once FSRS stability reaches this many days.
/// Product constant — levels and exam-readiness derive from it (04 §Feedback).
const double kRetainedStabilityDays = 7.0;

enum MasteryBucket { newCard, learning, young, retained }

MasteryBucket bucketOf(ScheduledCard c) {
  if (c.state == CardState.newCard || c.reps == 0) return MasteryBucket.newCard;
  if (c.state == CardState.learning || c.state == CardState.relearning) {
    return MasteryBucket.learning;
  }
  return c.stability >= kRetainedStabilityDays
      ? MasteryBucket.retained
      : MasteryBucket.young;
}

/// One item the learner keeps missing — surfaced as a focus suggestion.
class WeakPoint {
  final String id;
  final String word;
  final String meaningBn;

  /// Higher = weaker. Deterministic mix of lapses (dominant), FSRS difficulty,
  /// and how far stability still is from "retained".
  final double score;
  final int lapses;
  final double stability;

  const WeakPoint({
    required this.id,
    required this.word,
    required this.meaningBn,
    required this.score,
    required this.lapses,
    required this.stability,
  });
}

double weaknessScore(ScheduledCard c) {
  final stabilityGap =
      (kRetainedStabilityDays - c.stability).clamp(0.0, kRetainedStabilityDays);
  return c.lapses * 2.0 + stabilityGap * 0.5 + (c.difficulty - 5.0) * 0.2;
}

class ProgressReport {
  final int total;
  final int newCount, learning, young, retained;

  /// Recent recall success over the supplied history window (0..1);
  /// 1.0 when there is no history yet.
  final double retention;

  /// Weakest items first (only cards actually reviewed at least once).
  final List<WeakPoint> weakest;

  /// Cards becoming due on each of the next [days] days; index 0 = today
  /// (includes anything already overdue).
  final List<int> dueForecast;

  /// Days with any review in the last 30 — neutral history, not a streak.
  final int activeDaysLast30;

  const ProgressReport({
    required this.total,
    required this.newCount,
    required this.learning,
    required this.young,
    required this.retained,
    required this.retention,
    required this.weakest,
    required this.dueForecast,
    required this.activeDaysLast30,
  });

  bool get isEmpty => total == 0;
}

/// Builds the full report. [cards] pairs each scheduled card with its display
/// fields; [recentRatings] is the newest-first rating window (FSRS g values,
/// 1 = again); [activityDays] is newest-first distinct review days.
ProgressReport buildProgressReport({
  required List<({ScheduledCard card, String word, String meaningBn})> cards,
  required List<int> recentRatings,
  required List<DateTime> activityDays,
  required DateTime now,
  int forecastDays = 7,
  int weakLimit = 8,
}) {
  var newCount = 0, learning = 0, young = 0, retained = 0;
  for (final c in cards) {
    switch (bucketOf(c.card)) {
      case MasteryBucket.newCard:
        newCount++;
      case MasteryBucket.learning:
        learning++;
      case MasteryBucket.young:
        young++;
      case MasteryBucket.retained:
        retained++;
    }
  }

  final retention = recentRatings.isEmpty
      ? 1.0
      : recentRatings.where((g) => g > 1).length / recentRatings.length;

  final weakest = cards
      .where((c) => c.card.reps > 0)
      .map((c) => WeakPoint(
            id: c.card.id,
            word: c.word,
            meaningBn: c.meaningBn,
            score: weaknessScore(c.card),
            lapses: c.card.lapses,
            stability: c.card.stability,
          ))
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final today = DateTime(now.year, now.month, now.day);
  final forecast = List<int>.filled(forecastDays, 0);
  for (final c in cards) {
    final due = c.card.due;
    final dueDay = DateTime(due.year, due.month, due.day);
    final offset = dueDay.difference(today).inDays;
    if (offset < forecastDays) forecast[offset < 0 ? 0 : offset]++;
  }

  final cutoff = today.subtract(const Duration(days: 30));
  final active =
      activityDays.where((d) => !d.isBefore(cutoff)).toSet().length;

  return ProgressReport(
    total: cards.length,
    newCount: newCount,
    learning: learning,
    young: young,
    retained: retained,
    retention: retention,
    weakest: weakest.take(weakLimit).toList(growable: false),
    dueForecast: forecast,
    activeDaysLast30: active,
  );
}
