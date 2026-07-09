// Runnable proof for the lesson micro-loop state machine (LessonScreen._advance).
// The autonomy invariant needs: Skip/Next ALWAYS progresses (never blocks, never
// penalizes) and the loop ALWAYS terminates. Mirrors _advance/_quit exactly, with
// no Flutter SDK. Run: node tools/lesson_flow_reference.mjs

const PHASES = ['intro', 'recognition', 'production', 'context', 'srs']; // 09 §micro-loop

// port of _advance(itemCount) — Skip and Next both call this (identical path)
function advance(s, itemCount) {
  if (s.phase < PHASES.length - 1) return { ...s, phase: s.phase + 1 };
  if (s.item < itemCount - 1) return { ...s, item: s.item + 1, phase: 0 };
  return { ...s, started: false, done: true };
}
// port of _quit()
const quit = () => ({ item: 0, phase: 0, started: false, done: false });
const start = () => ({ item: 0, phase: 0, started: true, done: false });

let pass = 0, fail = 0;
const ok = (label, cond) => { console.log((cond ? 'ok   ' : 'FAIL ') + label); cond ? pass++ : fail++; };

// 1. A 2-item lesson visits all 5 phases of item 0, then all 5 of item 1, then done.
{
  const n = 2;
  let s = start();
  const seen = [];
  let guard = 0;
  while (s.started && guard++ < 100) {
    seen.push(s.item + ':' + PHASES[s.phase]);
    s = advance(s, n); // simulate tapping Next/Skip every step
  }
  const want = [
    '0:intro', '0:recognition', '0:production', '0:context', '0:srs',
    '1:intro', '1:recognition', '1:production', '1:context', '1:srs',
  ];
  ok('visits every phase of every item in order', JSON.stringify(seen) === JSON.stringify(want));
  ok('loop terminates (done=true, started=false)', s.done && !s.started);
}

// 2. Skip has the SAME effect as Next — it always moves forward, from any step.
{
  const n = 3;
  for (let item = 0; item < n; item++) {
    for (let phase = 0; phase < PHASES.length; phase++) {
      const before = { item, phase, started: true, done: false };
      const after = advance(before, n); // "Skip"
      const progressed = after.done ||
        after.item > before.item ||
        (after.item === before.item && after.phase > before.phase);
      ok(`skip progresses from ${item}:${PHASES[phase]}`, progressed);
    }
  }
}

// 3. Quit always returns to a clean overview (no penalty state carried).
{
  const s = quit();
  ok('quit resets to overview', !s.started && !s.done && s.item === 0 && s.phase === 0);
}

// 4. A 1-item lesson still runs all 5 phases then completes (no under/overflow).
{
  let s = start();
  let steps = 0, guard = 0;
  while (s.started && guard++ < 100) { steps++; s = advance(s, 1); }
  ok('single-item lesson runs exactly 5 steps then done', steps === 5 && s.done);
}

console.log(`\n${pass}/${pass + fail} passed`);
process.exit(fail ? 1 : 0);
