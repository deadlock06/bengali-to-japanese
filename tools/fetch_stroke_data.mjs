// One-time DEV tool. Run locally:  node tools/fetch_stroke_data.mjs
// Builds assets/stroke/kana_strokes.json so the app ships stroke-order data OFFLINE
// (no runtime network). Source = KanjiVG (canonical, correct stroke order/count),
// one <path> per stroke, in stroke order. We flatten each stroke path into sampled
// median points and scale KanjiVG's 109x109 viewBox up to the consumer's 0..1000
// y-down space (writing_screen.dart uses `sc = w/1000`), so the Flutter code is
// unchanged. Replaces the old kana-svg-data medians, which split looping strokes into
// two paths (16/92 wrong counts, e.g. あ→4, ヲ→2). See 99_DECISIONS.md D-011.
//
// KanjiVG is CC BY-SA 3.0 (© Ulrich Apel / KanjiVG contributors). The generated JSON
// is a derivative and stays under CC BY-SA; attribution is embedded in the file.
import fs from 'fs';

const HIRA = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'.split('');
const KATA = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'.split('');

const KVG_VIEWBOX = 109; // KanjiVG native viewBox is "0 0 109 109"
const OUT_VIEWBOX = 1000; // must match the scale in writing_screen.dart's painter
const SCALE = OUT_VIEWBOX / KVG_VIEWBOX;
const BEZIER_STEPS = 8; // samples per cubic/quadratic segment (smooth enough at this size)

// --- minimal SVG path flattener: M/m L/l H/h V/v C/c S/s Q/q T/t Z/z --------------
function tokenize(d) {
  const re = /([MmLlHhVvCcSsQqTtAaZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)/g;
  const out = [];
  let m;
  while ((m = re.exec(d))) out.push(m[1] ? { cmd: m[1] } : { num: parseFloat(m[2]) });
  return out;
}

function cubic(p0, p1, p2, p3, steps, push) {
  for (let k = 1; k <= steps; k++) {
    const t = k / steps, u = 1 - t;
    push(
      u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
      u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1],
    );
  }
}
function quad(p0, p1, p2, steps, push) {
  for (let k = 1; k <= steps; k++) {
    const t = k / steps, u = 1 - t;
    push(u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]);
  }
}

// Flatten one path's `d` into an array of [x,y] points (KanjiVG space).
function flatten(d) {
  const toks = tokenize(d);
  const pts = [];
  let i = 0, cur = [0, 0], start = [0, 0], prevCtrl = null, cmd = null;
  const nums = (n) => { const a = []; for (let k = 0; k < n; k++) a.push(toks[i++].num); return a; };
  const push = (x, y) => pts.push([x, y]);
  const first = () => pts.length === 0;

  while (i < toks.length) {
    if (toks[i].cmd) { cmd = toks[i++].cmd; }
    const abs = cmd === cmd.toUpperCase();
    const C = cmd.toUpperCase();
    switch (C) {
      case 'M': {
        const [x, y] = nums(2);
        cur = abs || first() ? [x, y] : [cur[0] + x, cur[1] + y];
        start = [...cur];
        push(cur[0], cur[1]);
        cmd = abs ? 'L' : 'l'; // subsequent implicit pairs are lineto
        prevCtrl = null;
        break;
      }
      case 'L': {
        const [x, y] = nums(2);
        cur = abs ? [x, y] : [cur[0] + x, cur[1] + y];
        push(cur[0], cur[1]); prevCtrl = null; break;
      }
      case 'H': {
        const [x] = nums(1);
        cur = [abs ? x : cur[0] + x, cur[1]];
        push(cur[0], cur[1]); prevCtrl = null; break;
      }
      case 'V': {
        const [y] = nums(1);
        cur = [cur[0], abs ? y : cur[1] + y];
        push(cur[0], cur[1]); prevCtrl = null; break;
      }
      case 'C': {
        const n = nums(6);
        const p1 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        const p2 = abs ? [n[2], n[3]] : [cur[0] + n[2], cur[1] + n[3]];
        const p3 = abs ? [n[4], n[5]] : [cur[0] + n[4], cur[1] + n[5]];
        cubic(cur, p1, p2, p3, BEZIER_STEPS, push);
        prevCtrl = p2; cur = p3; break;
      }
      case 'S': {
        const n = nums(4);
        const p1 = prevCtrl ? [2 * cur[0] - prevCtrl[0], 2 * cur[1] - prevCtrl[1]] : [...cur];
        const p2 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        const p3 = abs ? [n[2], n[3]] : [cur[0] + n[2], cur[1] + n[3]];
        cubic(cur, p1, p2, p3, BEZIER_STEPS, push);
        prevCtrl = p2; cur = p3; break;
      }
      case 'Q': {
        const n = nums(4);
        const p1 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        const p2 = abs ? [n[2], n[3]] : [cur[0] + n[2], cur[1] + n[3]];
        quad(cur, p1, p2, BEZIER_STEPS, push);
        prevCtrl = p1; cur = p2; break;
      }
      case 'T': {
        const n = nums(2);
        const p1 = prevCtrl ? [2 * cur[0] - prevCtrl[0], 2 * cur[1] - prevCtrl[1]] : [...cur];
        const p2 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        quad(cur, p1, p2, BEZIER_STEPS, push);
        prevCtrl = p1; cur = p2; break;
      }
      case 'Z': {
        push(start[0], start[1]); cur = [...start]; prevCtrl = null; break;
      }
      default: // A (arc) — not used by KanjiVG; skip its 7 params defensively
        if (C === 'A') { nums(7); } else { i++; }
        prevCtrl = null;
    }
  }
  return pts;
}

// Scale to OUT_VIEWBOX, round, and drop consecutive duplicate points.
function scaleClean(pts) {
  const out = [];
  for (const [x, y] of pts) {
    const p = [Math.round(x * SCALE), Math.round(y * SCALE)];
    const last = out[out.length - 1];
    if (!last || last[0] !== p[0] || last[1] !== p[1]) out.push(p);
  }
  return out;
}

async function fetchStrokes(ch) {
  const cp = ch.codePointAt(0).toString(16).padStart(5, '0');
  const url = `https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/${cp}.svg`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${ch} (${cp}) HTTP ${r.status}`);
  const svg = await r.text();
  // one <path d="..."> per stroke, in document (= stroke) order
  const paths = [...svg.matchAll(/<path[^>]*\sd="([^"]+)"/g)].map((m) => m[1]);
  if (!paths.length) throw new Error(`${ch} (${cp}) no <path> found`);
  return paths.map((d) => scaleClean(flatten(d))).filter((s) => s.length > 1);
}

const out = {
  viewBox: OUT_VIEWBOX,
  source: 'KanjiVG (https://kanjivg.tagaini.net)',
  license: 'CC BY-SA 3.0 — © Ulrich Apel / KanjiVG contributors',
  note: 'Generated by tools/fetch_stroke_data.mjs. One median polyline per stroke, in stroke order.',
  hiragana: {},
  katakana: {},
};

for (const [arr, key] of [[HIRA, 'hiragana'], [KATA, 'katakana']]) {
  for (const ch of arr) {
    try { out[key][ch] = await fetchStrokes(ch); process.stdout.write('.'); }
    catch (e) { console.error('\nFAIL', e.message); }
  }
}

fs.writeFileSync('assets/stroke/kana_strokes.json', JSON.stringify(out));
console.log(
  `\nwrote assets/stroke/kana_strokes.json  (hira:${Object.keys(out.hiragana).length} kata:${Object.keys(out.katakana).length})`,
);
