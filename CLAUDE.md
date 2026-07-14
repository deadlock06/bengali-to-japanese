# SENSEI / Bhasago — AI OPERATING MANUAL (auto-loaded; read before anything)

**⛔ STOP. Before doing ANY work on this project, use the `docs/` folder — it is your operating manual and the single source of truth for HOW to build.**

## Read order — EVERY session, no exceptions
1. **`docs/00_START_HERE.md`** — the router + the 7 NON-NEGOTIABLES. It maps your task → the ONE or TWO spec files to load. Do NOT read the whole spec (~25K tokens); load only what the table says.
2. **`CODEBASE_MAP.md`** (repo root) — what is actually BUILT vs NOT built right now. Read this INSTEAD of re-exploring the repo.
3. **`NEXT_SESSION.md`** (repo root) — what the last session did and what to do next.

Then open ONLY the `docs/NN_*.md` file(s) your task needs (00_START_HERE tells you which).

Tip: the `sensei-env` skill is the load-once agent form of `docs/00_START_HERE.md` — invoking it is equivalent to step 1.

## Hard rules (from docs/00 + docs/99 D-001 — never violate, never re-litigate)
- **Recommend, never force** — Skip/Hint/Quit always work, everywhere, no penalty. No dark patterns, locks, streak-saves, FOMO copy.
- **Offline-first** — every core feature works with no network.
- **Correctness over generation** — graded answers = deterministic answer-key match; the LLM SELECTS & GLUES, never INVENTS grammar/rules.
- **Bengali-first** · **Data autonomy** (1-tap export, instant delete w/ 7-day grace).
- Spec is silent? Make the smallest reasonable choice and **log it in `docs/99_DECISIONS.md`** (append-only, D-xxx format).

## Where truth lives
- **`docs/`** = HOW to build (the spec — the target). Don't rewrite specs to match half-built reality.
- **`CODEBASE_MAP.md`** = WHAT is built (current state). Keep it current when you build.
- **`docs/99_DECISIONS.md`** = WHY things were decided. Append every spec-silent choice.

## Verify on this machine
```
export PATH="$HOME/flutter/bin:$PATH"
flutter analyze        # expect: No issues found!
```
Web build serves the real app at `localhost:5601` (tools/web_server.mjs).
**Do NOT run `flutter gen-l10n`** — l10n is disabled (empty ARBs would wipe the hand-maintained localizations; see CODEBASE_MAP.md → Known Issues).
