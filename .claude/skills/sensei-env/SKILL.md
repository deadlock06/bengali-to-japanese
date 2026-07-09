---
name: sensei-env
description: >-
  Project environment + token-efficient documentation router for the SENSEI app
  (offline-first Japanese tutor for Bengali speakers). Load this FIRST on ANY
  SENSEI task: it carries the non-negotiable guardrails and maps your task to the
  ONLY 1-2 spec files you need, instead of reading the full ~15K-token spec.
  Use whenever working in the SENSEI repo or when the user mentions SENSEI, the
  v4.2 spec pack, 00_START_HERE, kana / FSRS / pitch / offline-AI, or edits files
  under lib/ or docs/NN_*.md.
---

# SENSEI — project router & guardrails (load FIRST, every task)

**Why this file exists:** reading the whole spec costs ~15K tokens. This file
(~1.3K) gives you the guardrails plus a map to the ONLY files your task needs —
about 80% fewer tokens per task, with nothing important skipped.

**What SENSEI is:** offline-first Japanese tutor for Bengali speakers
(Bangladesh / Kolkata) → JFT-Basic A2 / JLPT N5–N4 for SSW visa job-seekers.
Budget Android (Tecno Pova 4, 8GB). Flutter + Kotlin + llama.cpp. Core learning
works with ZERO internet; cloud is optional enhancement only.

## NON-NEGOTIABLES — apply to EVERY task, never violate, never re-litigate
1. **Recommend, never force.** Skip / pause / quit always work, everywhere, no penalty. (Parental mode for minors = the only exception, guardian opt-in.)
2. **No dark patterns.** No variable rewards, loot, streak-saves, guilt/FOMO copy. Rewards are predictable and mastery-based.
3. **Offline-first.** Every core feature works with no network, at every install tier.
4. **Correctness over generation.** Graded answers = deterministic key match. Grammar = retrieved from a verified store. The LLM SELECTS and GLUES, it never INVENTS rules.
5. **Data autonomy.** One-tap offline export (ZIP: CSV+JSON+PDF); instant delete with 7-day grace; no support ticket.
6. **Bengali-first.** Explanations in Bengali (Banglish register OK). EN/JA optional, never the default.
7. **Free tier is genuinely useful.** Premium sells convenience only. No microtransactions.

**Banned (stale v4.0) — never reintroduce:** "dopamine engine", forced output / "speak or die", loot drops, hidden skip, session/screen locks, subconscious triggers. If you see these in old material they are stale; `99_DECISIONS.md` D-001 governs.

## How to use this skill (the token rule)
1. You've read this file — that's your guardrails + map. **Do NOT read the whole spec.**
2. Find your task in the ROUTER below and load ONLY those file(s), from `docs/` (in the repo) or this skill's `reference/` (installed). Skip the rest.
3. Helper (optional): `node scripts/route.mjs "<what you're doing>"` prints the exact files + measured token cost; `node scripts/token_report.mjs` shows the measured savings.
4. Cite file + section when you rely on a spec detail (e.g. "per 03 §Tier-2").

## ROUTER — load by task type (~tokens measured, chars/4)
| Your task | Load | ~tok | Consider only if relevant |
|---|---|---|---|
| Product / ethics / UX-policy decision | `01_CONSTITUTION` | 0.7K | 09 |
| System design, new component, add dependency | `02_ARCHITECTURE` | 0.9K | 03, 08 |
| Install size, downloads, content packs, P2P, updates | `03_DISTRIBUTION` | 1.1K | 02 |
| Agent logic (Director/Persona/Scaffold/Feedback), state bus | `04_AGENTS` | 0.9K | 02, 09 |
| Authoring / validating lessons, SRS cards, mistakes, scenarios | `05_CONTENT_SCHEMAS` | 1.0K | — |
| SQL, DAOs, migrations, local storage | `06_DATABASE` | 1.5K | 07 |
| Endpoints, sync, conflict resolution, security/compliance | `07_API_SYNC` | 0.9K | 06 |
| On-device AI (LLM/STT/TTS/RAG/FSRS) impl or tuning | `08_OFFLINE_AI` | 1.4K | 02, 03 |
| Screens, copy, animation, accessibility, psych-state UI | `09_UI_STATES` | 0.9K | 01, 04 |
| Tests, CI, benchmarks, UAT, ethical review | `10_TESTING_QA` | 0.8K | — |
| "What do I build next?" / task board / progress | `11_ROADMAP_TASKS` | 1.3K | — |
| Pricing, GTM, marketing, launch, KPIs, costs | `12_BUSINESS_GTM` | 1.0K | 01 |
| First session / repo audit / "what exists?" | `90_EXISTING_CODEBASE` | 0.7K | writes CODEBASE_MAP.md |
| "Why was X decided?" / change a design / log a decision | `99_DECISIONS` | 0.9K | APPEND-ONLY |

"Consider" = load ONLY if the task actually touches that area. Don't preload dependencies by reflex.

## Session bootstrap (start of a work session)
1. Read `NEXT_SESSION.md` (repo root) — what the last session did and what's next.
2. Check `CODEBASE_MAP.md` (repo root). If missing or >2 weeks old → load `90_EXISTING_CODEBASE.md` and regenerate it BEFORE building. Otherwise trust the map instead of re-exploring.
3. Pick a task from `11_ROADMAP_TASKS.md` → load its router row → build.

## Work rules
- Request conflicts with a NON-NEGOTIABLE → flag it, propose a compliant alternative, don't silently comply.
- Spec is silent → make the smallest reasonable decision, log it in `99_DECISIONS.md` format, say so.
- Match existing Dart/Kotlin/C++/Python patterns (see `08` appendices).
- **Stack:** Flutter 3.22+ (fvm), Riverpod, sqflite/SQLCipher, Kotlin NDK, llama.cpp, whisper.cpp, Kokoro-82M, FSRS-4.5.
- **Device budget:** <6.5GB RAM peak, >8 tok/s inference, <2s cold start, <15%/hr battery.

---
Full human-readable router: `docs/00_START_HERE.md`. This skill is the load-once agent form of it; if you change one, update the other (or run `scripts/route.mjs` which reads the live files).
