#!/usr/bin/env node
// route.mjs — given a task description, print ONLY the doc(s) to load + token cost.
// Usage:  node route.mjs "encrypt the local database and add migrations"
//         node route.mjs "new session"        (prints the bootstrap sequence)
// Zero dependencies. Works in-repo (docs/) or as an installed skill (reference/).
// Token counts are MEASURED from the real files (chars/4); author estimates in
// routes.mjs are only a fallback when a file can't be read.

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';
import { DOCS, NON_NEGOTIABLES, byId } from './routes.mjs';

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
function findUp(fname) {
  let cur = __dirname;
  for (let i = 0; i < 8; i++) {
    const p = join(cur, fname);
    if (existsSync(p)) return p;
    const parent = dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }
  return null;
}

const toks = (s) => Math.ceil(s.length / 4);
const K = (t) => `${(t / 1000).toFixed(1)}K`;
const docsDir = resolveDocsDir();

const measured = {};
for (const d of DOCS) {
  const p = docsDir ? join(docsDir, d.file) : null;
  measured[d.id] = (p && existsSync(p)) ? toks(readFileSync(p, 'utf8')) : d.tok;
}
const BASELINE = DOCS.reduce((s, d) => s + measured[d.id], 0);
const skillFile = findUp('SKILL.md');
const SKILL_TOK = skillFile ? toks(readFileSync(skillFile, 'utf8')) : 1300;
const cost = (id) => measured[id] || byId(id)?.tok || 0;
const pathFor = (d) => (docsDir ? resolve(join(docsDir, d.file)) : `docs/${d.file}`);

const query = process.argv.slice(2).join(' ').trim();
const q = query.toLowerCase();

console.log('\nSENSEI router  ·  guardrails first, then load only what you need');
console.log('-'.repeat(64));
console.log('NON-NEGOTIABLES (apply to EVERY task):');
NON_NEGOTIABLES.forEach((n, i) => console.log(`  ${i + 1}. ${n}`));
console.log('-'.repeat(64));

if (!query) {
  console.log('No task given. Usage: node route.mjs "<what you are doing>"\n');
  console.log('Task areas:');
  for (const d of DOCS) if (d.id !== '00') console.log(`  ${d.id}  ${d.when}`);
  console.log(`\nLoad-everything cost: ~${K(BASELINE)} tokens. Router loads a fraction of that.\n`);
  process.exit(0);
}

if (/(new|start|begin|fresh|first)\b.*(session|task)?|^(hi|hello|kickoff)/.test(q)
    || /bootstrap|where do i start|onboard/.test(q)) {
  const b = SKILL_TOK + cost('11') + cost('90');
  console.log(`Task: "${query}"  ->  SESSION BOOTSTRAP\n`);
  console.log('Read, in order:');
  console.log('  1. NEXT_SESSION.md      (what the last session did / do-next)');
  console.log('  2. CODEBASE_MAP.md      (what actually exists vs spec)');
  console.log('     - if missing or >2 weeks old -> load 90_EXISTING_CODEBASE.md and regenerate it first');
  console.log('  3. 11_ROADMAP_TASKS.md  (pick the task) -> then re-run route.mjs with that task');
  console.log(`\nEst: ~${K(b)} tokens vs ~${K(BASELINE)} to load the whole spec (${(100 * (1 - b / BASELINE)).toFixed(0)}% less).\n`);
  process.exit(0);
}

const scored = DOCS.filter((d) => d.id !== '00').map((d) => {
  let score = 0;
  for (const k of d.keys) if (q.includes(k)) score += 1;
  return { d, score };
}).filter((x) => x.score > 0).sort((a, b) => b.score - a.score);

console.log(`Task: "${query}"\n`);

if (scored.length === 0) {
  console.log('No confident match. Browse the task areas and pick manually:');
  for (const d of DOCS) if (d.id !== '00') console.log(`  ${d.id}  ${d.when}`);
  console.log('\nStill unsure? 11_ROADMAP_TASKS.md is the safe default for "what/next" questions.\n');
  process.exit(0);
}

const primary = scored.slice(0, 3);
const primaryIds = new Set(primary.map((x) => x.d.id));
const loadList = primary.map((x) => x.d);

console.log('LOAD (only these):');
let total = SKILL_TOK;
for (const x of primary) {
  console.log(`  ${x.d.id}  ${x.d.file.padEnd(24)} ~${K(cost(x.d.id))}  - ${x.d.when}`);
  total += cost(x.d.id);
}

const optional = [...new Set(loadList.flatMap((d) => d.deps))]
  .filter((id) => id !== '00' && !primaryIds.has(id))
  .map(byId).filter(Boolean);
if (optional.length) {
  console.log('\nCONSIDER (only if your task actually touches these):');
  for (const d of optional) console.log(`  ${d.id}  ${d.file.padEnd(24)} ~${K(cost(d.id))}  - ${d.when}`);
}

console.log('\nSKIP everything else.');
if (docsDir) {
  console.log('\nResolved paths:');
  for (const d of loadList) console.log(`  ${pathFor(d)}`);
}

const saved = 100 * (1 - total / BASELINE);
console.log('\n' + '-'.repeat(64));
console.log(`Router cost: ~${K(total)} tokens (skill ~${K(SKILL_TOK)} + ${primary.length} doc${primary.length > 1 ? 's' : ''})`);
console.log(`Load-everything cost: ~${K(BASELINE)} tokens`);
console.log(`Saved: ~${saved.toFixed(0)}% for this task.\n`);
