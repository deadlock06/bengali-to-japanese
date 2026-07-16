#!/usr/bin/env node
// 📏 PROJECT SCALE validator — computes real completion % from the repo itself
// and names the next unblocked step from PROJECT_SCALE.md.
//   node tools/progress_scale.mjs          # scoreboard (fast, ~seconds)
//   node tools/progress_scale.mjs --gate   # + flutter analyze/test + all proofs (run before/after every step)
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const root = path.join(import.meta.dirname, '..');
const rd = (p) => fs.readFileSync(path.join(root, p), 'utf8');
const j = (p) => JSON.parse(rd(p));
const GATE = process.argv.includes('--gate');
let failures = 0;
const pct = (a, b) => (b ? Math.round((100 * a) / b) : 0);
const bar = (p) => '█'.repeat(Math.round(p / 10)).padEnd(10, '·');

// ── automated metrics ────────────────────────────────────────────────────────
const cur = j('assets/curriculum/curriculum.json');
const lessons = {};
for (const f of fs.readdirSync(path.join(root, 'assets/content')))
  if (f.startsWith('lesson_')) { const d = j(`assets/content/${f}`); lessons[d.id] = d.items; }

let target = 0, actual = 0, brokenRefs = [];
const unitRows = [];
for (const u of cur.units) {
  const ids = (u.lesson_id || '').split(',').map((s) => s.trim()).filter(Boolean);
  let a = 0;
  for (const id of ids) {
    if (id.startsWith('kana_')) a += 46;
    else if (lessons[id]) a += lessons[id].length;
    else brokenRefs.push(`${u.id}→${id}`);
  }
  target += u.target_word_count || 0; actual += a;
  unitRows.push({ id: u.id, t: u.target_word_count || 0, a });
}
const contentPct = pct(actual, target);

const man = j('assets/audio/manifest.json');
let audioMissing = 0, audioTotal = 0;
for (const items of Object.values(lessons))
  for (const it of items) { audioTotal++; if (!man[it.id]) audioMissing++; }
const batchSrc = rd('lib/data/lesson_batch.dart');
const kana71 = (batchSrc.match(/_hiraChars =\s*'([^']*)'\s*'([^']*)'/s) || [, '', ''])
  .slice(1).join('').length === 71;
const strokes = j('assets/stroke/kana_strokes.json');
const strokeOk = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'
  .split('').every((c) => strokes.hiragana?.[c]);
const bookSync = (rd('assets/book/book.json').match(/app-synced/g) || []).length;
const unitChaptersWanted = cur.units.filter((u) =>
  (u.lesson_id || '').split(',').some((x) => x.trim() && !x.trim().startsWith('kana_'))).length;

// ── steps from PROJECT_SCALE.md ──────────────────────────────────────────────
const scale = rd('PROJECT_SCALE.md');
const steps = [];
for (const m of scale.matchAll(/^- \[( |x)\] \*\*([A-E]\d+) · (.+?)\*\*[\s\S]*?_needs: (.*?)_/gm))
  steps.push({ done: m[1] === 'x', id: m[2], title: m[3], needs: m[4] });
const owner = [...scale.matchAll(/^## OWNER-ONLY[\s\S]*?(?=\n---|\n## |$)/gm)]
  .flatMap((s) => [...s[0].matchAll(/^- \[( |x)\] (.+)$/gm)])
  .map((m) => ({ done: m[1] === 'x', title: m[2] }));
const doneIds = new Set(steps.filter((s) => s.done).map((s) => s.id));
const unblocked = steps.filter((s) => !s.done && s.needs
  .split(',').map((n) => n.trim().replace(/ \(.*\)/, ''))
  .every((n) => n === '—' || doneIds.has(n) || n.startsWith('OWNER')));
const next = unblocked.find((s) => !s.needs.includes('OWNER')) || unblocked[0];

// ── proofs (always) + full gate (--gate) ─────────────────────────────────────
const run = (cmd, label) => {
  try { execSync(cmd, { cwd: root, stdio: 'pipe' }); console.log(`  ✅ ${label}`); }
  catch { console.log(`  ❌ ${label}`); failures++; }
};
console.log('\n📏 PROJECT SCALE — automated proofs');
for (const [f, l] of [['validate_content.mjs', 'content validator'],
  ['batch_reference.mjs', 'batch engine'], ['curriculum_reference.mjs', 'curriculum engine'],
  ['agents_reference.mjs', 'agents'], ['fsrs_reference.mjs', 'FSRS'],
  ['lesson_flow_reference.mjs', 'lesson flow'], ['migrations_reference.mjs', 'migrations'],
  ['pitch_reference.mjs', 'pitch']]) run(`node tools/${f}`, l);
if (brokenRefs.length) { console.log(`  ❌ curriculum refs: ${brokenRefs}`); failures++; }
else console.log('  ✅ curriculum refs resolve');
if (audioMissing) { console.log(`  ❌ audio: ${audioMissing}/${audioTotal} items missing clips`); failures++; }
else console.log(`  ✅ audio: all ${audioTotal} lesson items have clips`);
console.log(`  ${kana71 ? '✅' : '❌'} kana batch = 71`); if (!kana71) failures++;
console.log(`  ${strokeOk ? '✅' : '❌'} stroke data covers base kana`); if (!strokeOk) failures++;
console.log(`  ${bookSync === unitChaptersWanted ? '✅' : '❌'} book sync: ${bookSync}/${unitChaptersWanted} unit chapters`);
if (bookSync !== unitChaptersWanted) failures++;
if (GATE) {
  console.log('\n  — full gate (flutter) —');
  run('bash -lc \'export PATH="$HOME/flutter/bin:$PATH"; flutter analyze\'', 'flutter analyze');
  run('bash -lc \'export PATH="$HOME/flutter/bin:$PATH"; flutter test\'', 'flutter test');
}

// ── scoreboard ───────────────────────────────────────────────────────────────
const phase = {};
for (const s of steps) { const p = s.id[0]; phase[p] ??= [0, 0]; phase[p][1]++; if (s.done) phase[p][0]++; }
console.log('\n📊 SCOREBOARD');
console.log(`  Content (ladder items)   ${bar(contentPct)} ${contentPct}%  (${actual}/${target})`);
for (const [p, name] of [['A', 'Phase A · Content'], ['B', 'Phase B · Practice'],
  ['C', 'Phase C · Vision'], ['D', 'Phase D · Platform'], ['E', 'Phase E · Launch']]) {
  const [d, t] = phase[p] || [0, 0];
  console.log(`  ${name.padEnd(24)} ${bar(pct(d, t))} ${d}/${t} steps`);
}
const ownerOpen = owner.filter((o) => !o.done);
if (ownerOpen.length) console.log(`\n⚠️  OWNER items open: ${ownerOpen.map((o) => o.title).join(' · ')}`);
console.log(next
  ? `\n👉 NEXT STEP: ${next.id} — ${next.title}${next.needs.includes('OWNER') ? '  (⚠️ owner-blocked)' : ''}`
  : '\n🎉 every step ticked');
console.log(failures ? `\n❌ ${failures} check(s) failing — fix before proceeding\n` : '\n✅ all checks green\n');
process.exit(failures ? 1 : 0);
