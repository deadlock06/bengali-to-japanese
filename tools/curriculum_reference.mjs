// curriculum_reference.mjs — proof for CurriculumService.derive (T-120).
// Mirrors lib/data/curriculum_service.dart exactly; runs against the real
// assets/curriculum/curriculum.json. Run: node tools/curriculum_reference.mjs
import fs from 'node:fs';

const root = JSON.parse(fs.readFileSync('assets/curriculum/curriculum.json', 'utf8'));

function derive(root, completed) {
  const levelOrder = Object.fromEntries(root.levels.map(l => [l.id, l.order]));
  const raw = [...root.units].sort((a, b) =>
    (levelOrder[a.level] - levelOrder[b.level]) || ((a.order ?? 0) - (b.order ?? 0)));
  const lessonsOf = u => (typeof u.lesson_id === 'string' && u.lesson_id) ? u.lesson_id.split(',').map(s => s.trim()) : [];
  const doneById = {};
  for (const u of raw) { const ls = lessonsOf(u); doneById[u.id] = ls.length > 0 && ls.every(l => completed.has(l)); }
  let currentAssigned = false; const out = [];
  for (const u of raw) {
    const ls = lessonsOf(u);
    const prereqs = u.prerequisites ?? [];
    const isDone = doneById[u.id];
    const prereqsMet = prereqs.every(p => doneById[p]);
    let state = 'upcoming', pct = 0;
    if (isDone) { state = 'done'; pct = 1; }
    else if (!currentAssigned && prereqsMet) { state = 'current'; currentAssigned = true;
      if (ls.length) pct = ls.filter(l => completed.has(l)).length / ls.length; }
    out.push({ id: u.id, level: u.level, state, pct, prereqs, ls });
  }
  return out;
}

let pass = 0, fail = 0;
const t = (name, cond) => { cond ? pass++ : (fail++, console.log('  FAIL:', name)); };

// 1. ontology integrity
const ids = new Set(root.units.map(u => u.id));
t('20 units', root.units.length === 20);
t('all prereq ids resolve', root.units.every(u => (u.prerequisites ?? []).every(p => ids.has(p))));
{ // acyclic
  const g = Object.fromEntries(root.units.map(u => [u.id, u.prerequisites ?? []]));
  const state = {}; let cyclic = false;
  const dfs = n => { if (state[n] === 1) { cyclic = true; return; } if (state[n] === 2) return;
    state[n] = 1; for (const d of g[n]) dfs(d); state[n] = 2; };
  Object.keys(g).forEach(dfs);
  t('prereq graph acyclic', !cyclic);
}
// 2. every non-mock unit maps to real lesson files (kana handled by kana screens ids)
const realIds = new Set(fs.readdirSync('assets/content')
  .map(f => { try { return JSON.parse(fs.readFileSync('assets/content/' + f, 'utf8')).id; } catch { return null; } })
  .filter(Boolean));
realIds.add('kana_hiragana'); realIds.add('kana_katakana'); // kana screens' ids
const withLessons = root.units.filter(u => u.lesson_id);
t('13 units have lesson_id (mocks+N4 pending)', withLessons.length === 13);
t('all lesson_ids resolve to real lesson JSON ids (or kana ids)',
  withLessons.every(u => u.lesson_id.split(',').every(l => realIds.has(l.trim()))));

// 3. empty progress → single current at L0.1, zero done
let d0 = derive(root, new Set());
t('empty: L0.1 current', d0.find(u => u.id === 'L0.1').state === 'current');
t('empty: exactly one current', d0.filter(u => u.state === 'current').length === 1);
t('empty: zero done', d0.every(u => u.state !== 'done'));

// 4. kana done → L0.2 becomes current
let d1 = derive(root, new Set(['kana_hiragana']));
t('L0.1 done after kana_hiragana', d1.find(u => u.id === 'L0.1').state === 'done');
t('L0.2 current next', d1.find(u => u.id === 'L0.2').state === 'current');

// 5. all authored lessons done → mocks/N4 never done, one current remains
const allLessons = new Set(realIds);
allLessons.add('kana_hiragana'); allLessons.add('kana_katakana'); allLessons.add('work_intro_01');
let d2 = derive(root, allLessons);
t('authored-all: A2.M not done (no lessons)', d2.find(u => u.id === 'A2.M').state !== 'done');
t('authored-all: exactly one current', d2.filter(u => u.state === 'current').length === 1);
t('authored-all: >=13 done', d2.filter(u => u.state === 'done').length >= 13);

// 6. partial unit pct: only lesson_smalltalk of A2.5 done
// (fixture tracks the wired lesson lists — updated 2026-07-16 for the new
// numbers_big/week/food + orphan wirings shopping/greetings/emergency)
// Everything before A2.5 done + ONLY smalltalk of A2.5 → A2.5 current at
// 1/N pct. Derive the set from the live ontology so content growth doesn't
// break this fixture again (pct asserted against A2.5's live lesson count).
const upto = new Set();
for (const u of root.units) {
  if (u.id === 'A2.5' || u.id.startsWith('N4') || u.id === 'A2.M' || u.id === 'A2.6') continue;
  for (const id of (u.lesson_id || '').split(',').map(s => s.trim()).filter(Boolean)) upto.add(id);
}
upto.add('lesson_smalltalk');
let d3 = derive(root, upto);
const a25 = d3.find(u => u.id === 'A2.5');
const want = 1 / a25.ls.length; // one of A2.5's live lesson list completed
t(`A2.5 current w/ pct 1/${a25.ls.length}`, a25.state === 'current' && Math.abs(a25.pct - want) < 1e-9);

console.log(`\n${pass}/${pass + fail} passed`);
process.exit(fail ? 1 : 0);
