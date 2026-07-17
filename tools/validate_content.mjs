// Content validator — guardrail behind "never teach wrong Japanese" and
// "never ship dark-pattern copy". Run: node tools/validate_content.mjs
// Maps to the 12 blocking rules in docs/05_CONTENT_SCHEMAS.md §Validation rules.
//   Enforced (blocking): 1 JP↔BN · 5 strict JSON · 6 structure · 7 half-width
//     katakana · 12 banned copy · (4 prereqs & 11 acyclic when those fields exist)
//   Scaffolded (warn/notice until the data/list exists): 2 audio · 3 whitelist ·
//     8 audio-len · 9 images · 10 cultural review · 11 pack_id
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const CONTENT = path.join(ROOT, 'assets', 'content');
const FACTORY = path.join(ROOT, 'content_factory');
const LANGS = ['en', 'bn', 'ja'];

let errors = 0;
const warnings = [];
const err = (f, m) => { errors++; console.log(`  x [${f}] ${m}`); };
const warn = (f, m) => warnings.push(`  ! [${f}] ${m}`);
const nonEmpty = (s) => typeof s === 'string' && s.trim().length > 0;
const triOk = (o) => o && typeof o === 'object' && LANGS.every((l) => nonEmpty(o[l]));
const triStrings = (o) => (o && typeof o === 'object' ? LANGS.map((l) => o[l]).filter(nonEmpty) : []);

// --- optional CI resources (scaffolds) --------------------------------------
function loadLines(file) {
  if (!fs.existsSync(file)) return null;
  return fs.readFileSync(file, 'utf8')
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith('#'));
}
const banned = (loadLines(path.join(FACTORY, 'banned_phrases.txt')) || []).map((s) => s.toLowerCase());
const whitelist = loadLines(path.join(FACTORY, 'jft_a2_whitelist.txt')); // null until authored
const whitelistSet = whitelist ? new Set(whitelist) : null;
// N4 superset list (D-011: whitelist per level — jft_a2 at L0–A2, n4 at N4).
const n4List = loadLines(path.join(FACTORY, 'n4_whitelist.txt'));
const n4Set = n4List ? new Set(n4List) : null;

const HALFWIDTH_KATAKANA = /[｡-ﾟ]/; // rule 7

