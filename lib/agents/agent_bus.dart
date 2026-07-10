// Agent bus (04 §State bus) — the single place raw interaction events become
// SessionSignals, the four agents run, and one merged AgentState is published
// for the UI. Riverpod StateNotifier; Director merges each tick (post-answer;
// the UI may also call tick() on a 30s timer).
//
// The bus is deliberately clock-injectable and DB-free so the whole session
// dynamic is unit-testable. Persistence (lesson completions, review history)
// stays in SrsLocal; the bus only sees derived numbers.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'agent_state.dart';
import 'director.dart';
import 'persona.dart';
import 'scaffold_agent.dart';

class AgentBus extends StateNotifier<AgentState> {
  AgentBus({DateTime Function()? clock, PersonaType persona = PersonaType.didi})
      : _now = clock ?? DateTime.now,
        super(AgentState(persona: persona));

  final DateTime Function() _now;

  // --- raw session accumulators (reset by startSession) ---------------------
  DateTime? _sessionStart;
  int _answers = 0, _correct = 0;
  final List<bool> _recent = <bool>[]; // sliding window, newest last
  static const _recentWindow = 10;
  double _hesitationEwma = 0;
  bool _hesitationSeeded = false;

  // Interaction tempo: EWMA of inter-event gaps; baseline = first 8 events.
  DateTime? _lastInteraction;
  final List<double> _baselineGaps = <double>[];
  static const _baselineCount = 8;
  double _gapEwma = 0;
  bool _gapSeeded = false;

  final Map<String, int> _missStreaks = <String, int>{};
  String? _lastMissPattern;
  int _hints = 0, _skips = 0;

  // SRS context (fed async by the caller once SrsLocal answers).
  double _retention = 1.0;
  int _daysSince = 0, _dueLoad = 0;

  // Session bookkeeping for the Feedback agent.
  final List<String> _learnedIds = <String>[];
  final Map<String, int> _missCounts = <String, int>{};

  // Explainability ring buffer (04: agent_log).
  final List<AgentLogEntry> _log = <AgentLogEntry>[];
  static const _logCap = 200;
  List<AgentLogEntry> get log => List.unmodifiable(_log);

  Map<String, int> get missCounts => Map.unmodifiable(_missCounts);
  List<String> get learnedIds => List.unmodifiable(_learnedIds);
  int get hintsUsed => _hints;
  int get skipsUsed => _skips;

  /// Begins a fresh session. Safe to call again mid-app (e.g. new lesson).
  void startSession() {
    _sessionStart = _now();
    _answers = 0;
    _correct = 0;
    _recent.clear();
    _hesitationEwma = 0;
    _hesitationSeeded = false;
    _lastInteraction = null;
    _baselineGaps.clear();
    _gapEwma = 0;
    _gapSeeded = false;
    _missStreaks.clear();
    _lastMissPattern = null;
    _hints = 0;
    _skips = 0;
    _learnedIds.clear();
    _missCounts.clear();
    _logEvent('session: start', 'নতুন সেশন শুরু।');
    tick();
  }

  /// SRS-derived context, fetched asynchronously by the caller (SrsLocal).
  void updateSrsContext(
      {double? retention, int? daysSinceLastSession, int? dueLoad}) {
    _retention = retention ?? _retention;
    _daysSince = daysSinceLastSession ?? _daysSince;
    _dueLoad = dueLoad ?? _dueLoad;
    tick();
  }

  /// A graded answer. [patternKey] groups misses ("recognition", "context",
  /// or a finer key) so the Scaffold agent can spot a stuck pattern.
  /// [hesitationMs] is time from prompt shown to this first interaction.
  void recordAnswer({
    required bool correct,
    required String patternKey,
    double? hesitationMs,
  }) {
    _touchTempo();
    _answers++;
    if (correct) {
      _correct++;
      _missStreaks[patternKey] = 0;
    } else {
      _missStreaks[patternKey] = (_missStreaks[patternKey] ?? 0) + 1;
      _lastMissPattern = patternKey;
      _missCounts[patternKey] = (_missCounts[patternKey] ?? 0) + 1;
    }
    _recent.add(correct);
    if (_recent.length > _recentWindow) _recent.removeAt(0);
    if (hesitationMs != null) {
      _hesitationEwma = _hesitationSeeded
          ? _hesitationEwma * 0.7 + hesitationMs * 0.3
          : hesitationMs;
      _hesitationSeeded = true;
    }
    tick();
  }

