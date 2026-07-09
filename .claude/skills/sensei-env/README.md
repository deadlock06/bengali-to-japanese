# sensei-env — token-saving environment skill for SENSEI

A load-once **router + guardrails** for the SENSEI project. Instead of feeding an
LLM the whole ~15K-token spec every session, it loads one small file (`SKILL.md`,
~1.3K tokens) that carries the non-negotiables and points the model at the ONLY
1–2 spec files a given task needs. Measured savings: **~80–88% fewer tokens** on a
typical task (see `scripts/token_report.mjs`), with the guardrails always present.

## How it saves tokens
```
Old way:  read 00..99 every session            ≈ 15K tokens
This way: SKILL.md (1.3K, once) + the 1 doc     ≈ 2.3K tokens  → ~85% less
```
The router never drops the 7 non-negotiables — they live in the always-loaded
`SKILL.md`, so nothing important is skipped to save tokens.

## Two ways to use it

**A. In-repo (Claude Code / Cursor / any LLM).** It already lives at
`.claude/skills/sensei-env/`. Claude Code auto-discovers it. With any other LLM,
start a session with: *"Read `.claude/skills/sensei-env/SKILL.md` and follow it."*

**B. Installed in Cowork.** Install `sensei-env.skill` (at the repo root) via
**Settings → Capabilities → add skill**. It then auto-loads whenever you work on
SENSEI. (I can build the file, but you click Install — skills can't self-install.)

## CLI helpers (Node, zero dependencies)
```
node scripts/route.mjs "encrypt the local database and add migrations"
    → LOAD: 06_DATABASE.md (~1.5K) · SKIP the rest · ~81% saved

node scripts/route.mjs "new session"      # prints the bootstrap sequence
node scripts/token_report.mjs             # measured savings across sample tasks
```
`route.mjs` reads the live files, so its numbers always reflect the real docs.

## Files
```
SKILL.md              the router + guardrails (this is what loads each session)
scripts/routes.mjs    routing table data (single source of truth)
scripts/route.mjs     task text → exact files to load + measured token cost
scripts/token_report.mjs   measures whole-spec vs per-task token cost
build_bundle.mjs      regenerates ../../../sensei-env.skill (bundles docs/ → reference/)
reference/            (only inside the installed bundle) a snapshot of docs/NN_*.md
```

## Keeping it in sync
`docs/NN_*.md` stays the single source of truth. After editing the docs, rebuild
the installable bundle:
```
node build_bundle.mjs
```
If you add or rename a doc, also add its row to `SKILL.md`'s ROUTER table and its
entry (with keywords) to `scripts/routes.mjs`.
