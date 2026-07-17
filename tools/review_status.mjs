#!/usr/bin/env node
// A5 native-speaker review tracker. Content JSON MAY carry a top-level
// `reviewed_by` (+ optional `reviewed_at`); this reports coverage. The actual
// review is HUMAN work — a native Japanese speaker checks each lesson, then
// adds `"reviewed_by": "<name>"`. Publishing is blocked until 100%.
//   node tools/review_status.mjs
import fs from 'node:fs';
import path from 'node:path';

const dir = path.join(import.meta.dirname, '..', 'assets', 'content');
const files = fs.readdirSync(dir).filter((f) =>
  /^(lesson_|scenario_|hiragana|katakana|pitch)/.test(f) && f.endsWith('.json'));

let reviewed = 0;
const pending = [];
for (const f of files) {
  const d = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
  if (d.reviewed_by) reviewed++;
  else pending.push(f);
}
const pct = Math.round((100 * reviewed) / files.length);
console.log(`\n🈁 A5 native-speaker review: ${reviewed}/${files.length} files (${pct}%)`);
if (pending.length) {
  console.log(`\n⏳ pending (add "reviewed_by":"<name>" once a native speaker checks it):`);
  for (const f of pending) console.log(`   ${f}`);
  console.log(`\n⚠️  PUBLISH BLOCKED until 100% (D-001 correctness / A5).`);
} else {
  console.log('✅ all content native-reviewed — cleared for publish.');
}