  /// A miss keyed to a concrete item (for the weak-list in the summary).
  void recordItemMiss(String itemId) {
    _missCounts[itemId] = (_missCounts[itemId] ?? 0) + 1;
  }

  /// An item was seeded into SRS this session (Feedback: "learned").
  void recordLearned(String itemId) {
    if (!_learnedIds.contains(itemId)) _learnedIds.add(itemId);
  }

  void recordHint() {
    _touchTempo();
    _hints++;
    tick();
  }

  /// Skipping is a first-class, penalty-free action — recorded only so the
  /// Director can pace, never to punish.
  void recordSkip() {
    _touchTempo();
    _skips++;
    tick();
  }

  /// Any non-answer interaction (taps, toggles) — feeds the tempo baseline.
  void recordInteraction() {
    _touchTempo();
  }

  void setPersona(PersonaType p) {
    if (p == state.persona) return;
    _logEvent('persona: ${state.persona.name}→${p.name}',
        'তুমি টিউটর বদলেছ — এখন ${personaNameBn(p)}।');
    state = state.copyWith(persona: p);
  }

  /// The learner dismissed the current scaffold offer — respect it silently.
  void dismissScaffold() {
    if (state.scaffold == null) return;
    // Reset the triggering streak so the same offer doesn't nag next tick.
    final p = _lastMissPattern;
    if (p != null) _missStreaks[p] = 0;
    _hesitationEwma = 0;
    _hesitationSeeded = false;
    state = state.copyWith(clearScaffold: true);
  }

  /// Re-runs all agents over the current signals and publishes the merge.
  /// Called after every recorded event; the UI may also call it periodically.
  void tick() {
    final s = _signals();
    final d = directorDecide(s, currentDifficulty: state.difficulty);
    final offer = scaffoldCheck(s);
    if (d.psych != state.psych) {
      _logEvent('psych: ${state.psych.name}→${d.psych.name}', d.rationaleBn);
    }
    if (offer != null && offer.kind != state.scaffold?.kind) {
      _logEvent('scaffold: offer ${offer.kind.name}', offer.promptBn);
    }
    state = AgentState(
      psych: d.psych,
      difficulty: d.difficulty,
      recommendedLessonId: state.recommendedLessonId,
      rationaleBn: d.rationaleBn,
      persona: state.persona,
      scaffold: offer,
      advice: d.advice,
    );
  }

  /// Line for the learner's current moment, in their chosen persona's voice.
  String personaSay(PersonaEvent event) => personaLine(
        state.persona,
        event,
        psych: state.psych,
        rotation: _answers,
      );

  SessionSignals _signals() {
    final started = _sessionStart;
    final minutes =
        started == null ? 0 : _now().difference(started).inMinutes;
    return SessionSignals(
      answers: _answers,
      correct: _correct,
      recentAnswers: _recent.length,
      recentCorrect: _recent.where((r) => r).length,
      meanHesitationMs: _hesitationEwma,
      tapSpeedRatio: _tapSpeedRatio(),
      sessionMinutes: minutes,
      retention: _retention,
      daysSinceLastSession: _daysSince,
      dueLoad: _dueLoad,
      hintsUsed: _hints,
      skips: _skips,
      consecutiveMissesOnPattern: _missStreaks.values
          .fold(0, (max, v) => v > max ? v : max),
    );
  }

  void _touchTempo() {
    final now = _now();
    final last = _lastInteraction;
    _lastInteraction = now;
    if (last == null) return;
    final gap = now.difference(last).inMilliseconds.toDouble();
    // Ignore idle pauses (>60s): walking away is not "slow tapping".
    if (gap > 60000) return;
    if (_baselineGaps.length < _baselineCount) _baselineGaps.add(gap);
    _gapEwma = _gapSeeded ? _gapEwma * 0.7 + gap * 0.3 : gap;
    _gapSeeded = true;
  }

  double _tapSpeedRatio() {
    if (_baselineGaps.length < _baselineCount || _gapEwma <= 0) return 1.0;
    final baseline =
        _baselineGaps.reduce((a, b) => a + b) / _baselineGaps.length;
    if (baseline <= 0) return 1.0;
    // speed ∝ 1/gap: current speed relative to the session's own baseline.
    return baseline / _gapEwma;
  }

  void _logEvent(String event, String rationaleBn) {
    _log.add(AgentLogEntry(_now(), event, rationaleBn));
    if (_log.length > _logCap) _log.removeAt(0);
  }
}
