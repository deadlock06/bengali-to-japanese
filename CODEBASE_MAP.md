# CODEBASE MAP — full state of the SENSEI/Bhasago build
`refreshed 2026-07-17 (Claude Opus 4.8, Cowork/Linux). Read this INSTEAD of re-exploring.`

**One-line status:** the app is now a **feature-complete offline JFT-A2 → JLPT-N4 tutor**. The full curriculum is authored (L0→N4, 806 items = 104% of ladder), the 5-phase micro-loop is real (Intro→Recognition→Say/Write→Context→SRS), and the vision surfaces exist (journey-map Learn tab, roleplay, mock exams, online sensei). What remains is **not buildable in this sandbox**: a physical-device APK, the native offline-LLM/STT toolchain, human native-speaker review, and launch/payments. Overall ≈ **80%** toward a shippable beta; ~**100%** of what's buildable without a device/native-toolchain/human. Track exact state with `node tools/progress_scale.mjs`.

## Environment (verified 2026-07-17)
- **Flutter 3.44.5 installed** at `~/flutter` → `export PATH="$HOME/flutter/bin:$PATH"` before any flutter cmd.
- `flutter analyze` → **No issues found**. Pure-Dart tests (scenario/gap_fill/mock_exam) **10/10**. Content validator → **PASS**. All 8 node proofs green.
- ⚠️ **`flutter test` (full suite) TIMES OUT in this sandbox** — not a code failure; concurrent Claude sessions on the same box starve the test runner (verified via `ps aux`). Run the full suite from a normal machine as the authoritative gate. Isolated files pass fine.
- **Web build works** with supabase_flutter (`flutter build web --pwa-strategy=none`) — served at `localhost:5601`.
- **Android SDK NOT installed** → no APK here (D2 is owner's machine). iOS not targeted.
- **All work COMMITTED + PUSHED to GitHub** (deadlock06/bengali-to-japanese, through 2026-07-17).
- **Offline LLM downloaded** (Qwen3-1.7B-Q4_K_M + llama.cpp server) at `../.claude/llm/`; `tools/run_local_llm.sh` starts it; web_server proxy fails over to it (D-021). Kept OFF during builds (CPU).

## Stack
Flutter 3.44.5 · Riverpod ^2.5 · sqflite_sqlcipher (AES-256) · **supabase_flutter ^2.8 (cloud sync, D1)** · record ^7 · just_audio · flutter_tts · numbered migrations · gen-l10n **enabled** (l10n migration done) · backend: **SUPABASE (D-018, live w/ RLS)**.

## ✅ Built this session (2026-07-16/17) — the big additions
- **Full curriculum content**: 806 items across 60+ lessons L0→N4 (was ~100). N4 grammar (te-form/plain/potential/give-receive/keigo) authored from the standard canon; `n4_whitelist.txt` (D-020); validator level-scoped. Every item audio'd (969 clips) + book-synced.
- **5-phase micro-loop complete** (`lib/data/lesson_batch.dart` + `lesson_screen_v4.dart`): vocab = Intro→Recognition→**Say-it 🎙️** (record+self-compare, D-002)→**Context 🧩** (boundary-guarded gap-fill)→SRS; kana = …→**Write ✍️**→SRS. Kana batch 71→**106** (yōon/sokuon/long-vowel).
- **Mock-exam engine** (`lib/data/mock_exam.dart`, `mock_exam_screen.dart`, D-A4): JFT 50Q/4-section + N4 39Q/3-section, questions SELECTED from verified store, honest band estimate, recommend-only timer.
- **Journey-map Learn tab** (`journey_map_screen.dart`, C1/D-015) + **goal-select onboarding** (SSW/JLPT/daily — emphasis only, no locks).
- **Roleplay/scenario mode** (`scenario_repository.dart` + `scenario_screen.dart`, C2): 3 verified dialogue trees (konbini/clinic/interview), sensei plays the NPC, entry in Speak tab.
- **StatePack** (`state_pack.dart`, C3): reusable loading/empty/error/offline in Bold Ink — wired into Review, Pitch, Progress.
- **Cloud sync** (`sync_service.dart` + Settings toggle, D1/D-022): supabase_flutter, anonymous auth, opt-in, real srs_cards delta upsert (device-wins). ⚠️ needs owner to enable Anonymous sign-ins to activate.
- **Online sensei fully wired**: dynamic BN↔JP balance by level (D-017), curriculum-aware, page-specific persistent chat history, copy-anywhere explain, offline canned + local-LLM fallback.
- **Tooling**: `tools/progress_scale.mjs` (master tracker, D-019) · `tools/sync_book_vocab.py` · `tools/review_status.mjs` (A5 tracker) · `tools/run_local_llm.sh`.

---

## ✅ WHAT'S BUILT (verified, analyze-clean)

### UI / design
- **v4 "Bold Ink" design system** — theme.dart tokens, 4 brand fonts bundled + wired.
- **Home v4** to full fidelity — top row (lang pill + avatar), greeting, red AI-Classroom card (spinning star, live current-unit subtitle, #111/white/red progress pill), pink review card (live due count), blue AI-check, green retention sparkline (live series), book mini-card, week topics, AI-sensei typed-greeting pill, `_DepthField` backdrop (red sun + seigaiha + floating kana), 4-tab shell.
- **Onboarding** (language select, first-run gate, persisted).
- **Offline Japanese audio** — 306 bundled clips (edge-tts: 71×2 kana + every lesson item), 🔊 + auto-play in the classroom.
- **AI Classroom (lesson_screen_v4)** — the sensei classroom: mood ring (psych states), sensei sprite + speech bubble, MC recognition, Hint/Skip/Quit invariant, sensei chat sheet (canned), completion overlay. **NEW this session:** teaches **kana recognition in-classroom** (এটি কোন ধ্বনি? あ→আ) when the current unit is kana, then flows to vocab; **Phase-1 Intro** (sensei presents item before asking) + **Phase-5 SRS-close** line.
- **Curriculum screen** (red timeline, live from ontology), **Book reader** (T-121, renders book.json chapters, mark-read persists), **Progress v4** (retention chart — শোনা/বলা % still demo), **Review** (v0.1), **Speak** (shadowing + pitch entry, v0.1), **Kana grid + Writing/tracing** (offline stroke animation, sound context, first-open intro), **Settings** (locale, tutor-persona picker, **data autonomy: ZIP export + delete-with-7-day-grace**, KanjiVG attribution).

### Engine / logic (pure, proven by node ports)
- **FSRS-4.5** scheduler (D-003 compliant, no mood-coupling) · **4-agent system** (Director/Persona/Scaffold/Feedback) on a Riverpod bus — deterministic signals only (taps/timing/accuracy), wired into the classroom · **curriculum service** (T-120, DAG, no locks) · **T-112 classroom batch builder** (answer-key MC from verified content; kana recognition batch) · **pitch** F0 engine · **migrations** framework.
- **Kana-first sequencing** — numbers requires hiragana (ontology); the classroom teaches kana first.

### Content / data
- 60+ verified lesson JSONs (**806 items**, L0→N4 — live count via `node tools/progress_scale.mjs`; ALL ≤8-item lessons, validator-clean incl. trilingual + level-scoped whitelist) + kana×2 + pitch + **3 scenario trees** · **Bhasha Go book** 32 chapters incl. 11 app-synced vocab tables (tools/sync_book_vocab.py) · curriculum.json ontology (20 units, no broken refs) · KanjiVG stroke data (46+46 full coverage) · content validator (in CI).

### Platform
- SQLCipher DB + migrations · one-tap ZIP export + 7-day-grace deletion + boot purge check · persona persistence · device build **verified once** on TECNO (07-10).

---

## ❌ WHAT'S NOT BUILT (the real gaps)

### The "AI" — ~0%
- **Offline LLM** — **DOWNLOADED but GATED OFF by default (D-021→D-025):** llama.cpp + Qwen3-1.7B Q4_K_M (../.claude/llm/, tools/run_local_llm.sh) exists, but a raw 1.7B invents grammar → REMOVED from the learner-facing fallback for correctness (D-025). Enable only for dev with `ENABLE_LOCAL_LLM=1`. Offline the sensei falls back to VERIFIED content (explainOffline/handleOfflineChat) or an honest decline — never fabrication. Real offline AI (GBNF+whitelist+RAG on-device) = step D4.
- **Online AI (sensei chat)** — ✅ **WIRED** via a secure same-origin proxy (AiTutorService → /ai/chat → OpenAI gpt-4o-mini, Smart Banglish system prompt). Key stays server-side (tools/web_server.mjs, ENV). Offline/no-key → canned fallback. Still ❌: AI examiner, retrieval/RAG grounding.
- Sensei chat = ✅ real AI (proxy, when key set); AI examiner still canned/demo.
- **MASTER VISION execution slice 1 (13_MASTER_VISION / D-016, 2026-07-16):** ✅ sensei conversationally NARRATES every lesson stage (`_senseiNarration`: open greeting → teach → "এবার ছোট্ট পরীক্ষা" → "এবার হাতে লেখো ✍️" → verified WHY) · ✅ **dynamic BN↔JP language balance** (`learnerLevelProvider` → AiTutorService `_balanceLine`: L0/A1 80-90% BN · A2 50/50 · N4 80-90% JP, D-017) · ✅ stage-13 **next-lesson recommendation** in the done overlay (live ladder, recommend-only). Still ❌ from the vision: real-conversation/roleplay stage, voice-first STT, vocab say-it.
- **Page-specific persistent chat history** (`data/chat_history_store.dart`): every sensei chat surface saves/restores its OWN thread (chatKey `lesson:<id>` / `kana:<char>` / `explain:<text>`; 40-turn cap; 🗑 clear per page; '· সংরক্ষিত' badge).
- **ONE unified sensei chat** (`presentation/sensei_chat_sheet.dart`) — used both in the AI Classroom (tap the sensei) AND from **copy-anywhere ব্যাখ্যা**. Select text on any reading surface → floating sensei button (`selection_explain.dart`, ConsumerWidget) → opens the same chat *seeded* with that text: he explains it (dictionary format for JP, plain explanation for names/Bengali/other — never refuses), then you keep chatting (follow-up chips + per-message Bengali TTS "শুনি"). Passes the learner's **current curriculum unit** as a hint so answers match their level. `explain_sheet.dart` is now a thin launcher for it.
- **STT** (whisper.cpp) — 0% · **TTS** (Kokoro) — 0% · **RAG/embeddings** — 0%.
- NOTE: the "content factory" is a **deterministic pipeline** (no LLM by design), NOT an AI generator.

### Audio & speech — recognition audio ✅, speaking ❌
- ✅ **Bundled offline Japanese audio** — 238 edge-tts clips (46+46 base kana + 46 voiced/handakuten + lesson words), 🔊 in the classroom + auto-play on Intro (tools/generate_audio.py).
- ✅ **Kana recognition = full 71** (46 base **+ 25 dakuten ゛/handakuten ゜**, with a teaching note on the mark) — `buildKanaBatch` now meets the L0.1 46+25 assessment (classroom/CURRICULUM.md §6). Still ❌: yōon combos (きゃ), sokuon っ, long-vowel ー; katakana name-builder/shape-family drills.
- ✅ **Classroom ↔ Writing connected** — a base kana's Intro card shows an interactive **✍️ হাতে লিখে দেখাও** button (`_writeBtn`) that opens `WritingScreen` **focused on that character** (`startChar`). Arch-faithful (02 Tier-0): offline finger-draw + stroke-order animation + **bundled pronunciation 🔊** (deterministic, no network); handwriting is never AI-graded. Plus an **optional online-AI "সেনসেইকে জিজ্ঞেস"** button → the unified sensei chat (mnemonic/stroke/pronunciation help, offline canned fallback) — explanatory only (D-001/D-013).
- ❌ Still: record-and-compare pronunciation (speaking), OPUS, sentence-level audio.

### Content gaps
- **Smart Banglish** corporate code-switching content — not built (schema + lessons TODO).
- Lessons: **NO STUBS LEFT (2026-07-16)** — all 21 wired lessons have 8 items (vocab 100→168; ladder 24%→33%). 3 NEW lessons authored (numbers_big / week / food) + 7 expanded (numbers, time, work_intro, konbini, restaurant, workplace, clinic) — standard Irodori/JFT survival set, SSW-focused notes (halal-check, 報連相, heat-stroke). Every item: Intro+why → Recognition → SRS + bundled audio (306 clips). Design rule: **≤8 items per lesson file** (= one classroom session; the batch builder caps at 8 and would silently drop extras) — grow units by adding lesson FILES to the unit's comma list, never by making a lesson bigger.
- **Book ↔ classroom parity (2026-07-16):** every unit chapter of বাংলা গো (assets/book/book.json) now ends with an auto-synced '📱 ক্লাসরুম শব্দভাণ্ডার' table = the unit's FULL lesson vocabulary (168 rows). Regenerate with `python3 tools/sync_book_vocab.py` after ANY content change (idempotent; authored prose untouched).
- Still ❌ content: A1/A2 to full targets (~need +250 items via new lesson files) · **N4.1–N4.5 + both mocks not authored** (need N4 whitelist + verified grammar; do NOT auto-generate — D-001 correctness) · **native-speaker review pending on ALL content before publish**.
- **Mock exams** A2.M / N4.M — not built (AiCheck is demo).
- **Scenario mode** (NPC roleplay, 200+ target) — not built.
- Mistake-pattern remediation (500+ target) — schema only.
- **Native-speaker review** of content — pending (human-gated).

### Classroom loop (09 5-phase — 4 of 5 for kana, 3 of 5 for vocab)
- ✅ **Phase 3 Production for KANA** — after a correct recognition the learner WRITES the character in-lesson (`writingPhase` + `KanaTracePad`: trace pad w/ stroke-order ▶, height-capped, offline). Skip still works (D-001). Proven by test/kana_writing_phase_test.dart.
- ❌ Phase 3 for VOCAB (say-it speaking drill) — not built.
- **Phase 4 Context** (word-block sentence building) — not built.
- (Intro + Recognition + SRS-close done earlier.)

### The Learn experience (owner's own #1 — DESIGN_BRIEF)
- **Goal-select onboarding** (SSW / JLPT / daily life) — not built.
- **Journey map** (Learn tab = stylized Japan map, regions, passport stamps) — **not built. Biggest missing UX.**
- **State pack** (loading/empty/error/offline) — built for **zero** screens.
- Speak / Review / Settings / Kana screens still v0.1 styling.

### Backend / sync / data
- **Backend = SUPABASE (D-018, 2026-07-16)** — live Postgres 17 (Tokyo), `supabase/schema.sql` v1 applied: profiles/srs_cards/lesson_completions/daily_stats/deletion_requests, **RLS own-rows-only on every table** (verified). Creds OUTSIDE repo (`../.claude/sensei_db.env`). Still ❌: client wiring (supabase_flutter + auth + SyncService — needs the project's ANON KEY, not the DB password), offline_queue drain, /ai/explain smart-router as Edge Function, PDF export, opt-in analytics.

### Distribution — ~0%
- Content **bundled monolithically**; tiered download / content-pack system (03 / D-008) — not built · P2P import + update system — stubs only.

### Business / launch (doc 12)
- Premium/Pro tiers, payments, SSW agency — 0% · **on-device benchmarks** (Phase-0 spikes: >8 tok/s, thermal, battery) — device-gated, not done · UAT — not done.

### Accessibility
- reduced-motion — mostly done · screen-reader labels — partial · high-contrast mode — not built.

---

## ⚠️ KNOWN ISSUES / TRAPS (read before touching these)
1. ~~l10n broken + DISABLED~~ **RESOLVED 2026-07-17.** The l10n migration is done: `lib/l10n/app_{bn,en,ja}.arb` now carry the ~20 strings the code uses, `pubspec generate: true`, `l10n.yaml` restored. `flutter gen-l10n` regenerates `app_localizations.dart` correctly (verified: getters preserved, analyze clean, build passes) — it no longer wipes anything. Adding a NEW localized string = add its key to all three ARBs (template = app_en.arb).
2. ~~Journey smoke test red~~ **FIXED** — tests are 50/50 green. (Section-8 note: a push→pop→push loop is flaky under fake-async; the test asserts affordances + one push+pop instead.)
3. **Screenshots of the running web app time out** — canvaskit never idles with the animations, so the automated screenshot tool can't capture it; the app is fine live in the browser.
4. **Analyze/test don't auto-run gen-l10n; build/run DO** — that's why analyze was green but `flutter build web` first failed on l10n until disabled.

## Recommended next 3 (highest impact on how it *feels*)
1. **Audio** — bundle/record word audio + playback so learners can hear Japanese (biggest felt gap; some is device/asset work).
2. **Journey-map Learn tab** + goal-select onboarding (owner's #1 design priority) — design-first, then build.
3. **Online AI routing** (owner provides a key) — make the sensei chat actually generate (Smart Banglish), SELECT-and-glue only to stay spec-compliant.
Then: commit the uncommitted work, re-apply the journey test, l10n migration, Phase 3/4 of the classroom, mock-exam engine.
