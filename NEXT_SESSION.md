# ▶ NEXT SESSION — READ THIS FIRST (then CODEBASE_MAP.md, then only what your task needs)

You are an AI continuing work on **SENSEI/Bhasago**. Read order:
1. `docs/00_START_HERE.md` — router + NON-NEGOTIABLES (never violate).
2. `CODEBASE_MAP.md` — what exists vs spec (2026-07-09; still mostly accurate, see delta below).
3. `docs/CURRICULUM_MAP.md` + `docs/DESIGN_HANDOFF.md` — the curriculum backbone + buildable screen specs.
4. This file — what the last session did and what to do next.

## Last session (2026-07-10, Claude Fable 5 & Antigravity) — first real compile + agents + dashboard + autonomy UI + content ×5
**Flutter 3.44.5 IS INSTALLED on this machine (`D:\flutter\bin\flutter.bat`).** All checks run for real now.
*Antigravity injected the new UI screens, fixed the `intl` pubspec constraint, and successfully ran `flutter pub get` & `gen-l10n` to finalize the build state.*
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

## Later session (2026-07-10 night, Claude Fable 5) — FIRST SUCCESSFUL DEVICE BUILD + INSTALL
1. **Android toolchain fixed (D-014):** scaffold pinned AGP 8.3.0 / Kotlin 1.9.22 / Gradle 8.7 → device build always failed (Flutter 3.44.5 requires AGP ≥ 8.6). Re-pinned to the installed SDK's own template versions (read from `flutter_tools/.../gradle_utils.dart`): **AGP 9.0.1 / Kotlin 2.3.20 / Gradle 9.1.0** in `android/settings.gradle.kts` + `gradle-wrapper.properties`. All other android/ files already matched the new template byte-for-byte; `gradle.properties` keeps `android.newDsl=false`.
2. **`kotlin.incremental=false` added to `android/gradle.properties`:** Kotlin incremental caches crash when pub cache (C:) and project (D:) are on different drives ("this and base files have different roots"). Machine-specific but harmless everywhere.
3. **Verified end-to-end on TECNO LG7n:** `flutter build apk --debug` ✓ (5.4 min cold) · `adb install -r` ✓ · launch ✓ — Impeller/Vulkan backend, Dart VM service up, no fatal exceptions, process stable; app force-stopped afterwards to save battery. minSdk is 24 via `flutter.minSdkVersion` — already satisfies the ≥23 (SQLCipher) requirement, DO-NEXT #2's minSdk step is moot.
4. Re-verified after all changes: `flutter analyze` 0 issues · `flutter test` 47/47.
5. Remaining from DO-NEXT #2: native bridge stubs (MethodChannel: TTS/STT/LLM/thermal) per 02/08 — the scaffold itself is done and proven.

## Later session (2026-07-10, Claude Fable 5) — WritingScreen short-viewport fix
1. **WritingScreen overflow fixed (D-013):** paper is now `Expanded > Center > AspectRatio(1)` (square = shorter axis, redundant `Spacer` removed) — no overflow in landscape / split-screen / the default 800x600 test surface; portrait rendering unchanged. Chose adaptive layout over a `SystemChrome` portrait lock because Android multi-window ignores orientation preferences — rationale logged in `99_DECISIONS.md` D-013.
2. `test/widget_test.dart`: added a regression test on the default landscape surface (Write tab, no exception); viewport-pin comment updated (pin is now realism, not a safety workaround).
3. Cleared 8 pre-existing analyzer infos that had crept into the working tree (theme const, pitch/writing-painter for-braces, main const, screens interpolation, settings `withOpacity`→`withValues`).
4. Re-verified: `flutter analyze` 0 issues · `flutter test` **47/47**.

