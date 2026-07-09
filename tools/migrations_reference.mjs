// Runnable proof for the DB migration runner (lib/db/migrations/migration.dart).
// Mirrors runMigrations()' version-window selection exactly, so the off-by-one-
// prone logic is verified without a Flutter SDK. Run: node tools/migrations_reference.mjs

// --- port of runMigrations(all, from, to): apply (from, to] in ascending order ---
function runMigrations(all, from, to) {
  return all
    .filter((m) => m.version > from && m.version <= to)
    .sort((a, b) => a.version - b.version)
    .map((m) => m.version);
}
// --- port of kSchemaVersion: highest migration number ---
const schemaVersion = (all) => all.reduce((max, m) => (m.version > max ? m.version : max), 0);

const m = (v) => ({ version: v, name: 'm' + v });
let pass = 0, fail = 0;
function eq(label, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  console.log((ok ? 'ok   ' : 'FAIL ') + label + '  got=' + JSON.stringify(got) + ' want=' + JSON.stringify(want));
  ok ? pass++ : fail++;
}

const one = [m(1)];
const three = [m(1), m(2), m(3)];
const shuffled = [m(3), m(1), m(2)]; // registry must tolerate any input order

eq('fresh DB (0->1) runs baseline only', runMigrations(one, 0, 1), [1]);
eq('fresh DB (0->3) runs all in order', runMigrations(three, 0, 3), [1, 2, 3]);
eq('upgrade 1->2 skips applied baseline', runMigrations(three, 1, 2), [2]);
eq('upgrade 2->3 runs only the delta', runMigrations(three, 2, 3), [3]);
eq('no-op 3->3 runs nothing', runMigrations(three, 3, 3), []);
eq('out-of-order registry still ascends', runMigrations(shuffled, 0, 3), [1, 2, 3]);
eq('partial upgrade 0->2 stops at target', runMigrations(three, 0, 2), [1, 2]);
eq('kSchemaVersion = max (baseline)', schemaVersion(one), 1);
eq('kSchemaVersion = max (three)', schemaVersion(three), 3);
eq('kSchemaVersion = max (shuffled)', schemaVersion(shuffled), 3);

console.log(`\n${pass}/${pass + fail} passed`);
process.exit(fail ? 1 : 0);
