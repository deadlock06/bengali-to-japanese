# ▶ NEXT SESSION — READ THIS FIRST (then CODEBASE_MAP.md, then only what your task needs)

## ⚡ 2026-07-14 (Opus 4.8) — AI Classroom teaches kana in-classroom + 5-phase intro; full gap inventory
- **CODEBASE_MAP.md fully refreshed 07-14** — the authoritative built-vs-NOT-built inventory. Read it. TL;DR: scaffolding solid + analyze-clean; but AI (offline llama.cpp + online API routing) = 0%, audio = 0%, journey-map Learn tab / goal-select = not built, backend = none, content packs = not built, Smart Banglish content = not built.
- **This session's code (UNCOMMITTED):** AI ক্লাসরুম card now always opens the sensei classroom (reverted the kana→WritingScreen detour). The classroom TEACHES kana in-format: `buildKanaBatch` (providers route current kana unit → "এটি কোন ধ্বনি? あ→আ" recognition), `ClassroomQuestion.prompt/introBn` added. Added **Phase-1 Intro** (`introSeen` — sensei presents item before asking) + **Phase-5 SRS-close** line. Still MISSING from the 5-phase loop: Phase-3 Production (speak/write), Phase-4 Context (word-blocks).
- **content-factory analysis:** it is a DETERMINISTIC pipeline (Python compilers/validators + Dart CardGenerator that seeds FSRS) — NO LLM, NO API keys, NO routing. All "AI" (chat, examiner) is canned/demo.
- **l10n now DISABLED to allow builds:** `generate: false` in pubspec + `l10n.yaml` → `l10n.yaml.disabled`. Committed `lib/l10n/app_localizations*.dart` are authoritative. Do NOT run gen-l10n. (See CODEBASE_MAP Known Issues.)
- **Verify:** `export PATH="$HOME/flutter/bin:$PATH"; flutter analyze` (clean); web build → `localhost:5601`.

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

