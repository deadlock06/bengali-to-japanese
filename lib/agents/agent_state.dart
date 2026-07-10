// Agent contract types (04_AGENTS §State bus). Four deterministic agents
// publish through this shared vocabulary; the Director arbitrates. Every
// decision is explainable in Bengali and OVERRIDABLE by the user — nothing
// here can lock input, hide Skip, or force a continuation (01 constitution).
//
// Agents run on deterministic signals (taps, timing, accuracy) — never on
// LLM judgment (99 D-004).

/// The learner's inferred session state. Recommendations only — the UI adapts
/// colors/copy per 09 but never restricts what the learner may do.
enum PsychState {
  /// Not enough signals yet this session to infer anything (cold start).
  calibrating,

  /// Optimal challenge: accuracy ~70–85%, engaged, no fatigue signs.
  flow,

  /// Accuracy < 60% or rusty return: reduce difficulty, offer scaffolding.
  struggle,

  /// Fatigue: tap speed collapsed + errors rising. Recommend a break.
  burnout,

  /// Autopilot: accuracy > 90% for a while. Offer (not push) a challenge.
  boredom,
}

/// Tutor personality the learner picked. The agent may SUGGEST a switch,
/// never auto-switches (04 §Persona).
enum PersonaType {
  /// Strict, traditional — formal Bengali, measured praise.
  sensei,

  /// Warm elder sibling — patient, encouraging. The default.
  didi,

  /// Playful peer — casual register, exclamations.
  friend,

  /// Competitive trainer — pace-focused, but NEVER shaming; softens
  /// automatically when the learner struggles.
  coach,
}

/// What kind of help the Scaffold agent is offering. Always an offer the
/// learner accepts or dismisses; never applied automatically.
enum ScaffoldKind { hint, reviewSwitch, helpOffer }

/// A concrete, dismissible offer of help ("এটা নিয়ে সাহায্য লাগবে?").
class ScaffoldOffer {
  final ScaffoldKind kind;

  /// Bengali question copy (always asks, never commands — 04 §Scaffold).
  final String promptBn;
  const ScaffoldOffer({required this.kind, required this.promptBn});

  @override
  String toString() => 'ScaffoldOffer(${kind.name})';
}

/// What the Director recommends about the session itself. `continueSession`
/// is the neutral default; everything else is a dismissible recommendation.
enum AdviceKind { continueSession, shortBreak, easyReviewOnly, endSession }

class SessionAdvice {
  final AdviceKind kind;

  /// Bengali recommendation copy. Empty for the neutral default.
  final String messageBn;

  /// Suggested break length when [kind] == shortBreak.
  final int? breakMinutes;
  const SessionAdvice({
    required this.kind,
    this.messageBn = '',
    this.breakMinutes,
  });

  static const none = SessionAdvice(kind: AdviceKind.continueSession);
}

/// Deterministic inputs the agents read each tick. Built by the AgentBus from
/// raw interaction events; agents themselves stay pure functions of this.
class SessionSignals {
  /// Graded answers this session (recognition picks, context builds…).
  final int answers;
  final int correct;

  /// Sliding window (most recent ≤10 answers) for state detection, so one
  /// early mistake doesn't haunt the whole session.
  final int recentAnswers;
  final int recentCorrect;

  /// Time from a step appearing to the learner's first interaction with it,
  /// exponentially smoothed, in milliseconds. >3000 is the hesitation signal.
  final double meanHesitationMs;

  /// Current interaction speed vs this session's own baseline (1.0 = same,
  /// 0.4 = taking 2.5× longer than usual). <0.5 is the fatigue signal.
  final double tapSpeedRatio;

  final int sessionMinutes;

  /// SRS recall success over the recent review history (0..1); 1.0 when
  /// there is no history yet.
  final double retention;
  final int daysSinceLastSession;

  /// Cards currently due (Director may recommend review-first).
  final int dueLoad;

  final int hintsUsed;
  final int skips;

  /// Longest current same-pattern miss run (e.g. 3 misses on 'recognition').
  final int consecutiveMissesOnPattern;

  const SessionSignals({
    this.answers = 0,
    this.correct = 0,
    this.recentAnswers = 0,
    this.recentCorrect = 0,
    this.meanHesitationMs = 0,
    this.tapSpeedRatio = 1.0,
    this.sessionMinutes = 0,
    this.retention = 1.0,
    this.daysSinceLastSession = 0,
    this.dueLoad = 0,
    this.hintsUsed = 0,
    this.skips = 0,
    this.consecutiveMissesOnPattern = 0,
  });

  double get accuracy => answers == 0 ? 1.0 : correct / answers;
  double get recentAccuracy =>
      recentAnswers == 0 ? 1.0 : recentCorrect / recentAnswers;
  double get recentErrorRate => 1.0 - recentAccuracy;
}

/// The single state the UI consumes (04 §State bus contract). Immutable;
/// the AgentBus publishes a fresh one per tick.
class AgentState {
  final PsychState psych;

  /// Current difficulty recommendation, 1..10.
  final int difficulty;
  final String? recommendedLessonId;

  /// One-line Bengali rationale for the current recommendation —
  /// every decision is explainable (04).
  final String rationaleBn;
  final PersonaType persona;
  final ScaffoldOffer? scaffold;
  final SessionAdvice advice;

  const AgentState({
    this.psych = PsychState.calibrating,
    this.difficulty = 3,
    this.recommendedLessonId,
    this.rationaleBn = '',
    this.persona = PersonaType.didi,
    this.scaffold,
    this.advice = SessionAdvice.none,
  });

  AgentState copyWith({
    PsychState? psych,
    int? difficulty,
    String? recommendedLessonId,
    String? rationaleBn,
    PersonaType? persona,
    ScaffoldOffer? scaffold,
    bool clearScaffold = false,
    SessionAdvice? advice,
  }) =>
      AgentState(
        psych: psych ?? this.psych,
        difficulty: difficulty ?? this.difficulty,
        recommendedLessonId: recommendedLessonId ?? this.recommendedLessonId,
        rationaleBn: rationaleBn ?? this.rationaleBn,
        persona: persona ?? this.persona,
        scaffold: clearScaffold ? null : (scaffold ?? this.scaffold),
        advice: advice ?? this.advice,
      );
}

/// One explainability entry — kept in a ring buffer for the debug overlay
/// ("why did the app suggest that?").
class AgentLogEntry {
  final DateTime at;
  final String event; // e.g. 'psych: flow→struggle'
  final String rationaleBn;
  const AgentLogEntry(this.at, this.event, this.rationaleBn);

  @override
  String toString() => '[$at] $event — $rationaleBn';
}
