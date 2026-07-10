// Director agent (04 §1) — curriculum & pacing. A PURE decision function:
// SessionSignals in, DirectorDecision out. No clock, no randomness, no I/O —
// fully testable (mirrored by tools/agents_reference.mjs in CI).
//
// Constraint: RECOMMENDS, NEVER FORCES. Every output here is a suggestion the
// UI must render dismissible; continuing is always allowed (01 constitution).

import 'agent_state.dart';

/// Decision thresholds (04 §1 rules). Named so the Dart tests and the Node
/// reference proof assert against the same numbers.
abstract final class DirectorRules {
  /// Below this many graded answers we don't infer anything (cold start).
  static const int minAnswers = 4;

  /// STRUGGLE (in-session): recent accuracy < 60%.
  static const double struggleAccuracy = 0.60;

  /// STRUGGLE (session start): SRS retention < 60% after > 3 days away.
  static const double rustyRetention = 0.60;
  static const int rustyDaysAway = 3;

  /// BOREDOM: accuracy > 90% for > 20 minutes (autopilot).
  static const double boredomAccuracy = 0.90;
  static const int boredomMinutes = 20;

  /// BURNOUT: tap speed < 50% of the session's own baseline AND
  /// recent error rate > 30% — or the same error rate after 40+ minutes.
  static const double burnoutTapSpeed = 0.50;
  static const double burnoutErrorRate = 0.30;
  static const int fatigueMinutes = 40;

  /// FLOW: recent accuracy inside [0.70, 0.90].
  static const double flowLow = 0.70;

  /// Session-health soft caps (01 §Session-health, 09 §Session-cap UX).
  static const int breakSuggestMinutes = 20;
  static const int hardCapMinutes = 120;

  static const int minDifficulty = 1;
  static const int maxDifficulty = 10;
}

/// What the Director publishes each tick.
class DirectorDecision {
  final PsychState psych;
  final int difficulty; // 1..10
  final SessionAdvice advice;
  final String rationaleBn;
  const DirectorDecision({
    required this.psych,
    required this.difficulty,
    required this.advice,
    required this.rationaleBn,
  });
}

/// The Director's decision function. [currentDifficulty] is the difficulty in
/// force before this tick; the result nudges it by at most ±2 per tick so the
/// experience never whiplashes.
DirectorDecision directorDecide(SessionSignals s, {int currentDifficulty = 3}) {
  final psych = _classify(s);
  final difficulty = _adjustDifficulty(psych, s, currentDifficulty);
  final advice = _advise(psych, s);
  return DirectorDecision(
    psych: psych,
    difficulty: difficulty,
    advice: advice,
    rationaleBn: _rationale(psych, s),
  );
}

PsychState _classify(SessionSignals s) {
  // Session-start rule fires before any answers exist: rusty after days away.
  if (s.answers < DirectorRules.minAnswers) {
    final rusty = s.retention < DirectorRules.rustyRetention &&
        s.daysSinceLastSession > DirectorRules.rustyDaysAway;
    return rusty ? PsychState.struggle : PsychState.calibrating;
  }

  // Priority order matters: fatigue outranks everything (well-being first),
  // then struggle, then boredom; flow is the healthy default band.
  final fatigued = s.recentErrorRate > DirectorRules.burnoutErrorRate &&
      (s.tapSpeedRatio < DirectorRules.burnoutTapSpeed ||
          s.sessionMinutes >= DirectorRules.fatigueMinutes);
  if (fatigued) return PsychState.burnout;

  if (s.recentAccuracy < DirectorRules.struggleAccuracy) {
    return PsychState.struggle;
  }

  if (s.recentAccuracy > DirectorRules.boredomAccuracy &&
      s.sessionMinutes > DirectorRules.boredomMinutes) {
    return PsychState.boredom;
  }

  return PsychState.flow;
}

int _adjustDifficulty(PsychState psych, SessionSignals s, int current) {
  final delta = switch (psych) {
    PsychState.calibrating => 0,
    PsychState.flow =>
      // Hold inside the band; nudge up only at the top edge (i+1 pacing).
      s.recentAccuracy >= DirectorRules.boredomAccuracy ? 1 : 0,
    PsychState.boredom => 1,
    PsychState.struggle => -1,
    PsychState.burnout => -2,
  };
  return (current + delta)
      .clamp(DirectorRules.minDifficulty, DirectorRules.maxDifficulty);
}

SessionAdvice _advise(PsychState psych, SessionSignals s) {
  // Hard soft-cap (recommendation only): 120 min → easy-review-only offer.
  if (s.sessionMinutes >= DirectorRules.hardCapMinutes) {
    return const SessionAdvice(
      kind: AdviceKind.easyReviewOnly,
      messageBn: 'অনেকক্ষণ হলো — এখন শুধু সহজ রিভিউ করলে মাথা তাজা থাকবে। '
          'চাইলে চালিয়েও যেতে পারো।',
    );
  }
  if (psych == PsychState.burnout) {
    return const SessionAdvice(
      kind: AdviceKind.shortBreak,
      breakMinutes: 5,
      messageBn: 'তোমার মস্তিষ্ক ক্লান্ত মনে হচ্ছে। ৫ মিনিটের বিরতি নিলে ভালো হয়।',
    );
  }
  if (s.sessionMinutes >= DirectorRules.breakSuggestMinutes &&
      psych != PsychState.flow) {
    return const SessionAdvice(
      kind: AdviceKind.shortBreak,
      breakMinutes: 5,
      messageBn: '৫ মিনিটের বিরতি নিলে ভালো হয়।',
    );
  }
  return SessionAdvice.none;
}

String _rationale(PsychState psych, SessionSignals s) => switch (psych) {
      PsychState.calibrating => s.daysSinceLastSession > 0
          ? '${s.daysSinceLastSession} দিন পর ফিরেছ — ধীরে শুরু করি।'
          : 'শুরু করছি — তোমার গতি বুঝে নিচ্ছি।',
      PsychState.struggle => s.answers < DirectorRules.minAnswers
          ? 'আগে একটু ঝালাই করি।'
          : 'একটু কঠিন লাগছে — সহজ দিক থেকে এগোই।',
      PsychState.flow => 'দারুণ চলছে — এই গতিতেই থাকি।',
      PsychState.boredom => 'সবই পারছ! নতুন চ্যালেঞ্জ নিতে পারো।',
      PsychState.burnout => 'গতি কমে এসেছে — বিরতি নিলে ভালো হয়।',
    };