// Rule 12: banned dark-pattern copy in any user-facing string.
function scanBanned(file, tag, strings) {
  for (const s of strings) {
    const low = s.toLowerCase();
    for (const b of banned) {
      if (low.includes(b)) err(file, `${tag}: banned copy "${b}" in "${s}" (05 rule 12 / D-001)`);
    }
  }
}
// Rule 7: no half-width katakana in learner-facing JP.
function scanHalfwidth(file, tag, jpStrings) {
  for (const s of jpStrings) {
    if (HALFWIDTH_KATAKANA.test(s)) err(file, `${tag}: half-width katakana in "${s}" (05 rule 7)`);
  }
}
// Rules 2/8/9: referenced media must exist (len/dimension checks run in the full pipeline).
function checkMedia(file, tag, item) {
  for (const key of ['audio_path', 'audio_url', 'image_path', 'image_url']) {
    const rel = item[key];
    if (!nonEmpty(rel)) continue;
    const abs = path.join(ROOT, rel.replace(/^\//, ''));
    if (!fs.existsSync(abs)) err(file, `${tag}: ${key} "${rel}" not found (05 rule ${key.startsWith('audio') ? '2' : '9'})`);
    else warn(file, `${tag}: ${key} present — duration/size not verified here (05 rule 8/9, pipeline)`);
  }
}

// --- per-type structural validators -----------------------------------------
function validateKana(file, data) {
  if (!data.verified) err(file, 'missing verified:true');
  if (!nonEmpty(data.source)) err(file, 'missing source');
  const items = data.items || [];
  if (items.length !== 46) err(file, `expected 46 base kana, got ${items.length}`);
  const chars = new Set(), roma = new Set();
  for (const it of items) {
    if (!nonEmpty(it.char)) err(file, `${it.id}: empty char`);
    if (!/^[a-z]+$/.test(it.romaji || '')) err(file, `${it.id}: bad romaji "${it.romaji}"`);
    if (chars.has(it.char)) err(file, `duplicate char ${it.char}`);
    if (roma.has(it.romaji)) err(file, `duplicate romaji ${it.romaji}`);
    chars.add(it.char); roma.add(it.romaji);
    scanHalfwidth(file, it.id, [it.char]);
  }
}

function validateLesson(file, data, reg) {
  if (!data.verified) err(file, 'missing verified:true');
  if (!nonEmpty(data.source)) err(file, 'missing source');
  if (!triOk(data.can_do)) err(file, 'can_do not trilingual');
  scanBanned(file, 'can_do', triStrings(data.can_do));
  const items = data.items || [];
  if (items.length === 0) err(file, 'no items');
  const ids = new Set();
  for (const it of items) {
    const tag = it.id || '(no-id)';
    if (ids.has(it.id)) err(file, `duplicate item id ${it.id}`);
    ids.add(it.id);
    // GLOBAL uniqueness: item ids key the audio manifest + SRS cards — a
    // cross-file collision silently plays the WRONG audio (found 2026-07-17).
    if (reg.itemIds.has(it.id)) err(file, `${tag}: item id also used in ${reg.itemIds.get(it.id)} (audio/SRS key collision)`);
    else reg.itemIds.set(it.id, file);
    if (!nonEmpty(it.jp)) err(file, `${tag}: empty jp`);
    if (!nonEmpty(it.kana)) err(file, `${tag}: empty kana`);
    if (!nonEmpty(it.romaji)) err(file, `${tag}: empty romaji`);
    // rule 1: every learner-facing JP carries a Bengali meaning.
    if (!triOk(it.meaning)) err(file, `${tag}: meaning not trilingual (05 rule 1)`);
    else if (!nonEmpty(it.meaning.bn)) err(file, `${tag}: JP without BN meaning (05 rule 1)`);
    if (!triOk(it.note)) err(file, `${tag}: note not trilingual`);
    if (!Array.isArray(it.srs_words) || it.srs_words.length === 0) err(file, `${tag}: srs_words missing`);
    else for (const w of it.srs_words) reg.srsWords.push({ file, tag, word: w, lvl: data.jlpt_or_jft || '' });
    scanHalfwidth(file, tag, [it.jp, it.kana]);
    scanBanned(file, tag, [...triStrings(it.meaning), ...triStrings(it.note)]);
    checkMedia(file, tag, it);
  }
  // rules 4 & 11: record lesson id, pack_id, prerequisites for the global pass.
  if (nonEmpty(data.id)) reg.lessonIds.add(data.id);
  if (nonEmpty(data.pack_id)) reg.packEdges.push([data.pack_id, data.depends_on || data.pack_deps || []]);
  else warn(file, 'no pack_id (05 rule 11 — required before bundling)');
  if (Array.isArray(data.prerequisites)) reg.prereqs.push({ file, id: data.id, needs: data.prerequisites });
}

function validatePitch(file, data) {
  if (!data.verified) err(file, 'missing verified:true');
  if (!nonEmpty(data.source)) err(file, 'missing source');
  if (!nonEmpty(data.dialect)) err(file, 'missing dialect');
  const items = data.items || [];
  if (items.length === 0) err(file, 'no items');
  for (const it of items) {
    const tag = it.id || '(no-id)';
    if (!nonEmpty(it.word)) err(file, `${tag}: empty word`);
    if (!nonEmpty(it.romaji)) err(file, `${tag}: empty romaji`);
    if (!Array.isArray(it.pattern) || it.pattern.length === 0) err(file, `${tag}: pattern missing`);
    else {
      if (!it.pattern.every((n) => n === 0 || n === 1)) err(file, `${tag}: pattern must be 0/1 per mora`);
      const morae = [...it.word].length;
      if (it.pattern.length !== morae) err(file, `${tag}: pattern length ${it.pattern.length} != morae ${morae}`);
    }
    if (!triOk(it.meaning)) err(file, `${tag}: meaning not trilingual`);
    if (!triOk(it.accent_type)) err(file, `${tag}: accent_type not trilingual`);
    scanHalfwidth(file, tag, [it.word, it.kanji].filter(nonEmpty));
    scanBanned(file, tag, [...triStrings(it.meaning), ...triStrings(it.accent_type)]);
  }
}

// --- global cross-file checks (rules 3, 4, 11) ------------------------------
// Anchors that legitimately satisfy a prerequisite without being a lesson file.
const PREREQ_ANCHORS = new Set(['kana_hiragana', 'kana_katakana']);

function checkPrereqs(reg) {
  for (const { file, id, needs } of reg.prereqs) {
    for (const dep of needs) {
      if (!reg.lessonIds.has(dep) && !PREREQ_ANCHORS.has(dep)) {
        err(file, `prerequisite "${dep}" of ${id} does not resolve (05 rule 4)`);
      }
    }
  }
}

function checkPackAcyclic(reg) {
  if (reg.packEdges.length === 0) return;
  // Union deps per pack: many lessons can share one pack_id, so an edge from any
  // of them belongs to the pack (overwriting would silently drop edges).
  const graph = new Map();
  for (const [pack, deps] of reg.packEdges) {
    const set = graph.get(pack) || new Set();
    for (const d of deps) set.add(d);
    graph.set(pack, set);
  }
  const state = new Map(); // 0=visiting,1=done
  let reported = false;
  const dfs = (node, trail) => {
    if (state.get(node) === 1) return;
    if (state.get(node) === 0) {
      if (!reported) {
        err('pack-graph', `dependency cycle: ${[...trail, node].join(' -> ')} (05 rule 11)`);
        reported = true;
      }
      return;
    }
    state.set(node, 0);
    for (const d of graph.get(node) || []) dfs(d, [...trail, node]);
    state.set(node, 1);
  };
  for (const pack of graph.keys()) dfs(pack, []);
}

// C2 scenarios: verified flag, Bengali everywhere, graph integrity (every
// choice resolves, at least one END reachable), banned-copy scan.
function validateScenario(file, data) {
  if (data.verified !== true) err(file, 'scenario not verified');
  if (!nonEmpty(data.title?.bn)) err(file, 'scenario title.bn missing');
  if (!nonEmpty(data.setting_bn)) err(file, 'setting_bn missing');
  const ids = new Set((data.nodes || []).map((n) => n.id));
  let hasEnd = false;
  for (const n of data.nodes || []) {
    const tag = n.id || '(no-id)';
    if (!nonEmpty(n.npc_jp) || !nonEmpty(n.npc_bn)) err(file, `${tag}: npc line needs jp+bn`);
    if (n.end_bn) hasEnd = true;
    for (const c of n.choices || []) {
      if (!nonEmpty(c.jp) || !nonEmpty(c.bn)) err(file, `${tag}: choice needs jp+bn`);
      if (!ids.has(c.next)) err(file, `${tag}: choice → unknown node "${c.next}"`);
    }
    if (!(n.choices || []).length && !n.end_bn) err(file, `${tag}: dead-end (no choices, no end)`);
    scanBanned(file, tag, [n.npc_bn, n.end_bn || '', ...(n.choices || []).flatMap((c) => [c.bn])]);
  }
  if (!hasEnd) err(file, 'scenario has no ending node');
}

function checkWhitelist(reg) {
  if (!whitelistSet) return; // scaffold: no list authored yet
  for (const { file, tag, word, lvl } of reg.srsWords) {
    // Level-scoped bound (D-011): N4-tagged lessons check the N4 superset;
    // everything else stays inside JFT-A2.
    if (/N4/i.test(lvl) && n4Set) {
      if (!n4Set.has(word)) err(file, `${tag}: "${word}" outside N4 whitelist (05 rule 3)`);
    } else if (!whitelistSet.has(word)) {
      err(file, `${tag}: "${word}" outside JFT-A2 whitelist (05 rule 3)`);
    }
  }
}

// --- run --------------------------------------------------------------------
const files = fs.readdirSync(CONTENT).filter((f) => f.endsWith('.json'));
console.log(`Validating ${files.length} content file(s) in assets/content/`);
console.log(`  banned phrases: ${banned.length} · whitelist: ${whitelistSet ? whitelist.length + ' words' : 'not authored (rule 3 scaffolded)'} · n4: ${n4Set ? n4List.length + ' words' : 'not authored'}\n`);

const reg = { lessonIds: new Set(), packEdges: [], prereqs: [], srsWords: [], itemIds: new Map() };

for (const f of files) {
  let data;
  try { data = JSON.parse(fs.readFileSync(path.join(CONTENT, f), 'utf8')); } // rule 5
  catch (e) { err(f, 'invalid JSON: ' + e.message); continue; }
  const before = errors;
  if (data.type === 'kana') validateKana(f, data);
  else if (data.type === 'lesson') validateLesson(f, data, reg);
  else if (data.type === 'pitch') validatePitch(f, data);
  else if (data.type === 'scenario') validateScenario(f, data);
  else err(f, `unknown content type "${data.type}"`);
  if (errors === before) console.log(`  ok ${f} (${(data.items || []).length} items)`);
}

checkPrereqs(reg);   // rule 4
checkPackAcyclic(reg); // rule 11
checkWhitelist(reg); // rule 3

if (warnings.length) {
  console.log(`\n${warnings.length} warning(s) — non-blocking scaffolds:`);
  for (const w of warnings) console.log(w);
}

console.log(`\n${errors ? `FAIL: ${errors} problem(s)` : 'PASS: all content verified - cleared to ship'}`);
process.exit(errors ? 1 : 0);