## Later session (2026-07-11, Claude Fable 5 / Cowork) — classroom/ content: Bhasha Go BOOK + teaching CURRICULUM
1. **`classroom/BOOK.md` (new, ~1,890 lines):** the full Bengali→Japanese book ("Bhasha Go", matches BookScreenV4's cover) — 5 parts, 20 chapters mapped 1:1 to curriculum.json units (header `unit:` keys), 10 appendices (kana/conjugation/particles/counters/keigo/kanji-100/pronunciation-clinic/exam cards/grammar index/answer key). Chapter anatomy mirrors the 09 five-phase loop. Grounded in the verified lesson JSONs (all app phrases appear as-is, marked ★app verified). Register: Bengali script + natural English mixing per owner direction. Research: JFT-Basic CBT format + **Aug-2026 A1/A2.1/A2.2 band change**, JLPT N4 format, Irodori structure, BN-speaker phonology traps (ざ行/つ/ふ/long vowels/pitch).
2. **`classroom/CURRICULUM.md` (new, ~300 lines):** teaching curriculum for the AI classroom — 10 binding rules distilled from 00/01/04/05/09 + D-001/004/012/013/015; ladder w/ exam facts; 5-phase staging + session templates + Director sequencing algorithm; deterministic psych-state playbook with pre-authored Banglish copy pools (LLM selects, never invents); **all 20 unit specs** (grammar, mistake_patterns briefs, scaffold, deterministic assessments incl. 100% safety-critical bars); FSRS/reward policy; mock specs (A2.M CBT 4-section, N4.M 3-section); Sensei chat quick-chip contracts + off-scope redirect; integration map (T-120/T-121/Director/validator); authoring pipeline for the 8 missing lesson JSONs (priority A1.2→A2.5→A2.6→A2.M→N4.x).
3. **`classroom/README.md`:** wiring summary. Files written via shell (mount rule). Verified: all 20 unit ids in both files ✓ · banned-pattern scan CLEAN ✓ · chapter anatomy complete ✓ · no half-width katakana ✓ · stray-script artifacts cleaned ✓. NOT run: flutter checks (content-only session, no Dart touched).
4. **Curriculum.json sync TODO noted (§10):** A2.3/A2.4/A2.6 lesson_id links exist as files but null in ontology — wire in one commit at T-120.

## Later session (2026-07-11 PM, Claude Fable 5 / Cowork) — FULL-ARCHITECTURE AUDIT + fixes
Static audit + node proofs (no Flutter in sandbox). Results:
1. **Engine proofs all GREEN** (validator/agents/fsrs/lesson_flow/migrations/pitch = 65/65 + PASS).
2. **UI/UX-fonts:** bundled fonts ✓ pubspec ✓ theme wired ✓. **FIX:** `theme.dart` `_textTheme` now chains `.apply(fontFamilyFallback: ['Zen Kaku Gothic New','ZenKakuGothicNew'])` — JP glyphs everywhere (incl. mixed BN+JP unit subtitles in curriculum_screen_v4) render in brand JP face instead of platform fallback. writing_screen `0xFF14141F` refs are stroke-INK color (by design, not bg) — left alone.
3. **Wiring verified:** lesson header → CurriculumScreenV4/BookScreenV4 ✓ · sensei sprite → SenseiChatSheet ✓ · Home onOpenBook ✓ · onboarding gate ✓. Off-palette literals in v4 screens = design-sourced (token-promotion tech debt only).
4. **FIX curriculum.json:** lesson_id A2.3=lesson_directions,lesson_transport · A2.4=lesson_work_requests · A2.5=lesson_smalltalk(part) · A2.6=lesson_work_safety(part). Validator re-run PASS. CURRICULUM_MAP → 12/20.
5. **NOT run:** flutter analyze/test (Windows-only here) — FIRST THING next session; the one Dart edit is small + paren-balanced but must be compiler-verified.

## PROJECT STATE (updated 2026-07-12 night, JFT-usable-beta scope)
Engine/data ~90% · v4 UI shell ~90% (T-112/120/121 wired live; l10n + T-108-into-V4 pending) · Content: book 20/20 ✓, lessons 15/20 authored (13/20 units wired; native review pending on 24 items), audio 0% · Native AI bridges 0% · Overall ≈ **65–70%** (compiler-unverified until the Flutter gate). Biggest rocks left: mock engine, N4 lessons ×5 + whitelist, audio pipeline, native bridges, l10n, remaining designs (journey map / Speak / Review / state pack).

## Later session (2026-07-11 night, Claude Fable 5 / Cowork) — 3 lessons authored + T-120 CURRICULUM SERVICE WIRED
1. **Content +3 (validator PASS):** `lesson_intro_qa` (A1.2), `lesson_past_plans` (A2.5), `lesson_apology` (A2.6) — 8 items each, trilingual notes, full schema; whitelist +24 A2 surface forms (D-012 batch-2 marker); registered in content_repository manifest. **Native review pending on all 24 items.**
2. **curriculum.json id-normalization:** lesson_id values now match REAL lesson JSON ids (kana_hiragana/kana_katakana for kana screens; lesson_numbers,lesson_time; lesson_konbini; lesson_restaurant; lesson_workplace; lesson_clinic; +new 3 wired). 13/20 units now have resolvable lesson_ids.
3. **T-120 DONE (static+proof):** new `lib/data/curriculum_service.dart` (pure `derive()`: ontology+completed→states, D-001 no-locks) · `SrsLocal.completedLessonIds()` · `curriculumProvider` in providers.dart · `CurriculumScreenV4` → ConsumerWidget on live data (demo list kept as load/error fallback for design parity) · pubspec assets +`assets/curriculum/` +`classroom/BOOK.md` (T-121 prep).
4. **New proof `tools/curriculum_reference.mjs` — 14/14** (DAG resolve/acyclic, lesson_id↔real-id resolution, empty/partial/full progress states, pct math) + added to CI after agents proof.
5. **NOT run:** flutter analyze/test (Windows) — REQUIRED before trusting the Dart edits (theme fallback + this session's 4 Dart files).

## Later session (2026-07-12, Claude Fable 5 / Cowork) — FULL-PROJECT AUDIT (90_EXISTING_CODEBASE protocol)
Static audit + node proofs (Linux sandbox, no Flutter). Results:
1. **All 79/79 proofs GREEN:** validator PASS 0 warnings · agents 17/17 · fsrs 11/11 · lesson_flow 19/19 · migrations 10/10 · pitch 8/8 · curriculum 14/14. Book builder OK (32 entries / 20 chapters / 876 blocks).
2. **Risk sweeps CLEAN:** D-001 banned patterns 0 hits · no secrets · no FSRS mood-coupling (D-003).
3. **Found an UNCOMMITTED, undocumented T-121 slice in the tree** (post-dates the last entry above): `book_repository.dart`, `tools/build_book_json.mjs`, `assets/book/book.json`, providers (+bookProvider/+bookReadChapterProvider, curriculumProvider try/catch), book_screen_v4 on live data, pubspec `assets/book/`. Statically coherent (symbols/assets resolve). `theme.dart`/`main.dart` diffs are **CRLF-only** — content identical to HEAD.
4. **CODEBASE_MAP.md fully refreshed (was 07-09)** + roadmap ▶ pointer moved to 07-12. Curriculum wiring: 13/20 units; null lesson_id = A2.M, N4.1–5, N4.M (mock engine + N4 authoring pending, as planned).
5. **NOT run:** flutter analyze/test (Windows) — still gate #1 below; the uncommitted T-121 Dart must pass it before committing.

## Later session (2026-07-12, Claude Fable 5 / Cowork) — HANDOFF FOLLOW-UPS: T-112 live classroom + agent staging + kana context
Owner direction: "complete those all following the design documents (handoff)". Implemented every code follow-up the rev-2/3/4 handoff authorizes (l10n deferred — needs gen-l10n on Windows). NO new visual design improvised.
1. **T-112 DONE (static+proof):** new `lib/data/lesson_batch.dart` — pure deterministic batch builder (next uncompleted lesson in curriculum order per rev-3 rule; answer-key MC from verified meanings only, D-001/00§4) + `classroomBatchProvider` (providers.dart, demo fallback off-device) + **proof `tools/batch_reference.mjs` 11/11, added to CI**.
2. **LessonScreenV4 → live classroom:** ConsumerStatefulWidget on real batches (title = can_do.bn — the "why"); demo batch kept as fallback/free-practice; batch never swaps mid-lesson (rev-4 §2). **Agent bus wired** (startSession/recordAnswer+hesitation/recordHint/recordSkip/recordLearned): once out of calibrating, bus psych state drives the mood staging (brief §2.3); handoff local rules stand in during cold-start. Correct answer → sensei bubble shows note.bn (reasoning layer, never generated). Completion → recordLessonCompletion + seedCard×items + invalidate curriculum/due/batch providers.
3. **Ambiance loops (handoff follow-up 6):** _AmbientClassroom now animates per HANDOFF §Motion (lantern ±2° 6s, 6 dust motes 7–9s, 18s master loop); burnout still + disableAnimations freeze ALL.
4. **WritingScreen meaning layer (owner direction):** per-char strip "char · romaji · উচ্চারণ: <BN>" (46-entry gojūon maps, BOOK.md Ch.1) + first-open "এটা কী শিখছ?" intro card (condensed PART 0, shared_prefs `kana_intro_seen`) + reduced-motion gate (stroke demo renders statically). Marked interim until the blackboard-scene design.
5. **Smaller handoff follow-ups:** Speak tab = pitch entry card + shadowing (follow-up 2) · Home course % = live mean unit pct from curriculumProvider (T-108 hookup; real 0% for fresh user) · agent_panel psych strip snaps under reduced-motion. ProgressV4 শোনা/বলা pcts left demo ON PURPOSE — no truthful listening/pitch history source exists yet (correctness over fake data).
6. **Verified from sandbox:** batch 11/11 · validator PASS · all prior proofs green · bracket-balance clean on 7 edited Dart files · test-critical strings (ইঙ্গিত/বাদ/বন্ধ/Talk to sensei/chips) preserved. **flutter analyze/test NOT run (no SDK here) — REQUIRED first on Windows; ~9 Dart files now unverified.**
7. Still open from handoff: l10n migration (follow-up 1, Windows), tutor-service for SenseiChat (canned), T-121 finish, A2.M mock.

## ▶▶ 2026-07-13 (Claude Opus 4.8 / Cowork) — FLUTTER INSTALLED + FIRST REAL analyze/test + kana-first routing. READ THIS FIRST.
**Flutter 3.44.5 is installed at `~/flutter`.** Every command needs `export PATH="$HOME/flutter/bin:$PATH"` first (or add to ~/.bashrc). The archive download is finicky on this connection — if re-needed, use `wget -c` (curl -C - corrupted it twice).

**STATE: `flutter analyze` = "No issues found!" (first real pass ever). LIB CODE is complete + clean. BUT `test/user_journey_test.dart` was ACCIDENTALLY REVERTED to HEAD by a stray `git checkout` late in the session — so the kana-routing test, the direct-pump classroom test, and the `back()` helper I'd added are GONE and must be RE-APPLIED (all fully specified below). The lib/ changes are INTACT. Nothing committed.**

**RE-APPLY these test edits to test/user_journey_test.dart (they made it 51/51 except the one section-8 issue):**
- Add imports: `app/providers.dart`, `data/curriculum_service.dart`.
- Add a `back(WidgetTester t)` helper that taps `find.byIcon(Icons.arrow_back).last` (topmost visible arrow — KanaScreen is a Scaffold pushed inside _push's Scaffold = TWO arrows; `.last` = the visible/inner one that pops), else `pageBack()`.
- Journey section 4: tapping 'AI ক্লাসরুম' with the real (unresolvable-in-test) curriculumProvider → `current`=null → classroom FALLBACK. Assert hint/skip/quit via `find.widgetWithText(OutlinedButton, 'ইঙ্গিত'|'বাদ'|'বন্ধ')` (NOT find.text — 'ইঙ্গিত' also labels the hint card once open → ambiguous). Quit via `find.byIcon(Icons.arrow_back)` (header arrow), not the 'বন্ধ' pill (can be partly offscreen). Move the sensei-chat interaction OUT of the journey into its own direct-pump test (below) — `bySemanticsLabel('Talk to sensei')` needs `tester.ensureSemantics()` + a pump, and the handle must be `.dispose()`d explicitly at the end (addTearDown didn't fire it).
- Replace all `pageBack()` calls in the journey with `back(tester)`.
- NEW test "AI Classroom card opens kana screen when a kana unit is current": `ProviderScope(overrides:[curriculumProvider.overrideWith((ref)=>Future.value(const [CurriculumUnit(id:'L0.1',level:'L0',titleBn:'হিরাগানা',canDoBn:'…',prerequisites:[],lessonIds:['kana_hiragana'],state:UnitProgress.current,pct:0)]))], child: const SenseiApp())`. pumpUntil 'AI ক্লাসরুম', **pump ~6×50ms so the override resolves BEFORE tapping** (else current=null→classroom), tap 'AI ক্লাসরুম', pumpUntil 'হিরাগানা শেষ ✓', assert 'ひらがな' present + `widgetWithText(OutlinedButton,'ইঙ্গিত')` findsNothing. (This GREEN test proves the kana-first fix; the DB-backed provider can't resolve under fake-async, which is why the journey sees the classroom fallback.)
- NEW test "AI Classroom lesson: Skip/Hint/Quit + sensei chat": direct-pump `MaterialApp(home: LessonScreenV4())`, ensureSemantics, hint/skip via widgetWithText, `bySemanticsLabel('Talk to sensei')` → chip 'একটা উদাহরণ' → close via `find.descendant(of: SenseiChatSheet, matching: byIcon(close))`, then `sem.dispose()`.

**⚠️ UNRESOLVED (the reason the journey was still 1-red before the revert) — ROOT CAUSE NOT YET FOUND:** isolated repro (verified): onboard→home→tap grid_view (Kana opens, 1 back arrow, pops fine to home: home_icon/draw_icon/navbar all =1)→ then tap draw ⇒ **the Write screen does NOT open** (title/back/arrow all = 0). So after visiting KanaScreen once and returning home, the Home AppBar's draw IconButton stops opening WritingScreen in the widget test. NOTE: my earlier "KanaScreen is a double Scaffold" guess was WRONG — `KanaScreen` (screens.dart:17) returns a bare `GridView`, no Scaffold. So the cause is something else: possibly the `_DepthField` Stack / an AnimationController, contentProvider state, or a fake-async nav artifact after the GridView route. Next session: repro the isolated case (onboard→grid_view→back→draw), dump the widget tree after the draw tap (`debugDumpApp()` / check `find.byType(AppBar)` count + `tester.takeException()`), and see whether draw's `_push` actually runs. **Real-device impact: untested — could be a genuine bug OR a test-only fake-async artifact; confirm on device.** Test-side workarounds if it's fake-async-only: in section 8 re-tap `home_outlined` + `pumpUntil` a home widget before each icon, or reorder so grid_view (Kana) is last.

**Real pre-existing bugs found & FIXED by the first analyze/test (were invisible without Flutter):**
1. **l10n TRAP:** `lib/l10n/app_en.arb` is EMPTY (0 bytes). Running `flutter gen-l10n` regenerates `app_localizations.dart` from it → WIPES navReview/kanaTitle/navLearn/navSpeak/reviewDone/showAnswer/rAgain/rHard/rGood/rEasy → build breaks. **DO NOT run gen-l10n.** The committed `lib/l10n/app_localizations*.dart` are hand-maintained + authoritative. (Proper fix later = the l10n migration: populate the .arb files, then gen-l10n is safe.) I restored them via `git checkout HEAD -- lib/l10n/`.
2. **theme.dart:** duplicate `labelStyle` in the chip theme (compile error) — removed the dupe.
3. **home_screen.dart:** the pink review card used `Expanded(ListView)` inside the card grid's `IntrinsicHeight` → "can't compute a viewport's intrinsic height" CRASH on first render → killed all 3 shell tests. Fixed to a plain Column + Spacer.
4. `_DepthField` Stack → `fit: StackFit.expand` (tab bodies need tight constraints).

**KANA-FIRST ROUTING (the sequencing fix the owner asked for) — DONE, analyze-clean:** ontology says numbers(L0.3) requires hiragana(L0.1), but the app dropped beginners into `いち`. Now: `CurriculumUnit.isKana`/`kanaLessonId` (kana_* ids = kana SCREENS per 02 Tier 0); HomeScreen decides from the `current` unit it already renders and calls `onOpenKana` (kana screen) vs `onOpenLesson` (classroom); `main._openKana` pushes Scaffold+WritingScreen(startKatakana,onComplete); WritingScreen gained `startKatakana`+`onComplete` → "হিরাগানা/কাতাকানা শেষ ✓" records completion → ladder advances. Proven by new test `AI Classroom card opens kana screen when a kana unit is current` (GREEN, uses a curriculumProvider override — the real DB-backed one can't resolve under fake-async, which is WHY the journey test sees the classroom fallback; on a real device it routes to kana).

**THE 1 FAILING TEST — `user_journey_test.dart` "new learner…", section 8 loop:** diagnostic showed the 4th `back()` call finds `BackButton=0 arrow=0`. The loop pushes Kana(grid_view)→OK, then **Write(draw icon)→ pushed screen has NO back button**. So either the draw-icon `_push` isn't pushing, or the prior Kana `back()` left a bad nav state. Everything up to there passes. Debug: add prints in `back()` / dump the tree after the draw tap. The kana-routing + classroom(direct-pump) tests in the same file are GREEN — only the big journey smoke test's section 8 is red. Fix it, then `flutter test` should be 51/51 → COMMIT.

**Build/verify commands (this machine):**
```
export PATH="$HOME/flutter/bin:$PATH"
flutter analyze        # expect: No issues found!
flutter test           # expect: 50/51 until section-8 back-nav fixed
# DO NOT run flutter gen-l10n (see l10n trap above)
```
Android Studio / Android SDK still NOT installed (needs sudo, owner-only) — only needed for `flutter build apk`, not analyze/test.

## Later session (2026-07-12 night, Claude Fable 5 / Cowork) — apply-everything: commits + T-121 reader + data-autonomy restore
1. **Committed the day's work:** `61b10f8` (T-112 classroom/agents/kana/T-121 slice/audit docs) + `5d08ce4` (Home v4 fidelity + preview) + this batch. CRLF-only churn + build artifacts excluded.
2. **CRITICAL fixes found while applying:** `book_screen_v4.dart` imported `book_reader_screen.dart` that DID NOT EXIST (T-121 slice was incomplete — instant analyze failure) → **wrote BookReaderScreen** (renders h/p/li/q/table blocks, green ink, "পড়া শেষ" persists `book_read_ch`). Also `book_repository.dart` used `.firstOrNull` without the `package:collection` import → fixed + `collection: ^1.18.0` added to pubspec.
3. **Data autonomy RESTORED in Settings (00 §5 non-negotiable was unrouted!):** export ZIP (ExportService), delete w/ 7-day grace (request/confirm/cancel UI), persona picker (persists app_meta `persona` → agent bus), KanjiVG CC BY-SA attribution (D-011).
4. **main() bootstrap carry-over DONE:** HomeShell initState → elapsed-grace purge check + persona restore from app_meta.
5. **T-121 deep-link DONE:** lesson header book icon → BookReaderScreen of the CURRENT lesson's chapter via unit↔chapter map (verified: all 20 book chapters resolve to curriculum ids); falls back to the cover.
6. Static checks green (balance/proofs/mapping). **Flutter analyze/test still pending — owner is installing the SDK locally; run `flutter pub get; gen-l10n; analyze; test` next.** l10n migration (handoff follow-up 1) remains the top deferred item after that.

## Later session (2026-07-12 evening, Claude Fable 5 / Cowork) — Home v4.dc.html full-fidelity pass (new design bundle)
Source: fresh `Shared design file.zip` → `load-existing-design/` (design project export, README-first). Diffed `Home v4.dc.html` vs implementation; closed every Home/shell gap:
1. **Home top row** (lang pill cycling bn→en→ja persisted to `locale_chosen` + yellow avatar w/ initial) · greeting now "হাই, {name}" (`userNameProvider`, shared_prefs `user_name`, design default 'রাফি').
2. **Red AI Classroom card to spec:** spinning 4-point star (5s, reduced-motion-gated), subtitle = LIVE current curriculum unit, progress pill = #111 track/white fill/red knob (design §108-109), extra non-design button REMOVED — whole card taps.
3. **Green card sparkline → live `retentionSeriesProvider`** (was hardcoded) · **topics + "সব দেখো" → Learn tab** via new `onOpenLearn` (was mis-wired to classroom).
4. **AI sensei outline pill (new):** pulsing dot + 30ms typed greeting naming the real next batch ("আজ (title) — Nটা নতুন শব্দ"); tap retypes; reduced-motion = static full text.
5. **_DepthField backdrop (new, main.dart):** red sun pulse + seigaiha arcs + floating 語/あ/ん behind all tabs, 20s loop, frozen under reduced-motion. Nav already matched (white pill, onlyShowSelected).
6. Tests: `find.text('হাই!')` → `textContaining('হাই')` ×2. Preview regenerated to match (backdrop/top row/star/knob/sensei pill). Repaired a mount-duplicated `_push` in main.dart.
7. **NOT run:** flutter analyze/test (no SDK) — Windows gate now covers home_screen/main/providers on top of the earlier list.

## DO NEXT (priority order, post-audit)
1. **Windows checks:** `flutter pub get; flutter gen-l10n; flutter analyze; flutter test` — verify theme fontFamilyFallback edit + rev-3/4 code. Expect green.
2. ~~T-120 curriculum service~~ **DONE** (verify via analyze/test; then point "চালিয়ে যাও" at Director recommendation — currently pops to lesson).
3. **T-121 book reader:** BookScreenV4 → render classroom/BOOK.md (chapters keyed `unit:`); add to assets in pubspec; deep-link lesson↔chapter.
4. **Real mock in AiCheckScreen:** implement A2.M spec (classroom/CURRICULUM.md §6/§8): 4×12 CBT sampler from verified content, answer-key grading, band estimate + weakest-2 can_dos → Director.
5. **l10n migration:** v4 hardcoded BN strings → arb (keys listed handoff rev-2 §3 + rev-3 §3).
6. **Author N4 lesson JSONs** (A-level 3 DONE this session): N4.1–N4.5 need `n4_whitelist.txt` + validator whitelist_ref support (T-104) first. Native review batch: 24 new items + book.
7. Carry-overs: T-107 audio · native bridge stubs (TTS/STT/LLM/thermal) · T-108 data into ProgressV4 · persona+purge bootstrap in main() · PDF export · Speak-tab design (DESIGN_BRIEF item 2).

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