## Later session (2026-07-10 late night, Claude Fable 5 / Cowork) — v4 "Bold Ink" design handoff applied
Source: `Shared design file.zip` → `handoff/HANDOFF.md` + 5 step files (from the approved `Home v4.dc.html` Claude design project). **User direction: design-system-first — the Claude design project is the source of truth for UI/UX; code follows it, never improvises; any screen/component may be re-architected by a new design. See `DESIGN_BRIEF.md` (new, repo root) for what to design next.**
1. **Committed the pre-refresh checkpoint first** (`32c5fe1`, ~127 files — everything from the three sessions above), so the design refresh is its own commit. Stale `.git/*.lock` files blocked git (sandbox can't unlink them) → renamed aside as `.git/*.lock.stale*`/`lockjunk*` — safe to delete all of those anytime.
2. **Applied all 5 handoff steps to their spec'd destinations:** `lib/app/theme.dart` (replaced — ink-black + yellow/pink/blue/green token set; old `ai`/`sakura`/`gold` tokens had no usages outside theme.dart, verified by grep), `lib/presentation/home_screen.dart` (new), `lib/main.dart` (replaced — 4-tab shell Home/Learn/Speak/Progress; Kana/Write/Settings are Home-AppBar pushes per the handoff, Review/AI-check pushed from Home cards), `lib/presentation/onboarding_screen.dart` (new, first-run language select), `lib/presentation/progress_screen_v4.dart` (new — ProgressScreenV4 + AiCheckScreen).
3. **Wiring beyond raw copies (all per handoff notes):** `localeChosenProvider` added to `app/providers.dart` (shared_preferences; Keystore stays DB-key-only); step-4 onboarding gate in `SenseiApp` (`chosen==null` → blank frame, else Onboarding/HomeShell, `onDone` → `ref.invalidate`); step-3 TODOs resolved — Home AI card + Progress tab now use the real `AiCheckScreen`/`ProgressScreenV4`. Old `progress_screen.dart` (v0.1 insights dashboard) is **no longer routed** (kept — its T-108 logic feeds V4 later). PitchScreen also unrouted (known handoff follow-up: card inside Speak tab).
4. **Tests updated:** `test/widget_test.dart` rewritten for the v4 shell — 4 destinations (was 6), `SharedPreferences.setMockInitialValues` for the gate, new first-run onboarding test, D-013 landscape regression kept (Write now via Home AppBar icon).
5. **Fonts NOT bundled** (sandbox had no network to font repos): pubspec has a ready commented `fonts:` block with exact file names. Until TTFs exist in `assets/fonts/`, Flutter silently falls back to system fonts — compiles and runs fine.
6. **Verified from sandbox:** validator PASS 0 warnings · agents 17/17 · fsrs 11/11 · lesson_flow 19/19 · migrations 10/10 · pitch 8/8; static grep checks (removed tokens, screen constructors, l10n keys) clean. **`flutter analyze` + `flutter test` NOT run (no Flutter in the sandbox) — run them first thing next session.**
7. **Cowork infra note for future sessions:** when working through the Cowork sandbox mount, WRITE FILES VIA THE SHELL — files written by the desktop file tools can appear truncated to git through the mount (stale size cache). This session hit it and repaired by rewriting the affected files from the shell.

## Later session (2026-07-11, Claude Fable 5 / Cowork) — rev-3/4 handoff: sensei chat, curriculum, book
Source: `Load existing design 2.zip` → handoff rev-4 (prose deltas; step files 1–6 unchanged from rev-2, which a prior session had applied at ~05:00).
1. **Compile fix:** the rev-2 `lesson_screen_v4.dart` referenced `BhasagoTheme.bg/card/muted/text/outline/pillOutline` which didn't exist → added as aliases in `theme.dart` (values mirror `BhasagoColors`; `pillOutline` = #3A3A3A).
2. **SenseiChatSheet (rev-2 §4):** tap the sensei sprite in the lesson → 76% bottom sheet (#141414, 24px top radius): mood-ring 先 avatar + live mood dot, reversed bubble list (student = mood accent bg/#111, sensei = #1A1A1A), pulsing typing dots, quick chips (আবার বুঝিয়ে দাও / একটা উদাহরণ / উচ্চারণ), stadium input + 44px mood-color send FAB + mic voice mode (5-bar waveform + "শুনছি…" → canned transcript). DEMO-CANNED replies — TODO wire AI tutor service; chat is explanatory only, grading stays answer-key (D-001).
3. **CurriculumScreenV4 (rev-3 §1)** — `lib/presentation/curriculum_screen_v4.dart`: red section (#B3121B), JLPT N5 pill, 4px overall bar, vertical unit timeline (done = red dot + check / current = red-outline play + SOLID red card w/ white bar + white stadium "চালিয়ে যাও" → pops to lesson / upcoming = grey schedule icon, neutral card, NO locks). Demo units — TODO T-120 curriculum service; tutor batches must come from current unit.
4. **BookScreenV4 (rev-3 §2)** — `lib/presentation/book_screen_v4.dart`: green section, gradient hero cover (#2E7D5B→#1F5C42, spine #174632, 語 + BHASHA GO) w/ 22% bar, Bengali-numeral chapter tiles (done/current/upcoming). Reader = TODO T-121.
5. **Entries wired (rev-4):** lesson header icon row — `map` → Curriculum (press tint #E8515A), `auto_stories` → Book (tint #35E065), 19px glyphs in 44px hit areas; Home book mini-card (34×44 cover + "অধ্যায় ২ চলছে") above week topics via new `onOpenBook` callback (main.dart pushes BookScreenV4).
6. **Journey test fixed + extended** (`test/user_journey_test.dart`): ambiguous-tap fix (.first on onboarding cards), synced to red AI-ক্লাসরুম card, now drives the classroom (hint/skip), opens the sensei chat (chip → canned reply), closes sheet via descendant finder, quits. Earlier failure log: `test_log.txt` (UTF-16; ambiguous 'English' tap — resolved).
7. **NOT run:** `flutter analyze` / `flutter test` (no Flutter in sandbox) — run first. l10n of new strings still hardcoded BN (design parity), keys listed in handoff rev-2 §3 + rev-3 §3 pending.
Commits: `64a0a07` (pre-rev3/4 checkpoint incl. 4-5AM rev-2 work) → this session's rev-3/4 commit.

## DO NEXT
1. **Run the real checks** (sandbox couldn't): `flutter pub get; flutter gen-l10n; flutter analyze; flutter test`. Expect green; fix anything the static pass missed.
2. **Fonts:** download Baloo Da 2, Zen Kaku Gothic New (Medium/Bold/Black), Archivo, Space Grotesk from Google Fonts → `assets/fonts/` with the exact names in pubspec's commented block → uncomment → `flutter pub get`. The design's whole feel depends on these.
3. **l10n:** new v4 strings are hardcoded BN for design parity — move to `lib/l10n/app_{en,bn,ja}.arb` (add `navHome`, `navProgress`, `home*`, onboarding + progress/AI-check keys) and swap in `S.of` lookups.
4. **PitchScreen entry point:** card inside the Speak tab (waiting on the Speak-tab design — `DESIGN_BRIEF.md` item 2; don't improvise it).
5. **T-108 data into V4:** implement `SrsLocal.retentionByDay()` + per-skill accuracy; point `retentionSeriesProvider` at it (re-import `app/providers.dart` in progress_screen_v4 — TODO marked); add `dueCountProvider` for the pink Home card; real course % on Home. Reuse `lib/domain/progress.dart` (already pure + tested).
6. **Real mock exam in AiCheckScreen:** sample from verified content, grade vs answer key ONLY (00 non-negotiable #4); Banglish suggestion from weak-skill template. Currently a demo coin-flip, clearly TODO-marked.
7. Carry-overs: audio pipeline (T-107) · native bridge stubs (MethodChannel TTS/STT/LLM/thermal) · native-review sign-off on the 64 new phrases · persona + purge-check bootstrap in `main()` · PDF in export ZIP + `share_plus`.

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
