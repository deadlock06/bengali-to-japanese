#!/usr/bin/env node
// token_report.mjs — measure the real token cost of the SENSEI spec and show
// how much the router saves. Uses actual file sizes (not the author estimates).
// Token estimate = ceil(chars / 4), the standard rough rule for English/markdown.
// The PERCENTAGE is unit-invariant, so it holds regardless of the exact tokenizer.
//
// Usage:  node token_report.mjs

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';
import { DOCS } from './routes.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));

function resolveDocsDir() {
  let cur = __dirname;
  for (let i = 0; i < 8; i++) {
    for (const name of ['reference', 'docs']) {
      const cand = join(cur, name);
      if (existsSync(join(cand, '00_START_HERE.md'))) return cand;
    }
    const parent = dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }
  return null;
}
function skillPath() {
  for (const p of [join(__dirname, '..', 'SKILL.md'), join(__dirname, '..', '..', 'SKILL.md')])
    if (existsSync(p)) return p;
  return null;
}

const toks = (s) => Math.ceil(s.length / 4);
const K = (t) => `${(t / 1000).toFixed(1)}K`;

const docsDir = resolveDocsDir();
if (!docsDir) { console.error('Could not locate docs/ or reference/.'); process.exit(1); }

// measured token cost per doc
const measured = {};
let baseline = 0;
for (const d of DOCS) {
  const p = join(docsDir, d.file);
  const t = existsSync(p) ? toks(readFileSync(p, 'utf8')) : 0;
  measured[d.id] = t;
  baseline += t;
}
const sp = skillPath();
const skillTok = sp ? toks(readFileSync(sp, 'utf8')) : 1300;

console.log('\nSENSEI token report  (measured from ' + docsDir + ')');
console.log('='.repeat(66));
console.log('Per-file cost (~tokens, chars/4):');
for (const d of DOCS) console.log(`  ${d.id}  ${d.file.padEnd(24)} ~${K(measured[d.id])}`);
console.log('  ' + '-'.repeat(40));
console.log(`  Whole spec (load everything):   ~${K(baseline)} tokens`);
console.log(`  This skill / router (SKILL.md):  ~${K(skillTok)} tokens (loaded once)`);

// representative tasks → docs the router would select
const tasks = [
  ['Encrypt the DB + migrations',        ['06']],
  ['Build a lesson screen w/ Skip/Hint', ['09']],
  ['Tune on-device LLM inference',       ['08', '02', '03']],
  ['Author + validate a new lesson',     ['05']],
  ['What should I build next?',          ['11']],
  ['Sync + conflict resolution',         ['07', '06']],
  ['Pricing / launch metrics',           ['12']],
];

console.log('\nPer-task cost with the router (skill + only the needed docs):');
console.log('  ' + 'task'.padEnd(34) + 'router'.padEnd(10) + 'vs all'.padEnd(9) + 'saved');
let sumSaved = 0;
for (const [name, ids] of tasks) {
  const cost = skillTok + ids.reduce((s, id) => s + (measured[id] || 0), 0);
  const saved = 100 * (1 - cost / baseline);
  sumSaved += saved;
  console.log('  ' + name.padEnd(34) + `~${K(cost)}`.padEnd(10) + `~${K(baseline)}`.padEnd(9) + `${saved.toFixed(0)}%`);
}
const avg = sumSaved / tasks.length;

// typical single-doc task
const singleAvgDoc = Math.round(
  DOCS.filter(d => d.id !== '00').reduce((s, d) => s + measured[d.id], 0) / (DOCS.length - 1)
);
const typical = skillTok + singleAvgDoc;
const typicalSaved = 100 * (1 - typical / baseline);

console.log('  ' + '-'.repeat(58));
console.log(`  Average across the tasks above:            ${avg.toFixed(0)}% saved`);
console.log(`  Typical single-doc task (skill + 1 avg doc): ~${K(typical)} → ${typicalSaved.toFixed(0)}% saved`);
console.log('='.repeat(66));
console.log(`RESULT: the router turns a ~${K(baseline)}-token spec read into ~${K(typical)} tokens`);
console.log(`for a typical task — about ${typicalSaved.toFixed(0)}% fewer tokens, with the`);
console.log('non-negotiables still always in context. Bigger multi-doc tasks save less,');
console.log('but stay well under loading the whole spec.\n');
