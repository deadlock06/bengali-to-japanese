# CODEBASE MAP — refreshed 2026-07-12 by Claude (Fable 5, Cowork/Linux sandbox — static audit + node proofs; Flutter checks still pending on Windows)

> **SAME-DAY UPDATE (2026-07-12 PM):** handoff follow-ups implemented — **T-112 ☑** (lesson_batch.dart + classroomBatchProvider + proof 11/11 in CI), LessonScreenV4 = live batches + agent-bus staging + note.bn reasoning, ambiance loops animated (reduced-motion/burnout freeze), WritingScreen kana sound-context + intro card, Speak-tab pitch entry, Home course % live. l10n + শোনা/বলা pcts intentionally open. See NEXT_SESSION.md 07-12 PM entry.
>
> **NIGHT UPDATE (2026-07-12, final):** everything above + Home v4.dc.html full fidelity **COMMITTED** — `61b10f8` / `5d08ce4` / `4bef534`, tree clean. **T-121 ☑ (static):** BookReaderScreen written (was a MISSING import — would have failed analyze), mark-read persists `book_read_ch`, lesson→chapter deep-link (20/20 units↔chapters resolve). **Data autonomy (00 §5) restored in Settings** (export ZIP / delete w/ 7-day grace / persona picker / KanjiVG attribution) + boot purge-check & persona restore in HomeShell. `collection` dep added (book_repository needed it). The stale "uncommitted slice" wording below is historical. **Flutter analyze/test still the gate — owner installing SDK locally.**

> **AUDIT 2026-07-12 RESULTS (all runnable checks GREEN):**
> Proofs 79/79: validator **PASS 0 warnings** · agents 17/17 · fsrs 11/11 · lesson_flow 19/19 · migrations 10/10 · pitch 8/8 · curriculum 14/14. Book builder: `assets/book/book.json` = 32 entries (20 numbered chapters), 876 blocks.
> Risk sweeps CLEAN: banned D-001 patterns (dopamine/loot/streak-save/locks/hidden-skip) 0 hits in lib/+classroom/ · no committed secrets/API keys · no FSRS mood-coupling (D-003 ok).
> **UNCOMMITTED, UNDOCUMENTED T-121 slice found in the working tree** (not in NEXT_SESSION.md): `lib/data/book_repository.dart` + `tools/build_book_json.mjs` + `assets/book/book.json` (new) · `providers.dart` (+bookProvider, +bookReadChapterProvider, curriculumProvider hardened w/ try/catch) · `book_screen_v4.dart` (live data, +210/−93) · `pubspec.yaml` (`classroom/BOOK.md` asset → `assets/book/`). Coherent + validator-consistent; `getMeta`/asset refs resolve. **Commit it after Flutter checks.** `theme.dart` + `main.dart` diffs are CRLF-only (content identical to HEAD — safe to checkout or commit as-is).
> **`flutter analyze` / `flutter test` NOT run (no SDK in this sandbox) — still the first thing on Windows.**

**New session? Read NEXT_SESSION.md first.** Bridge between the v4.2 spec pack and the real repo. Read this INSTEAD of re-exploring (refresh if >2 weeks old or after big changes).

## Stack found
- **Flutter 3.44.5** (installed on the Windows dev machine, `D:\flutter\bin\flutter.bat`; repo root = app root). fvm still NOT set up (spec wants it — low priority now that the SDK is pinned by CI).
- **State mgmt:** Riverpod (`flutter_riverpod ^2.5`).
- **DB:** `sqflite_sqlcipher` (AES-256), key in Keystore via `flutter_secure_storage` (`lib/db/db_key.dart`); numbered migrations m001–m002 (`lib/db/migrations/`, proof 10/10).
- **Android:** real scaffold, **device build + install verified on TECNO LG7n 2026-07-10** — AGP 9.0.1 / Kotlin 2.3.20 / Gradle 9.1.0, minSdk 24 (SQLCipher requirement met). No `cpp/` yet — **native AI bridges (TTS/STT/LLM/thermal) 0%**, MethodChannel stubs pending per 02/08.
- **CI:** `.github/workflows/ci.yml` (tracked) — analyze+test+validator+all reference proofs incl. curriculum.
- **i18n:** gen-l10n ARB en/bn/ja; **v4 screens still hardcode BN strings** (l10n migration pending, keys in handoff rev-2 §3 + rev-3 §3).
- **Backend SDK:** none (D-010 Firebase/Supabase still open).

