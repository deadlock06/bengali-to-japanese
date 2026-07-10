// Scaffold agent (04 §3) — micro-teaching & confusion resolution. Watches
// deterministic confusion signals and OFFERS help; the learner pulls each
// rung of the hint ladder themselves. Always asks, never commands; accepting
// or dismissing carries no penalty.

import 'agent_state.dart';

/// Scaffold thresholds (04 §3). Shared with tests + the Node reference proof.
abstract final class ScaffoldRules {
  /// Hesitating longer than this before the first interaction → offer a hint.
  static const double hesitationMs = 3000;

  /// This many misses on the same pattern → offer switching to review.
  static const int missStreak = 3;

  /// "Random tapping": much faster than baseline AND mostly wrong → offer help.
  static const double rapidTapSpeed = 2.5;
  static const double rapidErrorRate = 0.50;
}

/// Pure check: returns the single most relevant offer, or null when the
/// learner shows no confusion signal. Priority: repeated same-pattern misses
/// (strongest evidence) > hesitation > frantic tapping.
ScaffoldOffer? scaffoldCheck(SessionSignals s) {
  if (s.consecutiveMissesOnPattern >= ScaffoldRules.missStreak) {
    return const ScaffoldOffer(
      kind: ScaffoldKind.reviewSwitch,
      promptBn: 'এই ধরনটা বারবার আটকে যাচ্ছে — একটু পিছিয়ে ঝালাই করবে?',
    );
  }
  if (s.meanHesitationMs > ScaffoldRules.hesitationMs) {
    return const ScaffoldOffer(
      kind: ScaffoldKind.hint,
      promptBn: 'এটা নিয়ে সাহায্য লাগবে?',
    );
  }
  if (s.tapSpeedRatio > ScaffoldRules.rapidTapSpeed &&
      s.recentErrorRate > ScaffoldRules.rapidErrorRate) {
    return const ScaffoldOffer(
      kind: ScaffoldKind.helpOffer,
      promptBn: 'একসাথে ধীরে ধীরে দেখি? সাহায্য চাইলে বলো।',
    );
  }
  return null;
}
