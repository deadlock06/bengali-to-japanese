// Agent-system tests (04): Director decision table, Scaffold offers, Persona
// determinism + softening, Feedback fixed-reward schedule, and full AgentBus
// session dynamics with an injected clock. Mirrors tools/agents_reference.mjs.

import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/agents/agent_bus.dart';
import 'package:sensei_app/agents/agent_state.dart';
import 'package:sensei_app/agents/director.dart';
import 'package:sensei_app/agents/feedback.dart';
import 'package:sensei_app/agents/persona.dart';
import 'package:sensei_app/agents/scaffold_agent.dart';

void main() {
  group('Director', () {
    test('too few answers → calibrating', () {
      final d = directorDecide(const SessionSignals(answers: 3, correct: 1));
      expect(d.psych, PsychState.calibrating);
    });

    test('session-start rusty rule: low retention after days away → struggle',
        () {
      final d = directorDecide(const SessionSignals(
          answers: 0, retention: 0.5, daysSinceLastSession: 4));
      expect(d.psych, PsychState.struggle);
      expect(d.rationaleBn, 'আগে একটু ঝালাই করি।');
    });

    test('recent accuracy < 60% → struggle, difficulty −1', () {
      final d = directorDecide(
        const SessionSignals(
            answers: 10, correct: 5, recentAnswers: 10, recentCorrect: 5),
        currentDifficulty: 5,
      );
      expect(d.psych, PsychState.struggle);
      expect(d.difficulty, 4);
    });

    test('accuracy > 90% after 20 min → boredom, difficulty +1', () {
      final d = directorDecide(
        const SessionSignals(
            answers: 20,
            correct: 19,
            recentAnswers: 10,
            recentCorrect: 10,
            sessionMinutes: 25),
        currentDifficulty: 5,
      );
      expect(d.psych, PsychState.boredom);
      expect(d.difficulty, 6);
    });

    test('high accuracy early in the session is flow, not boredom', () {
      final d = directorDecide(const SessionSignals(
          answers: 8,
          correct: 8,
          recentAnswers: 8,
          recentCorrect: 8,
          sessionMinutes: 10));
      expect(d.psych, PsychState.flow);
    });

    test('collapsed tap speed + errors → burnout, difficulty −2, break advice',
        () {
      final d = directorDecide(
        const SessionSignals(
            answers: 12,
            correct: 7,
            recentAnswers: 10,
            recentCorrect: 6,
            tapSpeedRatio: 0.4),
        currentDifficulty: 5,
      );
      expect(d.psych, PsychState.burnout);
      expect(d.difficulty, 3);
      expect(d.advice.kind, AdviceKind.shortBreak);
      expect(d.advice.breakMinutes, 5);
    });

    test('errors after 40+ minutes also read as fatigue', () {
      final d = directorDecide(const SessionSignals(
          answers: 30,
          correct: 18,
          recentAnswers: 10,
          recentCorrect: 6,
          sessionMinutes: 45));
      expect(d.psych, PsychState.burnout);
    });

    test('flow band holds difficulty', () {
      final d = directorDecide(
        const SessionSignals(
            answers: 10, correct: 8, recentAnswers: 10, recentCorrect: 8),
        currentDifficulty: 5,
      );
      expect(d.psych, PsychState.flow);
      expect(d.difficulty, 5);
      expect(d.advice.kind, AdviceKind.continueSession);
    });

    test('difficulty clamps to [1,10]', () {
      final low = directorDecide(
        const SessionSignals(
            answers: 10,
            correct: 5,
            recentAnswers: 10,
            recentCorrect: 5,
            tapSpeedRatio: 0.3),
        currentDifficulty: 1,
      );
      expect(low.difficulty, 1);
      final high = directorDecide(
        const SessionSignals(
            answers: 30,
            correct: 30,
            recentAnswers: 10,
            recentCorrect: 10,
            sessionMinutes: 30),
        currentDifficulty: 10,
      );
      expect(high.difficulty, 10);
    });

    test('120-minute soft cap → easy-review-only recommendation', () {
      final d = directorDecide(const SessionSignals(
          answers: 50,
          correct: 40,
          recentAnswers: 10,
          recentCorrect: 8,
          sessionMinutes: 121));
      expect(d.advice.kind, AdviceKind.easyReviewOnly);
      // The copy itself must keep continuing possible (never force).
      expect(d.advice.messageBn, contains('চালিয়ে'));
    });

    test('every state carries a non-empty Bengali rationale', () {
      for (final s in [
        const SessionSignals(),
        const SessionSignals(answers: 10, correct: 4, recentAnswers: 10, recentCorrect: 4),
        const SessionSignals(answers: 10, correct: 8, recentAnswers: 10, recentCorrect: 8),
        const SessionSignals(
            answers: 30, correct: 29, recentAnswers: 10, recentCorrect: 10, sessionMinutes: 30),
        const SessionSignals(
            answers: 10, correct: 6, recentAnswers: 10, recentCorrect: 6, tapSpeedRatio: 0.2),
      ]) {
        expect(directorDecide(s).rationaleBn, isNotEmpty);
      }
    });
  });

  group('Scaffold', () {
    test('3+ misses on one pattern → review-switch offer', () {
      final o = scaffoldCheck(
          const SessionSignals(consecutiveMissesOnPattern: 3));
      expect(o?.kind, ScaffoldKind.reviewSwitch);
    });

    test('hesitation > 3s → hint offer, phrased as a question', () {
      final o = scaffoldCheck(const SessionSignals(meanHesitationMs: 3200));
      expect(o?.kind, ScaffoldKind.hint);
      expect(o!.promptBn, endsWith('?'));
    });

    test('miss streak outranks hesitation', () {
      final o = scaffoldCheck(const SessionSignals(
          consecutiveMissesOnPattern: 3, meanHesitationMs: 5000));
      expect(o?.kind, ScaffoldKind.reviewSwitch);
    });

    test('frantic tapping with errors → help offer', () {
      final o = scaffoldCheck(const SessionSignals(
          tapSpeedRatio: 3.0,
          answers: 10,
          correct: 4,
          recentAnswers: 10,
          recentCorrect: 4));
      expect(o?.kind, ScaffoldKind.helpOffer);
    });

    test('no confusion signal → no offer', () {
      expect(scaffoldCheck(const SessionSignals()), isNull);
    });
  });

  group('Persona', () {
    test('deterministic: same inputs, same line', () {
      final a = personaLine(PersonaType.didi, PersonaEvent.correctAnswer,
          rotation: 4, psych: PsychState.flow);
      final b = personaLine(PersonaType.didi, PersonaEvent.correctAnswer,
          rotation: 4, psych: PsychState.flow);
      expect(a, b);
    });

    test('rotation cycles a fixed set (no variable-reward feel)', () {
      final seen = <String>{};
      for (var i = 0; i < 12; i++) {
        seen.add(personaLine(PersonaType.friend, PersonaEvent.correctAnswer,
            rotation: i, psych: PsychState.flow));
      }
      final cycle = seen.length;
      expect(cycle, greaterThan(1));
      // The 13th line repeats the cycle exactly.
      expect(
          personaLine(PersonaType.friend, PersonaEvent.correctAnswer,
              rotation: 12, psych: PsychState.flow),
          personaLine(PersonaType.friend, PersonaEvent.correctAnswer,
              rotation: 12 % cycle, psych: PsychState.flow));
    });

    test('every persona softens on struggle (anxiety → reduce intensity)', () {
      for (final p in PersonaType.values) {
        final normal = personaLine(p, PersonaEvent.wrongAnswer,
            psych: PsychState.flow, rotation: 0);
        final gentle = personaLine(p, PersonaEvent.wrongAnswer,
            psych: PsychState.struggle, rotation: 0);
        expect(gentle, isNot(normal),
            reason: '${p.name} must change tone when the learner struggles');
      }
    });

    test('personas have distinct voices', () {
      final lines = PersonaType.values
          .map((p) => personaLine(p, PersonaEvent.correctAnswer,
              psych: PsychState.flow, rotation: 0))
          .toSet();
      expect(lines.length, PersonaType.values.length);
    });

    test('all lines are non-empty for every event/state combination', () {
      for (final p in PersonaType.values) {
        for (final e in PersonaEvent.values) {
          for (final st in PsychState.values) {
            for (var r = 0; r < 4; r++) {
              expect(
                  personaLine(p, e, psych: st, rotation: r, weekNumber: 1),
                  isNotEmpty);
              expect(
                  personaLine(p, e,
                      psych: st, rotation: r, weekNumber: 20, casualOptIn: true),
                  isNotEmpty);
            }
          }
        }
      }
    });
  });

  group('Feedback (fixed reward schedule)', () {
    test('XP is a fixed multiple of lessons — never anything else', () {
      expect(const MasteryStats(lessonsCompleted: 0, wordsRetained: 0).xp, 0);
      expect(const MasteryStats(lessonsCompleted: 7, wordsRetained: 0).xp, 70);
    });

    test('milestone exactly every 10 lessons', () {
      expect(milestoneReached(9), isFalse);
      expect(milestoneReached(10), isTrue);
      expect(milestoneReached(11), isFalse);
      expect(milestoneReached(20), isTrue);
    });

    test('level rises exactly every 50 retained words', () {
      expect(levelUp(49, 50), isTrue);
      expect(levelUp(50, 51), isFalse);
      expect(levelUp(100, 149), isFalse);
      expect(levelUp(99, 150), isTrue);
      expect(
          const MasteryStats(lessonsCompleted: 0, wordsRetained: 120).level, 2);
    });

    test('exam readiness is retained/target, clamped', () {
      expect(
          const MasteryStats(lessonsCompleted: 0, wordsRetained: 600)
              .examReadiness,
          closeTo(0.5, 1e-9));
      expect(
          const MasteryStats(lessonsCompleted: 0, wordsRetained: 5000)
              .examReadiness,
          1.0);
    });

    test('session summary: weak = missed twice+, neutral copy when empty', () {
      final s = buildSessionSummary(
        learnedIds: ['a', 'b'],
        missCounts: {'a': 1, 'c': 2, 'd': 3},
        dueTomorrow: 4,
        lessonsCompletedBefore: 9,
        lessonsCompletedNow: 10,
        wordsRetainedBefore: 49,
        wordsRetainedNow: 50,
      );
      expect(s.weakIds, unorderedEquals(['c', 'd']));
      expect(s.xpEarned, RewardSchedule.xpPerLesson);
      expect(s.milestone, isTrue);
      expect(s.leveledUp, isTrue);
      expect(s.lineBn, isNotEmpty);

      final empty = buildSessionSummary(
        learnedIds: const [],
        missCounts: const {},
        dueTomorrow: 0,
        lessonsCompletedBefore: 0,
        lessonsCompletedNow: 0,
        wordsRetainedBefore: 0,
        wordsRetainedNow: 0,
      );
      expect(empty.lineBn, 'আজ ঘুরে দেখলে — সেটাও শেখা।');
    });
  });

  group('AgentBus (session dynamics, fake clock)', () {
    late DateTime now;
    late AgentBus bus;

    setUp(() {
      now = DateTime(2026, 7, 10, 9, 0);
      bus = AgentBus(clock: () => now);
      bus.startSession();
    });

    void tickClock(Duration d) => now = now.add(d);

    test('fresh session starts calibrating', () {
      expect(bus.state.psych, PsychState.calibrating);
    });

    test('sustained correct answers reach flow', () {
      for (var i = 0; i < 8; i++) {
        tickClock(const Duration(seconds: 5));
        bus.recordAnswer(correct: i != 2, patternKey: 'recognition');
      }
      expect(bus.state.psych, PsychState.flow);
    });

    test('a same-pattern miss streak surfaces a scaffold offer + struggle',
        () {
      for (var i = 0; i < 5; i++) {
        tickClock(const Duration(seconds: 5));
        bus.recordAnswer(correct: false, patternKey: 'context');
      }
      expect(bus.state.psych, PsychState.struggle);
      expect(bus.state.scaffold?.kind, ScaffoldKind.reviewSwitch);
    });

    test('dismissing a scaffold offer clears it and resets the streak', () {
      for (var i = 0; i < 4; i++) {
        tickClock(const Duration(seconds: 5));
        bus.recordAnswer(correct: false, patternKey: 'context');
      }
      expect(bus.state.scaffold, isNotNull);
      bus.dismissScaffold();
      expect(bus.state.scaffold, isNull);
      // One more miss is NOT enough to re-trigger (streak was reset).
      tickClock(const Duration(seconds: 5));
      bus.recordAnswer(correct: true, patternKey: 'recognition');
      expect(bus.state.scaffold, isNull);
    });

    test('slowing taps + errors drive burnout with a break recommendation',
        () {
      // Establish a brisk baseline tempo (8 gaps at 2s), mostly correct.
      for (var i = 0; i < 9; i++) {
        tickClock(const Duration(seconds: 2));
        bus.recordAnswer(correct: true, patternKey: 'recognition');
      }
      // Then: everything slows to 5× and answers go wrong.
      for (var i = 0; i < 8; i++) {
        tickClock(const Duration(seconds: 10));
        bus.recordAnswer(correct: false, patternKey: 'recognition');
      }
      expect(bus.state.psych, PsychState.burnout);
      expect(bus.state.advice.kind, AdviceKind.shortBreak);
    });

    test('120 minutes triggers the easy-review-only soft cap', () {
      for (var i = 0; i < 6; i++) {
        tickClock(const Duration(seconds: 5));
        bus.recordAnswer(correct: true, patternKey: 'recognition');
      }
      tickClock(const Duration(minutes: 121));
      bus.tick();
      expect(bus.state.advice.kind, AdviceKind.easyReviewOnly);
    });

    test('rusty SRS context flips a fresh session to gentle review mode', () {
      bus.updateSrsContext(retention: 0.4, daysSinceLastSession: 6);
      expect(bus.state.psych, PsychState.struggle);
      expect(bus.state.rationaleBn, 'আগে একটু ঝালাই করি।');
    });

    test('psych transitions are logged for explainability', () {
      for (var i = 0; i < 8; i++) {
        tickClock(const Duration(seconds: 5));
        bus.recordAnswer(correct: false, patternKey: 'context');
      }
      expect(
          bus.log.any((e) => e.event.contains('struggle')), isTrue);
      expect(bus.log.every((e) => e.rationaleBn.isNotEmpty), isTrue);
    });

    test('persona switching is learner-driven and logged, never automatic',
        () {
      expect(bus.state.persona, PersonaType.didi);
      // Nothing in a whole stormy session may auto-switch the persona.
      for (var i = 0; i < 15; i++) {
        tickClock(const Duration(seconds: 8));
        bus.recordAnswer(correct: i.isEven, patternKey: 'recognition');
      }
      expect(bus.state.persona, PersonaType.didi);
      bus.setPersona(PersonaType.coach);
      expect(bus.state.persona, PersonaType.coach);
      expect(bus.log.any((e) => e.event.startsWith('persona:')), isTrue);
    });

    test('idle pauses (>60s) never count as slow tapping', () {
      for (var i = 0; i < 9; i++) {
        tickClock(const Duration(seconds: 2));
        bus.recordAnswer(correct: true, patternKey: 'recognition');
      }
      // A tea break…
      tickClock(const Duration(minutes: 5));
      bus.recordAnswer(correct: true, patternKey: 'recognition');
      expect(bus.state.psych, isNot(PsychState.burnout));
    });
  });
}