## Task board reconciliation (IDs mirror 11_ROADMAP_TASKS.md; only rows that changed since 07-09 map)
| Task | Reality | Evidence | Gap / risk |
|---|---|---|---|
| T-101 toolchain/CI/SQLCipher | ☑ | device build 07-10, ci.yml, m001–m002 | fvm only |
| T-102 kana screens | ☑ | writing_screen + KanjiVG (D-011) | attribution confirm (D-011) |
| T-103 FSRS engine+UI | ☑ | fsrs.dart 11/11, SrsLocal wired | — |
| T-104 content validation | ◑ | validator PASS in CI, whitelist +A2 batches (D-012) | N4 whitelist + jsonschema + media rules |
| T-106 lesson micro-loop | ☑ | lesson_screen_v4 + agents wired | — |
| T-107 audio pipeline | ◐ | record/just_audio deps, stubs | OPUS, real record/playback — **biggest untouched rock** |
| T-108 progress dashboard | ◑ | progress.dart proven, v0.1 screen built | **unrouted**; ProgressScreenV4 shows demo data — wire T-108 logic in |
| T-120 curriculum service | ☑ | curriculum_service.dart, proof 14/14, live in CurriculumScreenV4 | "চালিয়ে যাও" → Director recommendation still pending |
| T-121 book reader | ☑ (static) | book_repository + BookReaderScreen + deep-link, committed `4bef534` | compiler-verify on Windows; reader polish later |
| T-401–405 agents | ☑ | lib/agents/ 17/17, wired into lesson | — |
| T-602/603 export+deletion | ◑ | export_service.dart ZIP, 7-day grace | PDF in export; persona+purge bootstrap in main() |
| Native bridges | ✗ | no cpp/, no MethodChannel | 0% — device-gated work |
| Content | ◑ | 19 lesson JSONs + kana×2 + pitch, all verified; book 20/20 ch | **13/20 units wired; null lesson_id: A2.M, N4.1–5, N4.M** (mock engine + N4 authoring); audio 0%; native review pending on 24 newest items |

## Exists but NOT in spec (keep/kill — human decides)
- Pitch pillar (8/8 proof, PitchScreen currently unrouted) — recommend KEEP, route as Speak-tab card per handoff.
- Trilingual UI EN/JA beyond Bengali-first spec — KEEP as optional, BN default (unchanged stance).
- classroom/ (BOOK.md, CURRICULUM.md) — now load-bearing for T-120/121, effectively in-spec.

## Spec violations found
- **None.** Banned-pattern grep clean; rewards fixed (feedback.dart); skip/hint/quit invariant present; streak = neutral count. FIX-A note (prototype gamification) applies only to `prototypes/` HTML, not the app.

## P0 blockers
- None for the sandbox-checkable surface. The only unverified risk: ~5 Dart files changed since the last successful `flutter analyze/test` (07-10). **Run the Windows checks before trusting them.**

## Recommended next 3 tasks (updated 2026-07-12 night)
1. **Flutter gate:** `flutter pub get; flutter gen-l10n; flutter analyze; flutter test` (SDK being installed) — ~14 Dart files changed since the last compile; fix whatever it surfaces.
2. **l10n migration** (handoff follow-up 1): v4 hardcoded BN strings → arb keys (lists in handoff rev-2 §3 + rev-3 §3), then gen-l10n regenerates.
3. **A2.M mock engine** in AiCheckScreen per classroom/CURRICULUM.md §6/§8 (4×12 CBT sampler, answer-key grading, band estimate → Director) — unblocks the A2.M curriculum row.
