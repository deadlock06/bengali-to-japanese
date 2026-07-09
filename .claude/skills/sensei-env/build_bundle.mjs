#!/usr/bin/env node
// build_bundle.mjs — package this skill into an installable `sensei-env.skill`
// (a plain ZIP) with a self-contained snapshot of docs/ as reference/.
// Zero dependencies, cross-platform: uses a tiny built-in ZIP (store) writer.
// Run:  node build_bundle.mjs   -> writes ../../../sensei-env.skill (repo root)

import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join, basename } from 'node:path';

const skillRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(skillRoot, '..', '..', '..');
const docsDir = join(repoRoot, 'docs');
const outFile = join(repoRoot, 'sensei-env.skill');

const entries = [];
const add = (arc, abs) => { if (existsSync(abs)) entries.push([arc, abs]); };
add('SKILL.md', join(skillRoot, 'SKILL.md'));
add('README.md', join(skillRoot, 'README.md'));
for (const f of ['routes.mjs', 'route.mjs', 'token_report.mjs'])
  add(`scripts/${f}`, join(skillRoot, 'scripts', f));
if (existsSync(docsDir))
  for (const f of readdirSync(docsDir).filter((n) => n.endsWith('.md')).sort())
    add(`reference/${f}`, join(docsDir, f));

if (!entries.some(([a]) => a === 'SKILL.md')) {
  console.error('ERROR: SKILL.md not found next to this script.'); process.exit(1);
}

const crcTable = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; }
  return t;
})();
const crc32 = (buf) => { let c = 0xFFFFFFFF; for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; };
const u16 = (n) => { const b = Buffer.alloc(2); b.writeUInt16LE(n >>> 0, 0); return b; };
const u32 = (n) => { const b = Buffer.alloc(4); b.writeUInt32LE(n >>> 0, 0); return b; };

const d = new Date();
const dosTime = ((d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1)) & 0xFFFF;
const dosDate = (((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate()) & 0xFFFF;

const locals = [], central = [];
let offset = 0;
for (const [arc, abs] of entries) {
  const name = Buffer.from(arc, 'utf8');
  const data = readFileSync(abs);
  const crc = crc32(data);
  const local = Buffer.concat([
    u32(0x04034b50), u16(20), u16(0), u16(0), u16(dosTime), u16(dosDate),
    u32(crc), u32(data.length), u32(data.length), u16(name.length), u16(0), name, data,
  ]);
  locals.push(local);
  central.push(Buffer.concat([
    u32(0x02014b50), u16(20), u16(20), u16(0), u16(0), u16(dosTime), u16(dosDate),
    u32(crc), u32(data.length), u32(data.length),
    u16(name.length), u16(0), u16(0), u16(0), u16(0), u32(0), u32(offset), name,
  ]));
  offset += local.length;
}
const centralBuf = Buffer.concat(central);
const end = Buffer.concat([
  u32(0x06054b50), u16(0), u16(0), u16(central.length), u16(central.length),
  u32(centralBuf.length), u32(offset), u16(0),
]);
writeFileSync(outFile, Buffer.concat([...locals, centralBuf, end]));

console.log(`Built ${basename(outFile)}  (${entries.length} files)`);
console.log(`-> ${outFile}`);
console.log('Install it via Settings > Capabilities, or share it as-is.');
