# 90 EXISTING CODEBASE — Reconciliation Protocol (RUN THIS BEFORE ANY BUILD TASK)
<!-- READ WHEN: first session in this project, or whenever CODEBASE_MAP.md is missing/stale. ~1K tokens -->

## Situation
A codebase ALREADY EXISTS. The roadmap in 11_ROADMAP_TASKS.md describes the target, not current reality. **Do not assume any task is ☐ todo until this audit has run.** Do not rewrite working code to match the spec cosmetically — reconcile, don't rebuild.

## Step 1 — Map the repo (do this first, cheaply)
Read in this order, nothing more: directory tree (2 levels) → pubspec.yaml → android/app/src/main/cpp (if present) → lib/ top-level structure → any existing README/docs → DB schema/migration files. From this alone, fill the inventory below.

## Step 2 — Produce/refresh `CODEBASE_MAP.md` at repo root
```md
# CODEBASE MAP — generated {date} by {model}
## Stack found: (Flutter version, state mgmt, DB lib, native bridge y/n, backend SDK)
## Task board reconciliation (mirror IDs from 11_ROADMAP_TASKS.md)
| Task | Spec status | Reality | Evidence (file paths) | Gap/risk |
| T-101 | ☐ | ☑/◐/✗ | lib/db/… | e.g. "schema exists but no SQLCipher" |
## Exists but NOT in spec: (list — flag for keep/kill decision)
## Spec violations found: (check against 00 non-negotiables + 99 D-001 banned list:
  grep for: forced, dopamine, loot, lock, streak_save, hidden skip, disabled input)
## P0 blockers: (won't compile / disconnected DB / placeholder keys / dead deps)
## Recommended next 3 tasks:
```

## Step 3 — Update the task board
Edit 11_ROADMAP_TASKS.md statuses (☐→◐/☑) with a one-line evidence note per changed task. Move the ▶ CURRENT POINTER to the first real gap. If existing code conflicts with a decision in 99_DECISIONS.md (e.g., mood-multiplied FSRS ratings = D-003 violation, monolithic asset bundle = D-008), add a `FIX-` task at top priority rather than silently patching.

## Step 4 — Special checks for this project (known risk areas)
- **FSRS:** does any code multiply rating × mood? → FIX per 08/D-003.
- **Assets:** is content bundled monolithically in the APK? → migrate to pack system per 03/D-008 (add FIX task; don't block other work on it).
- **Coercion remnants:** hidden skip, session locks, variable rewards anywhere in UI code? → FIX per D-001.
- **Secrets:** placeholder/committed API keys, unconnected DB → P0, fix before features.
- **STT:** open transcription used for grading? → switch to alignment per D-002.

## Rules
- CODEBASE_MAP.md is the bridge between spec and reality. Every future session: if it exists and is <2 weeks old, read it INSTEAD of re-exploring the repo (that's the token saving). If stale, re-run Steps 1–3.
- Never delete existing code in the audit pass — only map and flag. Kill decisions belong to the human, logged in 99.
