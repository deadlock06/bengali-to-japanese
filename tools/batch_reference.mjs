// Node proof for lib/data/lesson_batch.dart (T-112 classroom batch builder).
// Mirrors buildClassroomBatch 1:1 and runs it against the REAL lesson JSONs +
// curriculum.json, so batch behaviour is proven without Flutter.
// Run: node tools/batch_reference.mjs
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const content = join(root, 'assets', 'content');

// ── 1:1 port ────────────────────────────────────────────────────────────────
const seed = (s) => [...s].reduce((a, c) => (a + c.charCodeAt(0)) & 0x7fffffff, 0);

function buildClassroomBatch(curriculumOrdered, completed, maxItems = 8) {
  const next = curriculumOrdered.find(
    (l) => !completed.has(l.id) && l.items.length > 0);
  if (!next) return null;

  const poolLocal = [], poolGlobal = [];
  for (const it of next.items) {
    if (!poolLocal.includes(it.meaning.bn)) poolLocal.push(it.meaning.bn);
  }
  for (const l of curriculumOrdered) {
    if (l === next) continue;
    for (const it of l.items) {
      const m = it.meaning.bn;
      if (!poolLocal.includes(m) && !poolGlobal.includes(m)) poolGlobal.push(m);
    }
  }

  const questions = [];
  const items = next.items.slice(0, maxItems);
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    const correct = it.meaning.bn;
    const distractors = [];
    const local = poolLocal.filter((m) => m !== correct);
    for (let k = 0; k < local.length && distractors.length < 3; k++) {
      distractors.push(local[(k + i) % local.length]);
    }
    for (let k = 0; k < poolGlobal.length && distractors.length < 3; k++) {
      distractors.push(poolGlobal[(k + i) % poolGlobal.length]);
    }
    if (distractors.length < 3) continue;

    const answerIndex = seed(it.id) % 4;
    const options = [...distractors];
    options.splice(answerIndex, 0, correct);
    questions.push({ itemId: it.id, options, answerIndex, correct });
  }
  if (questions.length === 0) return null;
  return { lessonId: next.id, titleBn: next.can_do.bn, questions };
}

// ── load the real content in curriculum order ──────────────────────────────
const curriculum = JSON.parse(
  readFileSync(join(root, 'assets', 'curriculum', 'curriculum.json'), 'utf8'));
const units = Array.isArray(curriculum) ? curriculum : curriculum.units;

const lessonsById = {};
for (const f of readdirSync(content).filter((f) => f.startsWith('lesson_'))) {
  const l = JSON.parse(readFileSync(join(content, f), 'utf8'));
  lessonsById[l.id] = l;
}
const ordered = [];
for (const u of units) {
  const ids = (u.lesson_id ?? '').split(',').map((s) => s.trim()).filter(Boolean);
  for (const id of ids) {
    if (lessonsById[id] && !ordered.includes(lessonsById[id])) ordered.push(lessonsById[id]);
  }
}
for (const l of Object.values(lessonsById)) {
  if (!ordered.includes(l)) ordered.push(l);
}

// ── proofs ──────────────────────────────────────────────────────────────────
let pass = 0, fail = 0;
const ok = (cond, name) => {
  if (cond) { pass++; console.log(`ok   ${name}`); }
  else { fail++; console.log(`FAIL ${name}`); }
};

const b0 = buildClassroomBatch(ordered, new Set());
ok(b0 !== null, 'fresh learner gets a batch');
ok(b0.lessonId === ordered[0].id, 'fresh learner starts at the first curriculum lesson');
ok(b0.questions.length > 0 && b0.questions.length <= 8, `batch capped at 8 (got ${b0.questions.length})`);
ok(b0.titleBn.length > 0, 'batch carries the can_do.bn title (the "why")');

let structural = true, keyMatch = true, uniqueOpts = true;
for (const q of b0.questions) {
  if (q.options.length !== 4) structural = false;
  if (q.options[q.answerIndex] !== q.correct) keyMatch = false;
  if (new Set(q.options).size !== 4) uniqueOpts = false;
}
ok(structural, 'every question has exactly 4 options');
ok(keyMatch, 'options[answerIndex] IS the verified meaning.bn (answer-key grading, 00 §4)');
ok(uniqueOpts, 'options are unique (no duplicate distractors)');

const b1 = buildClassroomBatch(ordered, new Set());
ok(JSON.stringify(b0) === JSON.stringify(b1), 'deterministic: same inputs, identical batch');

const afterFirst = buildClassroomBatch(ordered, new Set([ordered[0].id]));
ok(afterFirst !== null && afterFirst.lessonId === ordered[1].id,
   'completing a lesson advances to the next curriculum lesson');

const allDone = buildClassroomBatch(ordered, new Set(ordered.map((l) => l.id)));
ok(allDone === null, 'all lessons completed -> null (caller shows "all done")');

// every wired lesson must be batchable (guards future content edits)
let allBatchable = true;
for (let i = 0; i < ordered.length; i++) {
  const done = new Set(ordered.slice(0, i).map((l) => l.id));
  const b = buildClassroomBatch(ordered, done);
  if (!b || b.lessonId !== ordered[i].id) { allBatchable = false; break; }
}
ok(allBatchable, `every lesson in curriculum order is batchable (${ordered.length} lessons)`);

console.log(`\n${pass}/${pass + fail} passed`);
if (fail > 0) process.exit(1);
