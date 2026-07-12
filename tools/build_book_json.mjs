#!/usr/bin/env node
// build_book_json.mjs — compiles classroom/BOOK.md into assets/book/book.json
// for the BookScreenV4 reader (T-121). Re-run after every BOOK.md edit:
//   node tools/build_book_json.mjs
// Output schema: { meta{...}, chapters:[{ id, num, title, unit, level, blocks:[
//   {t:'h',c} | {t:'p',c} | {t:'li',c} | {t:'q',c} | {t:'table',rows:[[..]]} ] }] }
// Block parser is markdown-lite: ###/#### heads, - lists, > quotes, | tables,
// everything else = paragraph. Bold/inline markers are kept (reader styles **).

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = readFileSync(join(root, 'classroom/BOOK.md'), 'utf8');
const lines = src.split(/\r?\n/);

// --- front matter ---
let i = 0, meta = {};
if (lines[0] === '---') {
  i = 1;
  while (lines[i] !== '---') {
    const m = lines[i].match(/^(\w+):\s*"?(.*?)"?\s*$/);
    if (m) meta[m[1]] = m[2];
    i++;
  }
  i++;
}

// --- split into chapters ---
// boundaries: "## Chapter N — Title" | "# PART ..." | "## Appendix X — ..." |
// intro pseudo-chapter = everything between the big title and PART 0.
const chapters = [];
let cur = null, curPart = '';
function flush() { if (cur && cur.lines.length) chapters.push(cur); cur = null; }
function start(id, num, title) { flush(); cur = { id, num, title, part: curPart, lines: [] }; }

for (; i < lines.length; i++) {
  const L = lines[i];
  const part = L.match(/^# (PART .+|APPENDICES.+)$/);
  const ch = L.match(/^## Chapter (\d+) — (.+)$/);
  const ap = L.match(/^## (Appendix [A-F]) — (.+)$/);
  const intro = L.match(/^## (ভূমিকা.*)$/);
  const tail = L.match(/^## (জাপানি proficiency.+|N3 এর দিকে.+|শেষ কথা.+|এই বই কীভাবে বানানো.+|পুরো রাস্তার Map)$/);
  if (part) { curPart = part[1]; continue; }
  if (intro) { start('intro', 0, 'ভূমিকা — এই বইটা কেন আলাদা'); continue; }
  if (tail) { start('x_' + chapters.length, -1, tail[1]); continue; }
  if (ch) { start('ch' + ch[1], parseInt(ch[1], 10), ch[2]); continue; }
  if (ap) { start(ap[1].toLowerCase().replace(' ', '_'), -2, ap[1] + ' — ' + ap[2]); continue; }
  if (L.startsWith('# ')) { flush(); continue; }
  if (cur) cur.lines.push(L);
}
flush();

// --- unit tag from the chapter's meta line: `unit: A2.M · level: A2 · ...` ---
function unitOf(ls) {
  for (const l of ls.slice(0, 4)) {
    const m = l.match(/`unit:\s*([\w.]+)\s*·\s*level:\s*(\w+)/);
    if (m) return { unit: m[1], level: m[2] };
  }
  return { unit: null, level: null };
}

// --- markdown-lite → blocks ---
function toBlocks(ls) {
  const blocks = [];
  let tbl = null, para = [];
  const endPara = () => { if (para.length) { blocks.push({ t: 'p', c: para.join(' ') }); para = []; } };
  const endTbl = () => { if (tbl) { blocks.push({ t: 'table', rows: tbl }); tbl = null; } };
  for (const raw of ls) {
    const l = raw.trimEnd();
    if (/^\|/.test(l)) {
      endPara();
      const cells = l.split('|').slice(1, -1).map(c => c.trim());
      if (cells.every(c => /^:?-+:?$/.test(c))) continue; // separator row
      (tbl ??= []).push(cells);
      continue;
    }
    endTbl();
    if (l === '' || l === '---') { endPara(); continue; }
    if (/^#{3,4} /.test(l)) { endPara(); blocks.push({ t: 'h', c: l.replace(/^#+ /, '') }); continue; }
    if (/^[-*] /.test(l)) { endPara(); blocks.push({ t: 'li', c: l.replace(/^[-*] /, '') }); continue; }
    if (/^> /.test(l)) { endPara(); blocks.push({ t: 'q', c: l.replace(/^> /, '') }); continue; }
    para.push(l);
  }
  endPara(); endTbl();
  return blocks;
}

const out = {
  meta: {
    id: meta.id ?? 'bhasha_go_book',
    version: Number(meta.version ?? 1),
    title: meta.title ?? 'Bhasha Go',
    subtitle: meta.subtitle ?? '',
    verified: meta.verified === 'true',
    curriculum_ref: meta.curriculum_ref ?? '',
    built: new Date().toISOString().slice(0, 10),
  },
  chapters: chapters.map(c => {
    const { unit, level } = unitOf(c.lines);
    return { id: c.id, num: c.num, title: c.title, part: c.part, unit, level, blocks: toBlocks(c.lines) };
  }),
};

mkdirSync(join(root, 'assets/book'), { recursive: true });
writeFileSync(join(root, 'assets/book/book.json'), JSON.stringify(out, null, 1), 'utf8');
const numbered = out.chapters.filter(c => c.num > 0).length;
console.log(`book.json: ${out.chapters.length} entries (${numbered} numbered chapters), ` +
  `${out.chapters.reduce((n, c) => n + c.blocks.length, 0)} blocks`);
if (numbered !== 20) { console.error('EXPECTED 20 numbered chapters!'); process.exit(1); }
