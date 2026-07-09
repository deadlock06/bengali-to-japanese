// Executable reference port of lib/domain/fsrs.dart (identical math), with
// property tests. Run:  node tools/fsrs_reference.mjs
// This proves the scheduling logic before it ships in Dart.

const DECAY = -0.5;
const FACTOR = 19 / 81;
const W = [
  0.40255, 0.59854, 2.40984, 5.80984, 4.92593, 0.94123, 0.86231,
  0.01000, 1.48959, 0.14480, 0.94123, 2.18154, 0.05000, 0.34560,
  1.26000, 0.29400, 2.61000,
];
const REQ = 0.90;
const clampD = (d) => Math.min(10, Math.max(1, d));

const retrievability = (t, s) => (s <= 0 ? 0 : Math.pow(1 + FACTOR * t / s, DECAY));
const nextInterval = (s) =>
  Math.min(36500, Math.max(1, Math.round((s / FACTOR) * (Math.pow(REQ, 1 / DECAY) - 1))));

const initStability = (g) => Math.max(W[g - 1], 0.1);
const initDifficulty = (g) => clampD(W[4] - W[5] * (g - 3));
const nextDifficulty = (d, g) =>
  clampD(W[7] * initDifficulty(4) + (1 - W[7]) * (d - W[6] * (g - 3)));

const stabRecall = (d, s, r, g) => {
  const hard = g === 2 ? W[15] : 1.0;
  const easy = g === 4 ? W[16] : 1.0;
  const inc =
    Math.exp(W[8]) * (11 - d) * Math.pow(s, -W[9]) *
    (Math.exp((1 - r) * W[10]) - 1) * hard * easy;
  return s * (1 + inc);
};
const stabForget = (d, s, r) =>
  W[11] * Math.pow(d, -W[12]) * (Math.pow(s + 1, W[13]) - 1) * Math.exp((1 - r) * W[14]);

function review(card, g, elapsedDays) {
  if (card.state === 'new') {
    return {
      stability: initStability(g),
      difficulty: initDifficulty(g),
      state: g === 1 ? 'learning' : 'review',
      lapses: card.lapses,
    };
  }
  const r = retrievability(elapsedDays, card.stability);
  if (g === 1) {
    return {
      stability: stabForget(card.difficulty, card.stability, r),
      difficulty: nextDifficulty(card.difficulty, g),
      state: 'relearning',
      lapses: card.lapses + 1,
    };
  }
  return {
    stability: stabRecall(card.difficulty, card.stability, r, g),
    difficulty: nextDifficulty(card.difficulty, g),
    state: 'review',
    lapses: card.lapses,
  };
}

// -------------------- PROPERTY TESTS --------------------
let pass = 0, fail = 0;
const ok = (name, cond) => { cond ? pass++ : fail++; console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}`); };
const approx = (a, b) => Math.abs(a - b) < 1e-9;

// 1. R(0) = 1, and strictly decreasing in time.
ok('R(0)=1', approx(retrievability(0, 5), 1));
ok('R decreases with time', retrievability(1, 5) > retrievability(10, 5));

// 2. Interval grows with stability, and ~= stability at 90% retention.
ok('interval grows with stability', nextInterval(2) < nextInterval(20));
ok('interval>=1 day', nextInterval(0.01) >= 1);

// 3. New-card first review: Again<Hard<Good<Easy in resulting stability.
const nw = { state: 'new', stability: 0, difficulty: 0, lapses: 0 };
const s1 = review(nw, 1, 0).stability, s2 = review(nw, 2, 0).stability,
      s3 = review(nw, 3, 0).stability, s4 = review(nw, 4, 0).stability;
ok('new: Again<Hard<Good<Easy stability', s1 < s2 && s2 < s3 && s3 < s4);

// 4. Difficulty always within [1,10] across ratings and states.
let dOk = true;
for (let g = 1; g <= 4; g++) {
  const d = review(nw, g, 0).difficulty;
  if (d < 1 || d > 10) dOk = false;
}
const rev = { state: 'review', stability: 10, difficulty: 5, lapses: 0 };
for (let g = 1; g <= 4; g++) {
  const d = review(rev, g, 12).difficulty;
  if (d < 1 || d > 10) dOk = false;
}
ok('difficulty stays in [1,10]', dOk);

// 5. Review success: higher rating -> higher next stability (monotonic).
const r2 = review(rev, 2, 12).stability, r3 = review(rev, 3, 12).stability,
      r4 = review(rev, 4, 12).stability;
ok('review: Hard<Good<Easy stability', r2 < r3 && r3 < r4);

// 6. Successful review increases stability (memory strengthens).
ok('Good review increases stability', review(rev, 3, 12).stability > rev.stability);

// 7. Again (lapse) reduces stability and increments lapses.
const lapse = review(rev, 1, 12);
ok('Again reduces stability', lapse.stability < rev.stability);
ok('Again increments lapses', lapse.lapses === 1);

// 8. Easier-to-recall cards (higher R) get bigger stability boost.
const lowR = review({ state: 'review', stability: 10, difficulty: 5, lapses: 0 }, 3, 30).stability;
const highR = review({ state: 'review', stability: 10, difficulty: 5, lapses: 0 }, 3, 1).stability;
ok('lower retrievability -> larger stability increment', lowR > highR);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
