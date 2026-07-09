# SENSEI — Always-On Agent Rules (loaded every session, no trigger needed)

## Project Identity
You are working on **SENSEI** — an offline-first Japanese tutor for Bangladeshi workers
targeting JFT-Basic A2 / JLPT N4. Flutter + Kotlin + llama.cpp.
Target device: Tecno Pova 4 (8 GB RAM, Android). Bengali-first UI.

## 7 NON-NEGOTIABLES (never violate, never re-litigate)
1. **Recommend, never force.** Skip / Pause / Quit always work, everywhere, zero penalty.
   (Parental mode = only guardian-opt-in exception.)
2. **No dark patterns.** No variable rewards, loot, streak-saves, guilt/FOMO copy.
   Rewards are predictable and mastery-based only.
3. **Offline-first.** Every core feature works with zero network at every install tier.
4. **Correctness over generation.** Graded answers = deterministic key match.
   Grammar = retrieved from a verified store. The LLM SELECTS and GLUES, never INVENTS rules.
5. **Data autonomy.** One-tap offline export (ZIP: CSV + JSON + PDF); instant delete with
   7-day grace; no support ticket required.
6. **Bengali-first.** Explanations in Bengali (Banglish register OK). EN/JA optional, never default.
7. **Free tier is genuinely useful.** Premium sells convenience only. No microtransactions.

## Banned patterns (never reintroduce — D-001)
`dopamine engine` · forced output / "speak or die" · loot drops · hidden skip ·
session/screen locks · subconscious triggers · streak-saves / loss copy

## Session Bootstrap (run at start of every work session)
1. Read `NEXT_SESSION.md` (repo root) — last session summary + what to do next.
2. Check `CODEBASE_MAP.md` (repo root). If missing or >2 weeks old → regenerate from `90_EXISTING_CODEBASE.md`.
3. Use the `.agents/skills/sensei-router` skill to pick the correct spec file for your task.

## Work Rules
- Conflict with a NON-NEGOTIABLE → flag it, propose a compliant alternative, don't silently comply.
- Spec is silent → smallest reasonable decision, log in `99_DECISIONS.md`, state you did so.
- Match existing Dart/Kotlin/C++/Python patterns (see `08` appendices).
- **Stack:** Flutter 3.22+ (fvm), Riverpod, sqflite/SQLCipher, Kotlin NDK, llama.cpp, whisper.cpp, Kokoro-82M, FSRS-4.5.
- **Device budget:** <6.5 GB RAM peak, >8 tok/s inference, <2 s cold start, <15%/hr battery.
- **minSdkVersion ≥ 23** — required by SQLCipher + flutter_secure_storage.

## Skills Active in This Project
| Skill name | Triggers on |
|---|---|
| `sensei-router` | SENSEI tasks, spec navigation, "what do I build?" |
| `sensei-flutter` | Dart/Flutter code, widgets, Riverpod, screens, tests |
| `sensei-content` | Lesson authoring, JSON schemas, validate_content, kana/vocabulary |
| `sensei-offline-ai` | llama.cpp, whisper.cpp, Kokoro, FSRS, on-device inference |
| `sensei-database` | SQLite, SQLCipher, migrations, DAOs, SrsLocal |
| `sensei-decisions` | Architecture decisions, trade-offs, logging to 99_DECISIONS.md |
| `sensei-testing` | Tests, proofs, CI/CD, benchmarks |

## File Locations Quick Reference
| What | Where |
|---|---|
| Spec docs | `docs/NN_*.md` |
| Session handoff | `NEXT_SESSION.md`, `CODEBASE_MAP.md` |
| Decision log | `docs/99_DECISIONS.md` |
| Verified content | `assets/content/*.json` |
| Stroke data | `assets/stroke/kana_strokes.json` |
| Flutter source | `lib/` |
| DB migrations | `lib/db/migrations/` |
| Tools/proofs | `tools/*.mjs` |
| CI | `.github/workflows/ci.yml` |
