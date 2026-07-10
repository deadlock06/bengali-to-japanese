// Feedback agent (04 §4) — mastery tracking & reporting. Every reward is a
// FIXED, PREDICTABLE function of mastery counts: correct answer → instant
// positive line (persona), lesson → fixed XP, 10 lessons → milestone,
// 50 retained words → level. NO variable rewards, ever (99 D-001).

import '../domain/progress.dart' show kRetainedStabilityDays;

/// Reward schedule constants — deliberately boring numbers, visible to the
/// learner in advance. Changing these is a product decision (log in 99).
abstract final class RewardSchedule {
  /// Fixed XP per completed lesson. Never randomized, never boosted.
  static const int xpPerLesson = 10;

  /// A milestone every N completed lessons.
  static const int lessonsPerMilestone = 10;

  /// A level every N retained words.
  static const int wordsPerLevel = 50;

  /// A card counts as "retained" once its FSRS stability reaches this many
  /// days — the memory survives a week without review (domain constant).
  static const double retainedStabilityDays = kRetainedStabilityDays;

  /// Exam target: the JFT-Basic A2 whitelist size (content_factory).
  static const int examTargetWords = 1200;
}

/// Deterministic totals derived from persisted counts.
class MasteryStats {
  final int lessonsCompleted;
  final int wordsRetained;
  const MasteryStats(
      {required this.lessonsCompleted, required this.wordsRetained});

  int get xp => lessonsCompleted * RewardSchedule.xpPerLesson;
  int get level => wordsRetained ~/ RewardSchedule.wordsPerLevel;
  int get milestones => lessonsCompleted ~/ RewardSchedule.lessonsPerMilestone;

  /// SSW progress marker: fraction of the exam word target retained (0..1).
  double get examReadiness =>
      (wordsRetained / RewardSchedule.examTargetWords).clamp(0.0, 1.0);
}

/// True exactly when this completion crosses a milestone boundary —
/// e.g. the 10th, 20th… lesson. Pure and predictable.
bool milestoneReached(int lessonsCompletedNow) =>
    lessonsCompletedNow > 0 &&
    lessonsCompletedNow % RewardSchedule.lessonsPerMilestone == 0;

/// True exactly when [wordsRetainedNow] crosses a level boundary that
/// [wordsRetainedBefore] had not reached.
bool levelUp(int wordsRetainedBefore, int wordsRetainedNow) =>
    wordsRetainedNow ~/ RewardSchedule.wordsPerLevel >
    wordsRetainedBefore ~/ RewardSchedule.wordsPerLevel;

/// End-of-session summary (learned / weak / next) the Feedback agent reports.
class SessionSummary {
  /// Item ids newly seeded into SRS this session.
  final List<String> learnedIds;

  /// Item ids missed 2+ times this session — tomorrow's focus, not a fault.
  final List<String> weakIds;

  /// Cards that will be due within the next day (what "next" looks like).
  final int dueTomorrow;

  final int xpEarned;
  final bool milestone;
  final bool leveledUp;

  const SessionSummary({
    required this.learnedIds,
    required this.weakIds,
    required this.dueTomorrow,
    required this.xpEarned,
    this.milestone = false,
    this.leveledUp = false,
  });

  /// Neutral Bengali summary line ("streaks are history, not leverage").
  String get lineBn {
    final parts = <String>[
      if (learnedIds.isNotEmpty) 'নতুন শিখলে ${learnedIds.length}টা',
      if (weakIds.isNotEmpty) 'ঝালাই দরকার ${weakIds.length}টার',
      if (dueTomorrow > 0) 'কাল রিভিউ $dueTomorrowটা',
    ];
    return parts.isEmpty ? 'আজ ঘুরে দেখলে — সেটাও শেখা।' : parts.join(' · ');
  }
}

/// Builds the summary from session bookkeeping. Pure.
SessionSummary buildSessionSummary({
  required List<String> learnedIds,
  required Map<String, int> missCounts,
  required int dueTomorrow,
  required int lessonsCompletedBefore,
  required int lessonsCompletedNow,
  required int wordsRetainedBefore,
  required int wordsRetainedNow,
}) {
  final weak = missCounts.entries
      .where((e) => e.value >= 2)
      .map((e) => e.key)
      .toList(growable: false);
  return SessionSummary(
    learnedIds: List.unmodifiable(learnedIds),
    weakIds: weak,
    dueTomorrow: dueTomorrow,
    xpEarned: (lessonsCompletedNow - lessonsCompletedBefore) *
        RewardSchedule.xpPerLesson,
    milestone: milestoneReached(lessonsCompletedNow) &&
        lessonsCompletedNow != lessonsCompletedBefore,
    leveledUp: levelUp(wordsRetainedBefore, wordsRetainedNow),
  );
}
