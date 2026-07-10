// Agents reference proof — a 1:1 JS port of the Director decision function
// (lib/agents/director.dart) and Scaffold check (lib/agents/scaffold_agent.dart)
// asserted against the same decision table as test/agents_test.dart. Runs in
// CI's Node job so agent logic is proven even without a Flutter toolchain.
//
// If this file and the Dart disagree, the Dart tests are the source of truth —
// update BOTH when a threshold changes (they share the 04_AGENTS rule table).

// --- thresholds (must equal DirectorRules / ScaffoldRules in Dart) ----------
const R = {
  minAnswers: 4,
  struggleAccuracy: 0.60,
  rustyRetention: 0.60,
  rustyDaysAway: 3,
  boredomAccuracy: 0.90,
  boredomMinutes: 20,
  burnoutTapSpeed: 0.50,
  burnoutErrorRate: 0.30,
  fatigueMinutes: 40,
  hardCapMinutes: 120,
  breakSuggestMinutes: 20,
  minDifficulty: 1,
  maxDifficulty: 10,
};
const S = { hesitationMs: 3000, missStreak: 3, rapidTapSpeed: 2.5, rapidErrorRate: 0.50 };

const sig = (o = {}) => ({
  answers: 0, correct: 0, recentAnswers: 0, recentCorrect: 0,
  meanHesitationMs: 0, tapSpeedRatio: 1.0, sessionMinutes: 0,
  retention: 1.0, daysSinceLastSession: 0, dueLoad: 0,
  hintsUsed: 0, skips: 0, consecutiveMissesOnPattern: 0, ...o,
});
const recentAccuracy = (s) => (s.recentAnswers === 0 ? 1.0 : s.recentCorrect / s.recentAnswers);
const recentErrorRate = (s) => 1.0 - recentAccuracy(s);

function classify(s) {
  if (s.answers < R.minAnswers) {
    const rusty = s.retention < R.rustyRetention && s.daysSinceLastSession > R.rustyDaysAway;
    return rusty ? 'struggle' : 'calibrating';
  }
  const fatigued = recentErrorRate(s) > R.burnoutErrorRate &&
    (s.tapSpeedRatio < R.burnoutTapSpeed || s.sessionMinutes >= R.fatigueMinutes);
  if (fatigued) return 'burnout';
  if (recentAccuracy(s) < R.struggleAccuracy) return 'struggle';
  if (recentAccuracy(s) > R.boredomAccuracy && s.sessionMinutes > R.boredomMinutes) return 'boredom';
  return 'flow';
}

function adjustDifficulty(psych, s, current) {
  const delta = {
    calibrating: 0,
    flow: recentAccuracy(s) >= R.boredomAccuracy ? 1 : 0,
    boredom: 1,
    struggle: -1,
    burnout: -2,
  }[psych];
  return Math.min(R.maxDifficulty, Math.max(R.minDifficulty, current + delta));
}

function advise(psych, s) {
  if (s.sessionMinutes >= R.hardCapMinutes) return 'easyReviewOnly';
  if (psych === 'burnout') return 'shortBreak';
  if (s.sessionMinutes >= R.breakSuggestMinutes && psych !== 'flow') return 'shortBreak';
  return 'continueSession';
}

const decide = (s, current = 3) => {
  const psych = classify(s);
  return { psych, difficulty: adjustDifficulty(psych, s, current), advice: advise(psych, s) };
};

function scaffoldCheck(s) {
  if (s.consecutiveMissesOnPattern >= S.missStreak) return 'reviewSwitch';
  if (s.meanHesitationMs > S.hesitationMs) return 'hint';
  if (s.tapSpeedRatio > S.rapidTapSpeed && recentErrorRate(s) > S.rapidErrorRate) return 'helpOffer';
  return null;
}

// --- decision table (mirrors test/agents_test.dart) --------------------------
let pass = 0, fail = 0;
const ok = (name, cond) => {
  if (cond) { pass++; } else { fail++; console.error(`FAIL: ${name}`); }
};

