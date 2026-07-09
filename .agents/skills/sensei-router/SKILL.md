---
name: sensei-router
description: >-
  Token-efficient spec router for the SENSEI app. Activate when the user asks
  what to build next, which spec file to read, navigating the SENSEI docs, or
  when starting a new SENSEI task without a clear spec area. Maps tasks to the
  exact 1-2 spec files needed instead of loading the full 15K-token spec.
  Also activates on: "00_START_HERE", "what doc", "which spec", "next task",
  "roadmap", "what file", SENSEI router, SENSEI navigation.
---

# SENSEI Spec Router

**Rule:** You've loaded this file. Do NOT load the full spec (~15K tokens).
Use ONLY the spec files your task needs, per the table below.

## ROUTER TABLE

| Task type | Load file | ~tokens | Also load if touching |
|---|---|---|---|
| Product / ethics / UX-policy decisions | `docs/01_CONSTITUTION.md` | 0.7K | `docs/09_UI_STATES.md` |
| System design, new component, dependency | `docs/02_ARCHITECTURE.md` | 0.9K | `docs/03_DISTRIBUTION.md`, `docs/08_OFFLINE_AI.md` |
| Install size, downloads, content packs, P2P | `docs/03_DISTRIBUTION.md` | 1.1K | `docs/02_ARCHITECTURE.md` |
| Agent logic (Director/Persona/Scaffold/Feedback), state bus | `docs/04_AGENTS.md` | 0.9K | `docs/02_ARCHITECTURE.md`, `docs/09_UI_STATES.md` |
| Authoring lessons, SRS cards, mistakes, scenarios | `docs/05_CONTENT_SCHEMAS.md` | 1.0K | — |
| SQL, DAOs, migrations, SrsLocal, SQLCipher | `docs/06_DATABASE.md` | 1.5K | `docs/07_API_SYNC.md` |
| API endpoints, sync, conflict resolution, security | `docs/07_API_SYNC.md` | 0.9K | `docs/06_DATABASE.md` |
| On-device AI (llama.cpp, whisper.cpp, Kokoro, RAG, FSRS) | `docs/08_OFFLINE_AI.md` | 1.4K | `docs/02_ARCHITECTURE.md`, `docs/03_DISTRIBUTION.md` |
| Screens, copy, animation, accessibility, psych-state UI | `docs/09_UI_STATES.md` | 0.9K | `docs/01_CONSTITUTION.md`, `docs/04_AGENTS.md` |
| Tests, CI/CD, benchmarks, UAT, ethical review | `docs/10_TESTING_QA.md` | 0.8K | — |
| "What to build next?" / task board / progress tracking | `docs/11_ROADMAP_TASKS.md` | 1.3K | — |
| Pricing, GTM, marketing, launch, KPIs, costs | `docs/12_BUSINESS_GTM.md` | 1.0K | `docs/01_CONSTITUTION.md` |
| First session / repo audit / "what exists?" | `docs/90_EXISTING_CODEBASE.md` | 0.7K | → writes `CODEBASE_MAP.md` |
| "Why was X decided?" / log new decision | `docs/99_DECISIONS.md` | 0.9K | APPEND-ONLY |

## Session Bootstrap Checklist
Run at the start of every SENSEI work session:
1. `NEXT_SESSION.md` — last session summary + the DO-NEXT list
2. `CODEBASE_MAP.md` — what exists (if missing or >2 weeks old, regenerate)
3. Pick from the DO-NEXT list → use the router above → load ONLY that file

## Helper script (optional)
```bash
node .agents/scripts/route.mjs "your task description"
# prints: recommended file(s) + estimated token cost
```

## Rules
- "Consider" column = load ONLY if the task actually touches that area
- Never preload dependencies by reflex
- Cite file + section when quoting spec (e.g. "per 03 §Tier-2")
- Conflict with NON-NEGOTIABLE → flag it, offer compliant alternative
- Spec is silent → smallest reasonable decision, log in `99_DECISIONS.md`
