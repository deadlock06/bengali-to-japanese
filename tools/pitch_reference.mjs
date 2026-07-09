// Executable mirror of lib/domain/pitch.dart, with tests on synthetic signals.
// Run: node tools/pitch_reference.mjs
const SR = 16000;

function estimateF0(buf, sampleRate, minHz = 70, maxHz = 500) {
  const n = buf.length;
  let rms = 0; for (const s of buf) rms += s * s; rms = Math.sqrt(rms / n);
  if (rms < 0.01) return -1;
  const minLag = Math.floor(sampleRate / maxHz);
  const maxLag = Math.min(n - 1, Math.ceil(sampleRate / minHz));
  const c = new Array(maxLag + 2).fill(0);
  let best = 0, bestLag = -1;
  for (let lag = minLag; lag <= maxLag; lag++) {
    let sum = 0; for (let i = 0; i < n - lag; i++) sum += buf[i] * buf[i + lag];
    c[lag] = sum;
    if (sum > best) { best = sum; bestLag = lag; }
  }
  if (bestLag <= 0) return -1;
  let refined = bestLag;
  if (bestLag > minLag && bestLag < maxLag) {
    const a = c[bestLag - 1], b = c[bestLag], g = c[bestLag + 1];
    const denom = a - 2 * b + g;
    if (Math.abs(denom) > 1e-9) refined = bestLag + 0.5 * (a - g) / denom;
  }
  const f = sampleRate / refined;
  return (f >= minHz && f <= maxHz) ? f : -1;
}
function toShape(contour) {
  const voiced = contour.filter((f) => f > 0);
  if (!voiced.length) return contour.map(() => null);
  const mean = voiced.reduce((a, b) => a + b, 0) / voiced.length;
  return contour.map((f) => (f > 0 ? 12 * Math.log2(f / mean) : null));
}
function resample(xs, len) {
  if (!xs.length) return Array(len).fill(null);
  return Array.from({ length: len }, (_, i) => xs[Math.min(xs.length - 1, Math.floor(i * xs.length / len))]);
}
function accentScore(reference, learner) {
  const r = toShape(reference), l = toShape(learner);
  const len = Math.max(r.length, l.length);
  const rr = resample(r, len), ll = resample(l, len);
  let err = 0, count = 0;
  for (let i = 0; i < len; i++) { if (rr[i] == null || ll[i] == null) continue; err += Math.abs(rr[i] - ll[i]); count++; }
  if (!count) return 0;
  return Math.max(0, Math.min(100, 100 * (1 - (err / count) / 6)));
}
const sine = (hz, ms, sr = SR) => Array.from({ length: Math.round(sr * ms / 1000) }, (_, i) => Math.sin(2 * Math.PI * hz * i / sr));

let pass = 0, fail = 0;
const ok = (name, cond, extra = '') => { cond ? pass++ : fail++; console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}${extra ? '  (' + extra + ')' : ''}`); };

// 1. Detect a pure 220 Hz tone within 2 Hz.
const f = estimateF0(sine(220, 200), SR);
ok('estimateF0 detects 220Hz', Math.abs(f - 220) < 2, `got ${f.toFixed(1)}Hz`);

// 2. Detect 330 Hz too.
const f2 = estimateF0(sine(330, 200), SR);
ok('estimateF0 detects 330Hz', Math.abs(f2 - 330) < 2, `got ${f2.toFixed(1)}Hz`);

// 3. Silence -> unvoiced.
ok('silence -> unvoiced (-1)', estimateF0(Array(2048).fill(0), SR) === -1);

// 4. Identical contours -> perfect score.
const rising = [180, 190, 200, 220, 240, 260];
ok('identical contour -> 100', accentScore(rising, rising) === 100);

// 5. Same shape, different octave (male vs female) -> still ~100 (speaker-independent).
const risingHigh = rising.map((x) => x * 2);
ok('same shape different octave -> ~100', accentScore(rising, risingHigh) > 99, `${accentScore(rising, risingHigh).toFixed(1)}`);

// 6. Opposite melody (rising vs falling) -> low score.
const falling = [...rising].reverse();
ok('opposite melody -> low score', accentScore(rising, falling) < 40, `${accentScore(rising, falling).toFixed(1)}`);

// 7. atamadaka (HL) vs heiban-ish (LH) minimal pair -> clearly different.
const HL = [260, 250, 200, 190]; // high then low
const LH = [190, 200, 250, 260]; // low then high
ok('HL vs LH distinguishable', accentScore(HL, LH) < 50, `${accentScore(HL, LH).toFixed(1)}`);
ok('HL vs HL close', accentScore(HL, HL.map((x) => x + 5)) > 90, `${accentScore(HL, HL.map((x) => x + 5)).toFixed(1)}`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