// Director
ok('calibrating below min answers', decide(sig({ answers: 3, correct: 1 })).psych === 'calibrating');
ok('rusty return → struggle', decide(sig({ retention: 0.5, daysSinceLastSession: 4 })).psych === 'struggle');
{
  const d = decide(sig({ answers: 10, correct: 5, recentAnswers: 10, recentCorrect: 5 }), 5);
  ok('accuracy<60% → struggle, −1', d.psych === 'struggle' && d.difficulty === 4);
}
{
  const d = decide(sig({ answers: 20, correct: 19, recentAnswers: 10, recentCorrect: 10, sessionMinutes: 25 }), 5);
  ok('acc>90% after 20min → boredom, +1', d.psych === 'boredom' && d.difficulty === 6);
}
ok('high accuracy early = flow, not boredom',
  decide(sig({ answers: 8, correct: 8, recentAnswers: 8, recentCorrect: 8, sessionMinutes: 10 })).psych === 'flow');
{
  const d = decide(sig({ answers: 12, correct: 7, recentAnswers: 10, recentCorrect: 6, tapSpeedRatio: 0.4 }), 5);
  ok('slow taps + errors → burnout, −2, break', d.psych === 'burnout' && d.difficulty === 3 && d.advice === 'shortBreak');
}
ok('errors after 40min → burnout',
  decide(sig({ answers: 30, correct: 18, recentAnswers: 10, recentCorrect: 6, sessionMinutes: 45 })).psych === 'burnout');
{
  const d = decide(sig({ answers: 10, correct: 8, recentAnswers: 10, recentCorrect: 8 }), 5);
  ok('flow band holds difficulty', d.psych === 'flow' && d.difficulty === 5 && d.advice === 'continueSession');
}
ok('difficulty floor 1',
  decide(sig({ answers: 10, correct: 5, recentAnswers: 10, recentCorrect: 5, tapSpeedRatio: 0.3 }), 1).difficulty === 1);
ok('difficulty ceiling 10',
  decide(sig({ answers: 30, correct: 30, recentAnswers: 10, recentCorrect: 10, sessionMinutes: 30 }), 10).difficulty === 10);
ok('120-min soft cap → easyReviewOnly',
  decide(sig({ answers: 50, correct: 40, recentAnswers: 10, recentCorrect: 8, sessionMinutes: 121 })).advice === 'easyReviewOnly');

// Scaffold
ok('3 misses → reviewSwitch', scaffoldCheck(sig({ consecutiveMissesOnPattern: 3 })) === 'reviewSwitch');
ok('hesitation > 3s → hint', scaffoldCheck(sig({ meanHesitationMs: 3200 })) === 'hint');
ok('miss streak outranks hesitation',
  scaffoldCheck(sig({ consecutiveMissesOnPattern: 3, meanHesitationMs: 5000 })) === 'reviewSwitch');
ok('frantic wrong tapping → helpOffer',
  scaffoldCheck(sig({ tapSpeedRatio: 3.0, recentAnswers: 10, recentCorrect: 4 })) === 'helpOffer');
ok('calm → no offer', scaffoldCheck(sig()) === null);

// Invariants: no signal combination may ever remove the learner's agency —
// structurally, advice is one of a fixed recommendation set (no "lock" state).
const adviceKinds = new Set(['continueSession', 'shortBreak', 'easyReviewOnly', 'endSession']);
{
  let allKnown = true;
  for (const answers of [0, 5, 20]) {
    for (const correctRate of [0.2, 0.7, 1.0]) {
      for (const minutes of [0, 25, 45, 130]) {
        for (const tap of [0.3, 1.0, 3.0]) {
          const s = sig({
            answers, correct: Math.round(answers * correctRate),
            recentAnswers: Math.min(answers, 10),
            recentCorrect: Math.round(Math.min(answers, 10) * correctRate),
            sessionMinutes: minutes, tapSpeedRatio: tap,
          });
          if (!adviceKinds.has(decide(s).advice)) allKnown = false;
        }
      }
    }
  }
  ok('every advice is a recommendation from the fixed set (no lock states)', allKnown);
}

console.log(`\n${pass}/${pass + fail} passed`);
process.exit(fail ? 1 : 0);
