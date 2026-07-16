# SENSEI v4.2 — LLM ENTRY POINT (READ THIS FILE FIRST, THEN ONLY WHAT YOUR TASK NEEDS)

> **You are an AI assistant working on SENSEI. The `docs/` folder is your operating manual — always start here.**
>
> **Read order, every session:**
> 1. **THIS file** (`docs/00_START_HERE.md`) — router + the 7 NON-NEGOTIABLES below.
> 2. **`../CODEBASE_MAP.md`** — what is actually BUILT vs NOT built right now (read instead of re-exploring).
> 3. **`../NEXT_SESSION.md`** — last session's work + what to do next.
> Then load ONLY the `docs/NN_*.md` file(s) your task needs (table below).
>
> Do NOT read the whole spec (~25K tokens / 13 files). This file ≈ 1.5K tokens.
> Spec-silent choice? Make the smallest reasonable one and log it in **`docs/99_DECISIONS.md`**.
> HOW-to-build lives in `docs/` (the spec/target). WHAT-is-built lives in `../CODEBASE_MAP.md`. WHY lives in `docs/99_DECISIONS.md`.

## WHAT SENSEI IS (30 seconds)
Offline-first Japanese tutor for Bengali speakers (Bangladesh/Kolkata) targeting JFT-Basic A2 / JLPT N5-N4 for SSW visa job seekers. Runs on budget Android (Tecno Pova 4, 8GB RAM). Flutter + Kotlin + llama.cpp. Core learning works with ZERO internet. Cloud is optional enhancement only.

## NON-NEGOTIABLES (apply to EVERY task — never violate, never re-litigate)
1. **Recommend, never force.** No locks, no forced breaks, no hidden buttons, no disabled input. Skip/pause/quit always work, everywhere, without penalty. (Parental mode for minors is the ONLY exception and is opt-in by guardian.)
2. **No dark patterns.** No variable rewards, loot boxes, streak saves, guilt copy ("don't waste your progress"), FOMO, or social shame. Rewards are predictable and mastery-based.
3. **Offline-first.** Every core feature (lessons, SRS, scenarios, grading) must work with no network at every install tier (see 03_DISTRIBUTION).
4. **Correctness over generation.** Graded answers = deterministic string/key match. Grammar explanations = retrieved from verified store. The LLM SELECTS and GLUES, it never INVENTS grammar rules.
5. **Data autonomy.** One-tap full export (ZIP: CSV+JSON+PDF, works offline). Instant deletion with 7-day grace. No support ticket needed.
6. **Bengali-first.** All explanations in Bengali. English never used unless explicitly requested.
7. **Free tier is genuinely useful.** Premium sells convenience, never core learning. No microtransactions of any kind.

## FILE MAP — LOAD BY TASK TYPE
| If your task is… | Read | Skip everything else |
|---|---|---|
| Any task (always) | `00_START_HERE.md` + relevant row below | |
| Product/ethics decision | `01_CONSTITUTION.md` | |
| System design, new component | `02_ARCHITECTURE.md` | |
| Install size, downloads, packs, P2P sharing | `03_DISTRIBUTION.md` | |
| Director/Persona/Scaffold/Feedback agent logic | `04_AGENTS.md` | |
| Writing/validating lessons, cards, scenarios | `05_CONTENT_SCHEMAS.md` | |
| SQL, local storage, migrations | `06_DATABASE.md` | |
| Endpoints, sync, conflict resolution | `07_API_SYNC.md` | |
| LLM/STT/TTS/RAG/FSRS implementation | `08_OFFLINE_AI.md` | |
| Screens, states, colors, copy tone | `09_UI_STATES.md` | |
| Tests, benchmarks, UAT, ethical review | `10_TESTING_QA.md` | |
| "What do I build next?" / task board | `11_ROADMAP_TASKS.md` | |
| Pricing, GTM, metrics, costs | `12_BUSINESS_GTM.md` | |
| Product direction / "does this feature fit the vision?" | `13_MASTER_VISION.md` (owner's master prompt; constitution wins on conflict) | |
| Existing repo audit / "what do we already have?" | `90_EXISTING_CODEBASE.md` | |
| "Why was X decided?" / past mistakes | `99_DECISIONS.md` | |

## CURRENT STARTING POINT
- **Codebase already exists.** First action in ANY new session: check for `CODEBASE_MAP.md` at repo root. If missing or >2 weeks old → run the audit in `90_EXISTING_CODEBASE.md` before building anything. Otherwise read the map instead of re-exploring the repo.
- **Target phase:** per reconciled task board in `11_ROADMAP_TASKS.md` (statuses reflect audited reality, not assumptions).
- **Stack:** Flutter 3.22+ (fvm), Riverpod, sqflite/SQLCipher, Kotlin NDK bridge, llama.cpp, whisper.cpp, Kokoro-82M, FSRS-4.5.
- **Target device budget:** <6.5GB RAM peak, >8 tok/s inference, <2s cold start, <15%/hr battery.

## HOW TO WORK (rules for any LLM in this project)
- Cite the file + section when you rely on a spec detail (e.g., "per 03_DISTRIBUTION §Tier-2").
- If a request conflicts with a NON-NEGOTIABLE above → flag it, propose a compliant alternative. Do not silently comply.
- If the spec is silent → make the smallest reasonable decision, log it as a new entry in `99_DECISIONS.md` format, and say so.
- Output code in Dart/Kotlin/C++/Python matching existing patterns in `08_OFFLINE_AI.md` appendices.
- Never reintroduce v4.0 concepts: "dopamine engine", "forced output", "speak or die", loot drops, hidden skip, session locks, subconscious triggers. These are banned words — if you see them in old material, they are stale; the redlines in `99_DECISIONS.md` D-001 govern.
