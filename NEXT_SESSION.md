# ▶ NEXT SESSION — READ THIS FIRST (then CODEBASE_MAP.md, then only what your task needs)

You are an AI continuing work on **SENSEI/Bhasago**. Read order:
1. `docs/00_START_HERE.md` — router + NON-NEGOTIABLES (never violate).
2. `CODEBASE_MAP.md` — what exists vs spec (2026-07-09; still mostly accurate, see delta below).
3. This file — what the last session did and what to do next.

## Last session (2026-07-10, Claude Fable 5) — first real compile + agents + dashboard + autonomy UI + content ×5
**Flutter 3.44.5 IS INSTALLED on this machine (`C:\flutter\bin\flutter.bat`, not on PATH).** All checks run for real now.
1. **First-ever compile check (DO-NEXT #1 done):** fixed 12 analyzer issues — `nullable-getter: false` added to `l10n.yaml` (S.of non-null), kata-shadowing bug in `writing_screen.dart`, `List<double>` contour in `accent_screens.dart`. `flutter analyze` clean, `flutter test` 45/45.
2. **Four-agent system built (T-401–405):** `lib/agents/` — `agent_state.dart` (contract), `director.dart` + `scaffold_agent.dart` (pure decision fns w/ named thresholds), `persona.dart` (4 voices, deterministic rotation, struggle-softening), `feedback.dart` (fixed rewards: 10 XP/lesson, milestone/10 lessons, level/50 retained words), `agent_bus.dart` (Riverpod StateNotifier, injectable clock, agent_log ring buffer). Wired into LessonScreen (grades recognition+context, hesitation timing, hint/skip signals) + `agent_panel.dart` (psych strip w/ 09 colors, dismissible advice, scaffold offers). Proofs: `test/agents_test.dart` + `tools/agents_reference.mjs` (17/17, added to CI).
3. **Progress dashboard (T-108):** `lib/domain/progress.dart` (pure; buckets/weakness/forecast/retention, `test/progress_test.dart`) + `lib/presentation/progress_screen.dart` (memory map, weak list framed as "focus next", 7-day forecast, neutral activity count). AppBar → insights icon.
4. **Settings + data autonomy (T-602/603 core):** `settings_screen.dart` (locale — moved out of AppBar; persona picker persisted to app_meta; KanjiVG attribution) + `export_service.dart` (ZIP: JSON+CSV+summary via new `archive`+`path_provider` deps) + deletion w/ 7-day grace (request/cancel/purge in SrsLocal; purge check on settings load). **PDF in export still TODO.**
5. **DB migration m002** (`lesson_completions` + `app_meta`) + SrsLocal: srsContext/recentRatings/allCards/activityDays/retainedWordCount/lessonCompletionCount/meta/deletion/exportAll.
6. **Content ×5 (12→76 items):** 8 new lessons (greetings, directions, shopping, transport, emergency, smalltalk, work_safety, work_requests; 8 items each, packs match basics←daily←work DAG) + `lesson_list_screen.dart` (Learn tab now lists ALL lessons grouped by pack; was hardcoded to one lesson). `Lesson.packId` added to models.
7. **Repairs of export-roundtrip damage in working tree:** `tools/validate_content.mjs` was a broken CJS rewrite → restored from HEAD (broken copy in scratchpad); content JSONs had lost `"type"` and kana `verified/source` → restored. Whitelist: +65 A2 surface forms (te/masu/desu forms, loanwords) appended w/ marker comment — existing lessons also needed them.
8. **CI:** agents proof step added; flutter pin 3.24.5→3.44.5 (theme uses DialogThemeData/WidgetState — won't compile on 3.24). NOTE: `.github/workflows/ci.yml` is untracked locally (push token lacked workflow scope — see git log).

## Green (all verified this session, on this machine)
`flutter analyze` 0 issues · `flutter test` 45/45 · validator **PASS 0 warnings** · agents 17/17 · fsrs 11/11 · lesson_flow 19/19 · migrations 10/10 · pitch 8/8.

## DO NEXT
1. **Commit!** Working tree has ~40 files of unverified-by-git work (this + prior session). Nothing is committed since `9087281`.
2. **Android scaffold:** no `android/` yet → `flutter create . --platforms=android`, set **minSdkVersion ≥ 23** (SQLCipher + secure storage), then native bridge stubs (MethodChannel: TTS/STT/LLM/thermal) per 02/08.
3. **Audio pipeline (T-107):** wire `record`/`just_audio` in production step + ShadowingScreen (TODOs marked); OPUS later.
4. **Native-review pass on new lessons:** 64 new phrases are standard textbook Japanese but 05 rule 10 wants human review — log reviewer sign-off, then also record audio.
5. **Persona persistence at startup:** persona loads from app_meta only when Settings opens; load it in main() bootstrap too. Deletion-grace purge check likewise runs only on Settings load — move to app start.
6. **PDF in export ZIP** (`pdf` package) + share sheet (`share_plus`) once android/ exists.

## Open decisions for a human (99_DECISIONS format)
- **D-012 (proposed, this session):** whitelist may be extended with A2-level conjugated surface forms used by verified lessons (validator matches surface forms, not lemmas). Confirm or replace with a lemmatizing validator.
- Confirm D-011 KanjiVG CC BY-SA attribution (now also shown in Settings › Attribution).
- Keep/kill pitch pillar (recommend KEEP).

## Guardrails (00 + 99 D-001) — unchanged
Recommend never force · no dark patterns · offline-first · deterministic grading · Bengali-first · data autonomy. Agent system enforces these structurally (advice is always dismissible; rewards fixed; streak = neutral count).

## Build commands (this machine)
```
& C:\flutter\bin\flutter.bat pub get; & C:\flutter\bin\flutter.bat gen-l10n
& C:\flutter\bin\flutter.bat analyze; & C:\flutter\bin\flutter.bat test
node tools/validate_content.mjs   # + all *_reference.mjs proofs
```
