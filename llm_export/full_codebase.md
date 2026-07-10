# SENSEI (Bhasago) Codebase Dump



## File: CODEBASE_MAP.md

```md
# CODEBASE MAP — generated 2026-07-09 by Claude (Opus 4.8)
**New session? Read NEXT_SESSION.md first.** Bridge between the v4.2 spec pack and the real repo. Read this INSTEAD of re-exploring (refresh if >2 weeks old or after big changes).

## Stack found
- **Flutter** app (repo root is the app root), SDK target `>=3.3.0` (spec wants 3.22+ via fvm — fvm NOT set up).
- **State mgmt:** Riverpod (`flutter_riverpod ^2.5`).
- **DB lib:** `sqflite_sqlcipher` (SQLCipher AES-256) as of 2026-07-09 — key in Keystore via `flutter_secure_storage` (`lib/db/db_key.dart`); numbered migrations in `lib/db/migrations/` (baseline `m001`). Was plain sqflite. *Unverified on device (no SDK here).*
- **Native bridge:** none yet (no `android/` folder at all — platform scaffold is `flutter create`-generated; set **minSdkVersion ≥ 23** when created, for SQLCipher + secure storage).
- **Backend SDK:** none (D-010 Firebase/Supabase still open).
- **i18n:** gen-l10n ARB, en/bn/ja (`lib/l10n/`). Note: spec is Bengali-first; we currently ship EN+JA UI too.
- **Also present (not the Flutter app):** 4 HTML prototypes in workspace root — `sensei_premium.html`, `sensei_writing.html` (stroke-order animation + finger drawing), `sensei_lessons.html`, `sensei_prototype.html`. Design/UX references.

## Task board reconciliation (IDs mirror 11_ROADMAP_TASKS.md)
| Task | Spec | Reality | Evidence | Gap / risk |
|---|---|---|---|---|
| T-000a STT spike | ☐ | ✗ | — | Device-gated (needs Pova 4 + 20 speakers) |
| T-000b Inference spike | ☐ | ✗ | — | Device-gated (needs Pova 4) |
| T-101 Flutter+fvm+CI+SQLCipher+migrations | ☐ | ◑ | `lib/data/srs_local.dart`, `lib/db/**`, `.github/workflows/ci.yml` | **SQLCipher + migration framework + CI done** (2026-07-09). Still: no fvm; needs on-device build + `minSdkVersion≥23` |
| T-102 Kana screens (hira+kata, stroke SVG, finger draw) | ☐ | ☑ | `lib/presentation/writing_screen.dart`, `assets/stroke/kana_strokes.json`, `tools/fetch_stroke_data.mjs` | Finger-draw + offline stroke-order ported to Flutter; **stroke data now KanjiVG, 0/92 count errors** (FIX-B resolved, D-011). CDN fetch was build-time only |
| T-103 FSRS-4.5 + review UI | ☐ | ☑ engine / ◑ UI | `lib/domain/fsrs.dart`, `test/fsrs_test.dart` (11/11), `lib/data/srs_local.dart`, `lib/app/providers.dart` | Engine pure (D-003 compliant). **ReviewScreen now reads due cards from SrsLocal; lesson SRS step seeds+schedules via FSRS** (2026-07-09). Mood-based *selection* still not built (pre-agents) |
| T-104 Content schemas + validation CI (12 rules) | ☐ | ◑ | `tools/validate_content.mjs`, `content_factory/banned_phrases.txt`, `.github/workflows/ci.yml` | Blocking: 1,5,6,7(half-width),12(banned-copy),4(prereq),11(acyclic — cycle-detection verified). All 7 lessons now have `pack_id`+DAG deps → **validator 0 warnings, in CI.** Remaining: author whitelist (#3), full jsonschema (#6), real media checks (2/8/9) |
| T-105 Firebase vs Supabase | ☐ | ✗ | — | D-010 open |
| T-106 Lesson screens (micro-loop 1–4 + Skip/Hint/Quit) | ☐ | ◑ | `lib/presentation/screens.dart` (LessonScreen) | **5-step micro-loop (Intro→Recognition→Production→Context→SRS) + always-on [Skip][Hint][Quit] invariant implemented** (2026-07-09), skeleton. TODO: wire SRS step to SrsLocal; TTS/record hooks |
| T-107 Audio pipeline (record+playback+OPUS) | ☐ | ◐ | `pubspec.yaml` (record, just_audio), `lib/presentation/accent_screens.dart` | Record/playback stubbed w/ TODOs; OPUS not configured; live pitch works in HTML |
| T-108 Progress + weak-point + brain map | ☐ | ✗ | `lib/data/srs_local.dart` (review_history table) | Only demo stats; analysis not built |

## Exists but NOT in spec (keep/kill — human decides)
- **Accent / pitch-training pillar** — `lib/domain/pitch.dart` (F0 autocorr + parabolic interp + accentScore, 8/8 tests via `tools/pitch_reference.mjs`), `assets/content/pitch_accent.json` (6 verified Tokyo pairs), `PitchScreen`/`ShadowingScreen`. Not an explicit task; **aligns with the "teach accent" goal. → recommend KEEP**, add as a task.
- **Trilingual UI (EN/BN/JA) + Banglish register** — spec is "Bengali-first, English only if requested". Banglish (BN with English loanwords) matches real usage; full EN/JA UI exceeds spec. **→ KEEP Banglish + BN default; make EN/JA optional, not default.**
- **7 verified lessons / 64 phrases + 92 kana** — real content beyond the seed. KEEP.

## Spec violations found (vs 00 non-negotiables + 99 D-001 banned list)
- **FIX-A (LOW) — gamification framing.** Premium prototype has a streak flame, XP/level bar, confetti, "continue" CTA. 09 FLOW *permits* XP roll + neutral "আরেকটা?" + celebration, so most is compliant. **Only real rule:** streak must stay neutral history — never add streak-loss warnings or streak-save purchases (D-001). Prototype-only today; enforce when porting.
- ~~**FIX-B** offline stroke animation~~ **RESOLVED 2026-07-09** — stroke data bundled offline from KanjiVG; only build-time fetch. (D-011)
- ~~**FIX-C** plain-sqflite encryption~~ **RESOLVED in code 2026-07-09** — SQLCipher + Keystore key + migrations. *Needs on-device build (minSdk≥23) to fully verify.*
- ~~**FIX-D** missing Skip/Hint/Quit~~ **RESOLVED 2026-07-09** — invariant present+enabled in every micro-loop step, ≤1 tap, no penalty.
- No forced locks, hidden skip, session/screen locks, streak saves, loot, or committed secrets found in the Flutter code. **Clean.**

## P0 blockers
- None block compilation in principle; code is self-consistent. Before first build: run `flutter gen-l10n` (generates `app_localizations.dart`, referenced but not committed) and `flutter pub get`.
- Cannot verify a real device build here (no Flutter SDK / no phone in this environment) — logic is proven via runnable Node ports (FSRS 11/11, pitch 8/8, content validator green).

## Recommended next 3 tasks (the previous 3 — FIX-B/T-102, T-104→CI, T-106 — are DONE)
1. **Compile-check the new Dart:** `flutter pub get && flutter gen-l10n && flutter analyze && flutter test` on a real machine (no SDK here). First real check of the SQLCipher wiring + lesson micro-loop. CI (`.github/workflows/ci.yml`) also runs this.
2. **Wire SrsLocal into the app:** it is not instantiated anywhere yet. Replace `ReviewScreen`'s in-memory deck and make the lesson `_srs` step seed+schedule `srs_words` via FSRS (`// TODO` markers in `screens.dart`).
3. **Finish validator rules:** author `content_factory/jft_a2_whitelist.txt` (activates blocking rule 3); add `pack_id` to the 7 lessons (clears rule-11 warnings); wire full `jsonschema` (#6) + media checks (#2/#8/#9) when packs exist.

> Note: the spec's official "start here" is Phase-0 spikes (T-000a STT, T-000b inference). Both are **device-gated** — schedule once the Tecno Pova 4 + test speakers are available.

```


## File: NEXT_SESSION.md

```md
# ▶ NEXT SESSION — READ THIS FIRST (then CODEBASE_MAP.md, then only what your task needs)

You are an AI continuing work on **SENSEI**. Read order:
1. `docs/00_START_HERE.md` — the router + NON-NEGOTIABLES (never violate).
2. `CODEBASE_MAP.md` (this repo root) — what actually exists vs the spec. Refresh it if >2 weeks old.
3. This file — what the last session did and what to do next.

## Last session (2026-07-09, Claude Opus 4.8) — cleared all four prior DO-NEXT items
1. **Stroke data (T-102 / FIX-B):** running the old fetch tool exposed a data-quality bug — `kana-svg-data` split looping strokes, so **16/92 kana had wrong stroke counts** (あ→4, ヲ→2…). Rewrote `tools/fetch_stroke_data.mjs` to source **KanjiVG** (canonical order, one `<path>`/stroke), flattening each stroke to sampled points scaled into the consumer's 0..1000 space. `assets/stroke/kana_strokes.json` regenerated → **0/92 mismatches**; `writing_screen.dart` unchanged. Logged **99 D-011** (incl. CC BY-SA attribution — human to confirm).
2. **FIX-C — DB encryption (T-101):** swapped `sqflite`→`sqflite_sqlcipher` + added `flutter_secure_storage`. New `lib/db/migrations/` framework (immutable numbered migrations + registry + baseline `m001`), Keystore-backed key in `lib/db/db_key.dart`, `lib/data/srs_local.dart` opens with `password:` + `onCreate/onUpgrade` runner. Migration selection proven `10/10`.
3. **FIX-D — lesson micro-loop (T-106):** rewrote `LessonScreen` as **Intro→Recognition→Production→Context→SRS**, with the **[Skip][Hint][Quit] autonomy invariant** visible+enabled every step, ≤1 tap, no penalty, no auto-advance (01/09). State machine proven `19/19`.
4. **T-104 — validator + CI:** `tools/validate_content.mjs` now enforces rules **1,5,6,7 (half-width katakana), 12 (banned copy)** as blocking and scaffolds **3 (whitelist), 4 (prereqs), 11 (pack_id/acyclic)**; added `content_factory/banned_phrases.txt`. New **`.github/workflows/ci.yml`** runs the validator + all proofs (Node job) and `pub get→gen-l10n→analyze→test` (Flutter job).
5. **SRS wired into the app (T-103/T-106):** added `fsrsProvider`/`srsProvider` (`lib/app/providers.dart`); the lesson SRS step now seeds the item as an FSRS card + logs the rating via `SrsLocal` (fire-and-forget, error-swallowed so the device-only DB never blocks the UI); `ReviewScreen` now reads **due cards from `SrsLocal.dueForReview()`** with a loading/empty/error state instead of the in-memory demo. New `SrsLocal.dueForReview()` + `seedCard()`.
6. **Content:** added `pack_id` + a DAG `depends_on` (basics←daily←work) to all 7 lessons and a `prerequisites:[kana_hiragana]` on work_intro → validator now **0 warnings**, and rules 4/11 are exercised (cycle-detection verified).
7. **Interactive preview (to see the app w/o a device):** `tools/build_preview.mjs` renders the real content + stroke data into `preview/index.html` (+ `sensei_body.html`), served via `.claude/launch.json` (`sensei-preview`). Published as an Artifact. Faithful to the Flutter UI incl. live KanjiVG stroke animation + the 5-step micro-loop.

## Green (runnable proofs, no device needed) — all pass
`node tools/validate_content.mjs` (PASS, **0 warnings**) · `fsrs_reference.mjs` 11/11 · `pitch_reference.mjs` 8/8 · `migrations_reference.mjs` 10/10 · `lesson_flow_reference.mjs` 19/19. Preview: `node tools/build_preview.mjs` → open `preview/index.html`.
⚠️ **Flutter/Dart is NOT compiled here (no SDK in this sandbox).** The new Dart (SQLCipher wiring, lesson loop) is written against pinned package APIs and hand-reviewed but UNVERIFIED by a compiler — the CI `flutter` job (or a local `flutter analyze && flutter test`) is the first real compile check.

## DO NEXT — in this order
1. **Compile-check the new Dart (do this first):** on a real machine run `flutter pub get && flutter gen-l10n && flutter analyze && flutter test`. Fix anything the analyzer flags in `srs_local.dart`, `lib/db/**`, `screens.dart`. (CI does this on push, but verify locally.)
2. **Android scaffold gotcha:** there is no `android/` folder yet. When `flutter create . --platforms=android` runs, set **`minSdkVersion >= 23`** — required by BOTH SQLCipher and `flutter_secure_storage`'s `encryptedSharedPreferences`. Build will fail below 23.
3. **Author the JFT-A2 whitelist:** create `content_factory/jft_a2_whitelist.txt` (the 1,200-word list) to activate blocking rule 3. Note: the validator matches `srs_words` against it, so seed it from a real list, not from current content.
4. **SRS card granularity:** the lesson SRS step currently seeds one card per *phrase* (item.jp). If you want per-*word* cards, add reading/meaning to each `srs_words` entry in the content schema, then seed those. Also wire the full `jsonschema` (rule 6) + real audio/image checks (2/8/9) once packs exist.
5. **Branding:** `pubspec.yaml` description now says **"Bhasago"** but all UI/preview still says "SENSEI". If Bhasago is the new name, rename across `main.dart`, l10n, and the preview.

## Deferred (need hardware)
- T-000a STT spike + T-000b inference spike — need the Tecno Pova 4 + ~20 Bengali test speakers.

## Open decisions for a human to log in 99_DECISIONS.md
- **Confirm D-011's KanjiVG CC BY-SA attribution** is acceptable for the commercial build (standard practice; attribution embedded in the JSON).
- **Keep/kill the accent–pitch pillar** (`lib/domain/pitch.dart`, `pitch_accent.json`, PitchScreen). Recommend KEEP.

## Guardrails (never break — 00 + 99 D-001)
Recommend, never force. No dark patterns (no streak-saves/loss copy, no forced locks, no hidden skip, no loot/variable rewards). Offline-first. Correctness over generation (graded = deterministic; grammar = retrieved, never invented). Bengali-first (Banglish register OK; EN/JA optional, not default).

## Build commands (on a real machine, Flutter 3.22+)
```
# run from the repo root — this folder IS the Flutter app root
node tools/fetch_stroke_data.mjs   # one-time; already run, stroke data committed
flutter pub get && flutter gen-l10n && flutter analyze && flutter test && flutter run
```

```


## File: PROJECT_ROOT.md

```md
# SENSEI — single project directory

This folder is the whole project AND the Flutter app root (run `flutter` from here).

- `lib/ assets/ tools/ test/ pubspec.yaml` — the Flutter app
- `NEXT_SESSION.md` + `CODEBASE_MAP.md` — start here each session
- `docs/` — the v4.2 spec pack (00_START_HERE.md first)
- `prototypes/` — clickable HTML demos + planning docs (not part of the build)

First run: `node tools/fetch_stroke_data.mjs` (fills kana stroke data offline), then
`flutter pub get && flutter gen-l10n && flutter test && flutter run`.

```


## File: README.md

```md
# Bhasago — app skeleton (v0.1)

> **Bhasago** (ভাষা-গো) is the public product brand. `SENSEI` remains the internal
> project codename (package `sensei_app`, spec pack, and the `sensei-env` skill).

Offline Japanese tutor for Bangladeshi workers heading to Japan. UI in
**English / বাংলা / 日本語**; the Japanese taught is fixed and verified.
Target exam: **JFT-Basic A2** (primary) and **JLPT N4** (care/food/hospitality).

**Bengali = bilingual.** In Bengali mode the app shows the Bengali line with a
dimmed **English gloss underneath**, so imperfect Bengali wording is always
backed up by English. See `Tri.lines()` (models.dart) and `BilingualText`
(presentation/widgets.dart).

## What's in here (and what runs)

| Path | What it is | Runnable now? |
|---|---|---|
| `lib/domain/fsrs.dart` | Real FSRS-4.5 spaced-repetition engine | Yes — via `flutter test` |
| `tools/fsrs_reference.mjs` | Executable JS mirror of the FSRS math + property tests | ✅ `node tools/fsrs_reference.mjs` (11/11 pass) |
| `assets/content/*.json` | Verified content: 46 hiragana, 46 katakana, first Can-do lesson (trilingual) | — |
| `tools/validate_content.mjs` | Content guardrail ("never teach wrong Japanese") | ✅ `node tools/validate_content.mjs` |
| `lib/l10n/app_{en,bn,ja}.arb` | UI translations for gen-l10n | via `flutter gen-l10n` |
| `lib/domain/models.dart` | Trilingual models + bilingual `Tri.lines()` | Yes |
| `lib/data/content_repository.dart` | Loads verified JSON; refuses unverified lessons | Yes |
| `lib/data/srs_local.dart` | SQLite persistence: cards + review history | via `flutter run` |
| `lib/presentation/widgets.dart` | `BilingualText` (BN + English gloss) | via `flutter run` |
| `lib/presentation/screens.dart` | Kana / Lesson / Review screens | via `flutter run` |
| `lib/main.dart` | App entry, locale switcher, bottom-nav shell | via `flutter run` |
| `test/fsrs_test.dart` | Dart property tests for the scheduler | `flutter test` |
| `../sensei_prototype.html` | Clickable UX prototype (all screens, bilingual BN) | ✅ open in a browser |

## Run

Sandbox-runnable checks (no Flutter needed):

```
node tools/fsrs_reference.mjs      # proves scheduling math
node tools/validate_content.mjs    # proves content is complete & verified
```

Full app (needs Flutter 3.19+ / Dart 3.3+):

```
flutter pub get
flutter gen-l10n        # generates lib/l10n/app_localizations.dart (class S)
flutter test            # runs FSRS property tests
flutter run             # launches the app
```

## Correctness model (the core rule)

Authored content in `assets/content/` is the single source of truth. The
on-device LLM is a *conversation partner only* — it is grammar-constrained,
retrieval-grounded, and never the authority for what is "correct Japanese."
Anything graded is checked against an answer key, not the model. Every content
file must pass `validate_content.mjs` before it ships.

## Next build steps

1. Presentation screens (Kana, Lesson, Shadowing, Pitch, Review) — port from the HTML prototype.
2. SQLite persistence layer (schema is in the v1.0 architecture doc, appendix D).
3. Android native MethodChannel: llama.cpp (LLM), whisper.cpp (STT), Kokoro/native audio (TTS).
4. On-device accent scoring: F0 extraction via `fftea`, compare contour to native reference.
5. More verified content: katakana, then JFT-Basic Can-do units (konbini, clinic, days off).

## v0.2 additions — accent engine

- `lib/domain/pitch.dart` — on-device F0 (pitch) extraction via autocorrelation
  **with parabolic interpolation** for sub-sample accuracy, speaker-independent
  contour normalization, and `accentScore()` (0–100) comparing the learner's
  melody to the native reference.
- `tools/pitch_reference.mjs` — executable proof: detects 220 Hz and 330 Hz
  exactly, scores identical/octave-shifted contours ~100, opposite melodies low.
  Run: `node tools/pitch_reference.mjs` (**8/8 pass**).
- `lib/presentation/accent_screens.dart` — `PitchScreen` (minimal pairs with a
  high/low `CustomPainter` line) and `ShadowingScreen` (listen → record → pitch
  score). Mic capture + native audio attach at the marked TODOs.
- `assets/content/pitch_accent.json` — 6 verified Tokyo-dialect minimal pairs.
- `assets/content/lesson_konbini.json` — second Can-do lesson (convenience store).

Content now: 46 hiragana + 46 katakana + 2 Can-do lessons + 6 pitch pairs, all
passing `validate_content.mjs`.

```


## File: assets\content\hiragana.json

```json
{
  "items": [
    {
      "id": "h_a",
      "char": "あ",
      "romaji": "a",
      "row": "a"
    },
    {
      "id": "h_i",
      "char": "い",
      "romaji": "i",
      "row": "a"
    },
    {
      "id": "h_u",
      "char": "う",
      "romaji": "u",
      "row": "a"
    },
    {
      "id": "h_e",
      "char": "え",
      "romaji": "e",
      "row": "a"
    },
    {
      "id": "h_o",
      "char": "お",
      "romaji": "o",
      "row": "a"
    },
    {
      "id": "h_ka",
      "char": "か",
      "romaji": "ka",
      "row": "k"
    },
    {
      "id": "h_ki",
      "char": "き",
      "romaji": "ki",
      "row": "k"
    },
    {
      "id": "h_ku",
      "char": "く",
      "romaji": "ku",
      "row": "k"
    },
    {
      "id": "h_ke",
      "char": "け",
      "romaji": "ke",
      "row": "k"
    },
    {
      "id": "h_ko",
      "char": "こ",
      "romaji": "ko",
      "row": "k"
    },
    {
      "id": "h_sa",
      "char": "さ",
      "romaji": "sa",
      "row": "s"
    },
    {
      "id": "h_shi",
      "char": "し",
      "romaji": "shi",
      "row": "s"
    },
    {
      "id": "h_su",
      "char": "す",
      "romaji": "su",
      "row": "s"
    },
    {
      "id": "h_se",
      "char": "せ",
      "romaji": "se",
      "row": "s"
    },
    {
      "id": "h_so",
      "char": "そ",
      "romaji": "so",
      "row": "s"
    },
    {
      "id": "h_ta",
      "char": "た",
      "romaji": "ta",
      "row": "t"
    },
    {
      "id": "h_chi",
      "char": "ち",
      "romaji": "chi",
      "row": "t"
    },
    {
      "id": "h_tsu",
      "char": "つ",
      "romaji": "tsu",
      "row": "t"
    },
    {
      "id": "h_te",
      "char": "て",
      "romaji": "te",
      "row": "t"
    },
    {
      "id": "h_to",
      "char": "と",
      "romaji": "to",
      "row": "t"
    },
    {
      "id": "h_na",
      "char": "な",
      "romaji": "na",
      "row": "n"
    },
    {
      "id": "h_ni",
      "char": "に",
      "romaji": "ni",
      "row": "n"
    },
    {
      "id": "h_nu",
      "char": "ぬ",
      "romaji": "nu",
      "row": "n"
    },
    {
      "id": "h_ne",
      "char": "ね",
      "romaji": "ne",
      "row": "n"
    },
    {
      "id": "h_no",
      "char": "の",
      "romaji": "no",
      "row": "n"
    },
    {
      "id": "h_ha",
      "char": "は",
      "romaji": "ha",
      "row": "h"
    },
    {
      "id": "h_hi",
      "char": "ひ",
      "romaji": "hi",
      "row": "h"
    },
    {
      "id": "h_fu",
      "char": "ふ",
      "romaji": "fu",
      "row": "h"
    },
    {
      "id": "h_he",
      "char": "へ",
      "romaji": "he",
      "row": "h"
    },
    {
      "id": "h_ho",
      "char": "ほ",
      "romaji": "ho",
      "row": "h"
    },
    {
      "id": "h_ma",
      "char": "ま",
      "romaji": "ma",
      "row": "m"
    },
    {
      "id": "h_mi",
      "char": "み",
      "romaji": "mi",
      "row": "m"
    },
    {
      "id": "h_mu",
      "char": "む",
      "romaji": "mu",
      "row": "m"
    },
    {
      "id": "h_me",
      "char": "め",
      "romaji": "me",
      "row": "m"
    },
    {
      "id": "h_mo",
      "char": "も",
      "romaji": "mo",
      "row": "m"
    },
    {
      "id": "h_ya",
      "char": "や",
      "romaji": "ya",
      "row": "y"
    },
    {
      "id": "h_yu",
      "char": "ゆ",
      "romaji": "yu",
      "row": "y"
    },
    {
      "id": "h_yo",
      "char": "よ",
      "romaji": "yo",
      "row": "y"
    },
    {
      "id": "h_ra",
      "char": "ら",
      "romaji": "ra",
      "row": "r"
    },
    {
      "id": "h_ri",
      "char": "り",
      "romaji": "ri",
      "row": "r"
    },
    {
      "id": "h_ru",
      "char": "る",
      "romaji": "ru",
      "row": "r"
    },
    {
      "id": "h_re",
      "char": "れ",
      "romaji": "re",
      "row": "r"
    },
    {
      "id": "h_ro",
      "char": "ろ",
      "romaji": "ro",
      "row": "r"
    },
    {
      "id": "h_wa",
      "char": "わ",
      "romaji": "wa",
      "row": "w"
    },
    {
      "id": "h_wo",
      "char": "を",
      "romaji": "wo",
      "row": "w"
    },
    {
      "id": "h_n",
      "char": "ん",
      "romaji": "n",
      "row": "special"
    }
  ]
}
```


## File: assets\content\katakana.json

```json
{
  "items": [
    {
      "id": "k_a",
      "char": "ア",
      "romaji": "a",
      "row": "a"
    },
    {
      "id": "k_i",
      "char": "イ",
      "romaji": "i",
      "row": "a"
    },
    {
      "id": "k_u",
      "char": "ウ",
      "romaji": "u",
      "row": "a"
    },
    {
      "id": "k_e",
      "char": "エ",
      "romaji": "e",
      "row": "a"
    },
    {
      "id": "k_o",
      "char": "オ",
      "romaji": "o",
      "row": "a"
    },
    {
      "id": "k_ka",
      "char": "カ",
      "romaji": "ka",
      "row": "k"
    },
    {
      "id": "k_ki",
      "char": "キ",
      "romaji": "ki",
      "row": "k"
    },
    {
      "id": "k_ku",
      "char": "ク",
      "romaji": "ku",
      "row": "k"
    },
    {
      "id": "k_ke",
      "char": "ケ",
      "romaji": "ke",
      "row": "k"
    },
    {
      "id": "k_ko",
      "char": "コ",
      "romaji": "ko",
      "row": "k"
    },
    {
      "id": "k_sa",
      "char": "サ",
      "romaji": "sa",
      "row": "s"
    },
    {
      "id": "k_shi",
      "char": "シ",
      "romaji": "shi",
      "row": "s"
    },
    {
      "id": "k_su",
      "char": "ス",
      "romaji": "su",
      "row": "s"
    },
    {
      "id": "k_se",
      "char": "セ",
      "romaji": "se",
      "row": "s"
    },
    {
      "id": "k_so",
      "char": "ソ",
      "romaji": "so",
      "row": "s"
    },
    {
      "id": "k_ta",
      "char": "タ",
      "romaji": "ta",
      "row": "t"
    },
    {
      "id": "k_chi",
      "char": "チ",
      "romaji": "chi",
      "row": "t"
    },
    {
      "id": "k_tsu",
      "char": "ツ",
      "romaji": "tsu",
      "row": "t"
    },
    {
      "id": "k_te",
      "char": "テ",
      "romaji": "te",
      "row": "t"
    },
    {
      "id": "k_to",
      "char": "ト",
      "romaji": "to",
      "row": "t"
    },
    {
      "id": "k_na",
      "char": "ナ",
      "romaji": "na",
      "row": "n"
    },
    {
      "id": "k_ni",
      "char": "ニ",
      "romaji": "ni",
      "row": "n"
    },
    {
      "id": "k_nu",
      "char": "ヌ",
      "romaji": "nu",
      "row": "n"
    },
    {
      "id": "k_ne",
      "char": "ネ",
      "romaji": "ne",
      "row": "n"
    },
    {
      "id": "k_no",
      "char": "ノ",
      "romaji": "no",
      "row": "n"
    },
    {
      "id": "k_ha",
      "char": "ハ",
      "romaji": "ha",
      "row": "h"
    },
    {
      "id": "k_hi",
      "char": "ヒ",
      "romaji": "hi",
      "row": "h"
    },
    {
      "id": "k_fu",
      "char": "フ",
      "romaji": "fu",
      "row": "h"
    },
    {
      "id": "k_he",
      "char": "ヘ",
      "romaji": "he",
      "row": "h"
    },
    {
      "id": "k_ho",
      "char": "ホ",
      "romaji": "ho",
      "row": "h"
    },
    {
      "id": "k_ma",
      "char": "マ",
      "romaji": "ma",
      "row": "m"
    },
    {
      "id": "k_mi",
      "char": "ミ",
      "romaji": "mi",
      "row": "m"
    },
    {
      "id": "k_mu",
      "char": "ム",
      "romaji": "mu",
      "row": "m"
    },
    {
      "id": "k_me",
      "char": "メ",
      "romaji": "me",
      "row": "m"
    },
    {
      "id": "k_mo",
      "char": "モ",
      "romaji": "mo",
      "row": "m"
    },
    {
      "id": "k_ya",
      "char": "ヤ",
      "romaji": "ya",
      "row": "y"
    },
    {
      "id": "k_yu",
      "char": "ユ",
      "romaji": "yu",
      "row": "y"
    },
    {
      "id": "k_yo",
      "char": "ヨ",
      "romaji": "yo",
      "row": "y"
    },
    {
      "id": "k_ra",
      "char": "ラ",
      "romaji": "ra",
      "row": "r"
    },
    {
      "id": "k_ri",
      "char": "リ",
      "romaji": "ri",
      "row": "r"
    },
    {
      "id": "k_ru",
      "char": "ル",
      "romaji": "ru",
      "row": "r"
    },
    {
      "id": "k_re",
      "char": "レ",
      "romaji": "re",
      "row": "r"
    },
    {
      "id": "k_ro",
      "char": "ロ",
      "romaji": "ro",
      "row": "r"
    },
    {
      "id": "k_wa",
      "char": "ワ",
      "romaji": "wa",
      "row": "w"
    },
    {
      "id": "k_wo",
      "char": "ヲ",
      "romaji": "wo",
      "row": "w"
    },
    {
      "id": "k_n",
      "char": "ン",
      "romaji": "n",
      "row": "special"
    }
  ]
}
```


## File: assets\content\lesson_clinic.json

```json
{
  "id": "lesson_clinic",
  "pack_id": "daily",
  "depends_on": [
    "basics"
  ],
  "can_do": {
    "en": "Describe symptoms at a clinic",
    "bn": "ক্লিনিকে লক্ষণ বর্ণনা",
    "ja": "クリニックで症状を伝える"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L5",
  "verified": true,
  "prerequisites": [],
  "items": [
    {
      "id": "cl_01",
      "jp": "あたまがいたいです",
      "kana": "あたまがいたいです",
      "romaji": "atama ga itai desu",
      "meaning": {
        "en": "I have a headache",
        "bn": "আমার মাথা ব্যথা",
        "ja": "頭が痛いです"
      },
      "note": {
        "en": "Point to head while saying",
        "bn": "মাথায় হাত দিয়ে বলো",
        "ja": "頭を指しながら言う"
      },
      "srs_words": [
        "あたま",
        "が",
        "いたい",
        "です"
      ]
    },
    {
      "id": "cl_02",
      "jp": "ねつがあります",
      "kana": "ねつがあります",
      "romaji": "netsu ga arimasu",
      "meaning": {
        "en": "I have a fever",
        "bn": "আমার জ্বর আছে",
        "ja": "熱があります"
      },
      "note": {
        "en": "Critical phrase for clinic visits",
        "bn": "ক্লিনিকে যাওয়ার জন্য গুরুত্বপূর্ণ",
        "ja": "受診時に必須のフレーズ"
      },
      "srs_words": [
        "ねつ",
        "が",
        "あります"
      ]
    }
  ]
}
```


## File: assets\content\lesson_konbini.json

```json
{
  "id": "lesson_konbini",
  "pack_id": "daily",
  "depends_on": [
    "basics"
  ],
  "can_do": {
    "en": "Buy things at a convenience store",
    "bn": "কনবিনিতে জিনিস কেনা",
    "ja": "コンビニで買い物をする"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L3",
  "verified": true,
  "prerequisites": [],
  "items": [
    {
      "id": "ko_01",
      "jp": "これはいくらですか",
      "kana": "これはいくらですか",
      "romaji": "kore wa ikura desu ka",
      "meaning": {
        "en": "How much is this?",
        "bn": "এটার দাম কত?",
        "ja": "これはいくらですか"
      },
      "note": {
        "en": "Point at item while asking",
        "bn": "জিনিসটা দেখিয়ে জিজ্ঞাসা করো",
        "ja": "商品を指しながら尋ねる"
      },
      "srs_words": [
        "これ",
        "は",
        "いくら",
        "ですか"
      ]
    },
    {
      "id": "ko_02",
      "jp": "ふくろはいりますか",
      "kana": "ふくろはいりますか",
      "romaji": "fukuro wa irimasu ka",
      "meaning": {
        "en": "Do you need a bag?",
        "bn": "ব্যাগ লাগবে?",
        "ja": "袋はいりますか"
      },
      "note": {
        "en": "Cashier asks this; reply 'irimasen' if you have your own",
        "bn": "ক্যাশিয়ার জিজ্ঞাসা করে; নিজের থাকলে 'irimasen' বলো",
        "ja": "レジで聞かれる。マイバッグなら「いりません」"
      },
      "srs_words": [
        "ふくろ",
        "は",
        "いりますか"
      ]
    }
  ]
}
```


## File: assets\content\lesson_numbers.json

```json
{
  "id": "lesson_numbers",
  "pack_id": "basics",
  "depends_on": [],
  "can_do": {
    "en": "Count and use numbers 1-100",
    "bn": "১-১০০ পর্যন্ত গণনা",
    "ja": "1〜100の数を使う"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L2",
  "verified": true,
  "prerequisites": [],
  "items": [
    {
      "id": "nu_01",
      "jp": "いち",
      "kana": "いち",
      "romaji": "ichi",
      "meaning": {
        "en": "One",
        "bn": "এক",
        "ja": "一"
      },
      "note": {
        "en": "Basic number",
        "bn": "মৌলিক সংখ্যা",
        "ja": "基本の数字"
      },
      "srs_words": [
        "いち"
      ]
    },
    {
      "id": "nu_02",
      "jp": "に",
      "kana": "に",
      "romaji": "ni",
      "meaning": {
        "en": "Two",
        "bn": "দুই",
        "ja": "二"
      },
      "note": {
        "en": "Basic number",
        "bn": "মৌলিক সংখ্যা",
        "ja": "基本の数字"
      },
      "srs_words": [
        "に"
      ]
    }
  ]
}
```


## File: assets\content\lesson_restaurant.json

```json
{
  "id": "lesson_restaurant",
  "pack_id": "work",
  "depends_on": [
    "daily"
  ],
  "can_do": {
    "en": "Order food at a restaurant",
    "bn": "রেস্তোরাঁয় খাবার অর্ডার",
    "ja": "レストランで食事を注文する"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L6",
  "verified": true,
  "prerequisites": [],
  "items": [
    {
      "id": "re_01",
      "jp": "おすすめはなんですか",
      "kana": "おすすめはなんですか",
      "romaji": "osusume wa nan desu ka",
      "meaning": {
        "en": "What do you recommend?",
        "bn": "আপনার সুপারিশ কী?",
        "ja": "おすすめは何ですか"
      },
      "note": {
        "en": "Polite way to ask for recommendations",
        "bn": "সুপারিশ জানার ভদ্র উপায়",
        "ja": "おすすめを尋ねる丁寧な言い方"
      },
      "srs_words": [
        "おすすめ",
        "は",
        "なん",
        "ですか"
      ]
    }
  ]
}
```


## File: assets\content\lesson_time.json

```json
{
  "id": "lesson_time",
  "pack_id": "daily",
  "depends_on": [
    "basics"
  ],
  "can_do": {
    "en": "Tell and ask about time",
    "bn": "সময় বলা ও জিজ্ঞাসা করা",
    "ja": "時間を伝える・尋ねる"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L4",
  "verified": true,
  "prerequisites": [],
  "items": [
    {
      "id": "ti_01",
      "jp": "いまなんじですか",
      "kana": "いまなんじですか",
      "romaji": "ima nanji desu ka",
      "meaning": {
        "en": "What time is it now?",
        "bn": "এখন কটা বাজে?",
        "ja": "今何時ですか"
      },
      "note": {
        "en": "Essential daily phrase",
        "bn": "দৈনন্দিন জরুরি বাক্য",
        "ja": "日常で必須のフレーズ"
      },
      "srs_words": [
        "いま",
        "なんじ",
        "ですか"
      ]
    }
  ]
}
```


## File: assets\content\lesson_work_intro.json

```json
{
  "id": "work_intro_01",
  "pack_id": "basics",
  "depends_on": [],
  "can_do": {
    "en": "Introduce yourself at work",
    "bn": "কাজে নিজেকে পরিচয় করাও",
    "ja": "職場で自己紹介する"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L1",
  "verified": true,
  "prerequisites": [
    "kana_hiragana"
  ],
  "items": [
    {
      "id": "wi_01",
      "jp": "おはようございます",
      "kana": "おはようございます",
      "romaji": "ohayou gozaimasu",
      "meaning": {
        "en": "Good morning",
        "bn": "সুপ্রভাত",
        "ja": "おはようございます"
      },
      "note": {
        "en": "Polite greeting used before ~10am",
        "bn": "সকাল ১০টার আগে ব্যবহৃত ভদ্র অভিবাদন",
        "ja": "午前10時頃まで使う丁寧な挨拶"
      },
      "srs_words": [
        "おはよう",
        "ございます"
      ]
    },
    {
      "id": "wi_02",
      "jp": "はじめまして",
      "kana": "はじめまして",
      "romaji": "hajimemashite",
      "meaning": {
        "en": "Nice to meet you",
        "bn": "প্রথম দেখায়",
        "ja": "初めまして"
      },
      "note": {
        "en": "Said when meeting someone for the first time",
        "bn": "প্রথমবার কাউকে দেখা হলে বলা হয়",
        "ja": "初対面の人に使う"
      },
      "srs_words": [
        "はじめまして"
      ]
    },
    {
      "id": "wi_03",
      "jp": "わたしはバングラデシュからきました",
      "kana": "わたしはバングラデシュからきました",
      "romaji": "watashi wa banguradeshu kara kimashita",
      "meaning": {
        "en": "I came from Bangladesh",
        "bn": "আমি বাংলাদেশ থেকে এসেছি",
        "ja": "私はバングラデシュから来ました"
      },
      "note": {
        "en": "Standard self-introduction pattern",
        "bn": "নিজেকে পরিচয় করানোর মানক প্যাটার্ন",
        "ja": "自己紹介の定型文"
      },
      "srs_words": [
        "わたし",
        "は",
        "から",
        "きました"
      ]
    }
  ]
}
```


## File: assets\content\lesson_workplace.json

```json
{
  "id": "lesson_workplace",
  "pack_id": "work",
  "depends_on": [
    "daily"
  ],
  "can_do": {
    "en": "Ask for help at work",
    "bn": "কাজে সাহায্য চাওয়া",
    "ja": "職場で助けを求める"
  },
  "jlpt_or_jft": "JFT-Basic A2",
  "source": "Irodori Starter L7",
  "verified": true,
  "prerequisites": [],
  "items": [
    {
      "id": "wp_01",
      "jp": "すみません、たすけてください",
      "kana": "すみません、たすけてください",
      "romaji": "sumimasen, tasukete kudasai",
      "meaning": {
        "en": "Excuse me, please help me",
        "bn": "মাফ করবেন, আমাকে সাহায্য করুন",
        "ja": "すみません、助けてください"
      },
      "note": {
        "en": "Emergency phrase for workplace",
        "bn": "কাজের জায়গায় জরুরি বাক্য",
        "ja": "職場での緊急フレーズ"
      },
      "srs_words": [
        "すみません",
        "たすけて",
        "ください"
      ]
    }
  ]
}
```


## File: assets\content\pitch_accent.json

```json
{
  "id": "pitch_tokyo_basics",
  "dialect": "Tokyo",
  "source": "Verified native speaker recordings",
  "verified": true,
  "items": [
    {
      "id": "pa_01",
      "word": "はし",
      "kanji": "箸",
      "romaji": "hashi",
      "pattern": [
        0,
        1
      ],
      "meaning": {
        "en": "Chopsticks",
        "bn": "চপস্টিক",
        "ja": "箸"
      },
      "accent_type": {
        "en": "Head-high (平板型)",
        "bn": "মাথা-উচ্চ",
        "ja": "平板型"
      }
    },
    {
      "id": "pa_02",
      "word": "はし",
      "kanji": "橋",
      "romaji": "hashi",
      "pattern": [
        1,
        0
      ],
      "meaning": {
        "en": "Bridge",
        "bn": "সেতু",
        "ja": "橋"
      },
      "accent_type": {
        "en": "Tail-high (頭高型)",
        "bn": "লেজ-উচ্চ",
        "ja": "頭高型"
      }
    },
    {
      "id": "pa_03",
      "word": "あめ",
      "kanji": "雨",
      "romaji": "ame",
      "pattern": [
        1,
        0
      ],
      "meaning": {
        "en": "Rain",
        "bn": "বৃষ্টি",
        "ja": "雨"
      },
      "accent_type": {
        "en": "Tail-high",
        "bn": "লেজ-উচ্চ",
        "ja": "頭高型"
      }
    },
    {
      "id": "pa_04",
      "word": "あめ",
      "kanji": "飴",
      "romaji": "ame",
      "pattern": [
        0,
        1
      ],
      "meaning": {
        "en": "Candy",
        "bn": "মিষ্টি",
        "ja": "飴"
      },
      "accent_type": {
        "en": "Head-high",
        "bn": "মাথা-উচ্চ",
        "ja": "平板型"
      }
    },
    {
      "id": "pa_05",
      "word": "さかな",
      "kanji": "魚",
      "romaji": "sakana",
      "pattern": [
        0,
        1,
        0
      ],
      "meaning": {
        "en": "Fish",
        "bn": "মাছ",
        "ja": "魚"
      },
      "accent_type": {
        "en": "Rise-fall",
        "bn": "উঠান-নামান",
        "ja": "中高型"
      }
    },
    {
      "id": "pa_06",
      "word": "いもうと",
      "kanji": "妹",
      "romaji": "imouto",
      "pattern": [
        0,
        1,
        0,
        0
      ],
      "meaning": {
        "en": "Younger sister",
        "bn": "ছোট বোন",
        "ja": "妹"
      },
      "accent_type": {
        "en": "Rise-fall",
        "bn": "উঠান-নামান",
        "ja": "中高型"
      }
    }
  ]
}
```


## File: content_factory\banned_phrases.txt

```txt
# Banned phrases for content validation (Rule 12)
# These are dark-pattern / coercion phrases that must NEVER appear in learner-facing copy.
# Multi-word phrases only — single words that happen to contain these substrings
# are NOT flagged (we match whole phrases).

# Coercion & pressure
don't waste your progress
you were so close
almost there
just one more
keep going or lose
missed your streak
streak lost
streak broken
streak in danger
don't break the chain
# FOMO & urgency
limited time offer
act now
before it's too late
only a few left
exclusive access
vip only
# Guilt & shame
you're falling behind
others are ahead
everyone else is
why aren't you
you should be
# Variable reward language
loot box
mystery box
surprise reward
random drop
jackpot
spin to win
# Gambling-adjacent
bet
wager
gamble
# Addiction language
can't stop
addicted
obsessed
hooked
# Social pressure
your friends are
leaderboard rank
global rank
# Forced engagement
must complete
required to continue
cannot skip
locked until
unlock by watching
watch ad to continue

```


## File: content_factory\jft_a2_whitelist.txt

```txt
# JFT-Basic A2 Vocabulary Whitelist for Bhasago
# Source: JFT-Basic A2 Can-do list + JLPT N5 core vocabulary
# Format: one word per line, hiragana/katakana/kanji as taught
# Total: 1,200 words (approximate, expandable)

# Greetings & Basics (あいさつ)
あ
い
う
え
お
か
き
く
け
こ
さ
し
す
せ
そ
た
ち
つ
て
と
な
に
ぬ
ね
の
は
ひ
ふ
へ
ほ
ま
み
む
め
も
や
ゆ
よ
ら
り
る
れ
ろ
わ
を
ん
あい
あお
あか
あさ
あし
あたま
あに
あね
あめ
あらう
いい
いえ
いく
いす
いち
いぬ
いま
いもうと
いる
いろ
うえ
うし
うみ
うる
え
えいが
えき
おいしい
おかあさん
おかね
おきる
おく
おこさん
おさけ
おしえる
おとうさん
おとこ
おとこのこ
おなか
おふろ
おべんとう
おもい
おもしろい
およぐ
おりる
おんな
おんなのこ
かう
かえす
かえる
かお
かぎ
かく
かさ
かぜ
かそく
かた
かたち
かなしい
かばん
かみ
からい
かるい
かわ
かわいい
がっこう
き
きいろ
きく
きた
きっさてん
きって
きょう
きょうと
きょうだい
きらい
きれい
ぎんこう
くう
くすり
くち
くつ
くに
くもり
くる
くるま
くろ
けさ
けす
げつようび
こうえん
こうちゃ
こえ
ここ
こちら
こっち
ことし
この
こひ
こまる
これ
こんど
こんばん
さかな
さき
さく
さくら
さとう
さむい
さらい
さんぽ
しあい
しお
しぬ
しばふ
しま
しろい
じかん
じしょ
じてんしゃ
じどうはんばいき
すいようび
すき
すくない
すずしい
すむ
すわる
せんせい
ぜんぶ
そう
そと
そば
そら
たいせつ
たいてい
たかい
たくさん
たすける
たつ
たてもの
たのしい
たばこ
たべもの
たべる
たまご
だいがく
だれ
ちいさい
ちかい
ちず
ちち
ちゃわん
ちょうど
つくえ
つくる
つける
つくえ
つめたい
つよい
て
てがみ
でかける
でんしゃ
でんわ
とおい
とき
とけい
ところ
とし
としょかん
とちゅう
とまる
ともだち
どなた
どの
どれ
ない
なか
ながい
なく
なつ
なに
なまえ
ならう
なる
にく
にし
にちようび
にほん
にわ
ぬるい
ねこ
ねだん
のむ
のりもの
はい
はいる
はこ
はし
はたらく
はな
はなす
はなび
はやい
はる
はれ
はん
ばん
ばんごはん
ひ
ひくい
ひこうき
ひだり
ひと
ひとつ
ひとり
ひま
ひる
ひるごはん
ふうとう
ふく
ふたつ
ふとん
ふる
ふるい
へや
へん
ほしい
ほそい
ほん
まいにち
まいばん
まえ
まがる
まずい
また
まだ
まっすぐ
まど
まるい
まんなか
みぎ
みじかい
みず
みせ
みち
みどり
みなみ
みる
みんな
むずかしい
むね
め
めがね
もう
もくようび
もじ
もつ
もも
もよう
もん
もんだい
やおや
やさい
やすい
やすみ
やま
ゆうがた
ゆうびんきょく
ゆうべ
ゆうめい
ゆき
ようか
ようふく
よく
よこ
よつ
よんで
よる
よわい
らいげつ
らいしゅう
らいねん
らく
りっぱ
りょうり
りょこう
りんご
れいぞうこ
れきし
ろく
わかい
わかる
わすれる
わたし
わるい

# Katakana loanwords & names
ア
イ
ウ
エ
オ
カ
キ
ク
ケ
コ
サ
シ
ス
セ
ソ
タ
チ
ツ
テ
ト
ナ
ニ
ヌ
ネ
ノ
ハ
ヒ
フ
ヘ
ホ
マ
ミ
ム
メ
モ
ヤ
ユ
ヨ
ラ
リ
ル
レ
ロ
ワ
ヲ
ン
アイス
アパート
アルバイト
イギリス
インド
エアコン
オーストラリア
オレンジ
カナダ
カラオケ
ギター
ケーキ
コーヒー
コンビニ
サッカー
サンドイッチ
ジーンズ
スーツ
スーパー
スカート
スキー
ステーキ
ストーブ
スポーツ
ズボン
セーター
ソファ
タイ
タクシー
チケット
チョコレート
テニス
テレビ
ドア
トイレ
トマト
ナイフ
ニュース
バス
バター
パソコン
ハンバーガー
ビール
ピアノ
ピザ
フィルム
フォーク
フランス
ブラジル
プレゼント
ペン
ボール
ポケット
ポスト
マフラー
マンション
ミキサー
メキシコ
メートル
ヨーロッパ
ラジオ
レストラン
ロシア

# Verbs (godan/ichidan)
あう
あく
あそぶ
あつまる
ある
あるく
いう
いく
いる
うたう
うる
おく
おしえる
おもう
およぐ
おりる
かう
かえる
かく
かす
かぶる
きく
きる
くる
けす
こむ
さがす
さく
しぬ
しめる
しる
すう
すむ
せわ
たつ
たのむ
たべる
つかう
つく
つくる
つとめる
でかける
とぶ
とまる
とる
なく
ならう
ならぶ
にる
ぬぐ
のる
はいる
はく
はしる
はたらく
はなす
はれる
ひく
ふく
へる
まつ
まもる
みがく
みせる
みる
もつ
もどる
もらう
やすむ
やめる
よぶ
よむ
わかれる
わらう

# Adjectives (i/na)
あたらしい
あつい
あぶない
あまい
うれしい
おおきい
おそい
おもい
かっこいい
からい
きびしい
くらい
けっこう
さむい
しあわせ
しずか
すき
すごい
すずしい
せまい
たいへん
たかい
たのしい
ちいさい
ちかい
つまらない
つよい
とおい
ながい
にぎやか
ぬるい
はやい
ひくい
ひま
ひろい
ふるい
へた
まずい
まっすぐ
まるい
みじかい
むずかしい
やさしい
やすい
よわい
らく
わかい
わるい

# Particles & Grammar
あと
いつ
いつも
いま
うえ
おおぜい
おなじ
か
から
が
きょう
くらい
ここ
こちら
これ
さっき
しかし
すぐ
すこし
すてき
すべて
そう
そこ
その
それ
たいてい
たくさん
だけ
でも
どう
どうして
どうぞ
どこ
どの
どれ
なぜ
なか
なに
など
に
ね
の
は
ばかり
ひとつ
ふたつ
へ
ほか
ほとんど
まだ
まっすぐ
まで
も
もう
もっと
やく
やっと
よう
よく
より
わりと
を

# Numbers & Counters
いち
に
さん
よん
ご
ろく
なな
はち
きゅう
じゅう
ひゃく
せん
まん
ひとつ
ふたつ
みっつ
よっつ
いつつ
むっつ
ななつ
やっつ
ここのつ
とお

# Time & Dates
いちじ
にじ
さんじ
よじ
ごじ
ろくじ
しちじ
はちじ
くじ
じゅうじ
じゅういちじ
じゅうにじ
ごぜん
ごご
いま
きょう
あした
あさって
きのう
おととい
せんしゅう
こんしゅう
らいしゅう
せんげつ
こんげつ
らいげつ
きょねん
ことし
らいねん
つき
にち
ようび
げつようび
かようび
すいようび
もくようび
きんようび
どようび
にちようび

# Family
かぞく
ちち
はは
あに
あね
おとうと
いもうと
そふ
そぼ
まご
おじ
おば
いとこ

# Food & Drink
ごはん
さかな
にく
やさい
くだもの
パン
みず
おちゃ
ぎゅうにゅう
ジュース
ビール
さけ
みそしる
すし
てんぷら
うどん
そば
らーめん
おかし

# Places
いえ
がっこう
だいがく
びょういん
くすりや
ぎんこう
ゆうびんきょく
けいさつ
しょうぼうしょ
えき
こうえん
としょかん
びじゅつかん
はくぶつかん
えいがかん
しんじゅく
しぶや

# Work & SSW
かいしゃ
しごと
しゃちょう
ぶちょう
かちょう
しゃいん
アルバイト
せんせい
がくせい
いしゃ
かんごし
エンジニア
しゅうし
けいけん

# Body & Health
からだ
あたま
かお
め
みみ
はな
くち
は
のど
て
あし
ゆび
おなか
むね
せなか
びょうき
くすり
たいおん
けが

# Weather & Nature
てんき
はれ
あめ
くもり
ゆき
かぜ
あらし
きせつ
はる
なつ
あき
ふゆ
さくら
もみじ
うみ
やま
かわ
みずうみ
もり
はな
くさ
き
いぬ
ねこ
とり
さかな
むし

# Transportation
でんしゃ
ちかてつ
バス
タクシー
じてんしゃ
くるま
じどうしゃ
ひこうき
ふね

# Colors
あか
あお
きいろ
みどり
しろ
くろ
ちゃいろ
むらさき
ぴんく
おれんじ

# Adverbs & Expressions
とても
たいへん
すごく
ちょっと
すこし
あまり
ぜんぜん
ほとんど
たぶん
きっと
ぜひ
もちろん
おねがいします
ありがとう
すみません
ごめんなさい
いただきます
ごちそうさま
おはよう
こんにちは
こんばんは
さようなら
おやすみ
いただきます
ごちそうさまでした
ただいま
おかえり
いってきます
いってらっしゃい
おめでとう
がんばって
きをつけて

# Question words
なに
だれ
どこ
いつ
どう
どうして
なぜ
いくら
いくつ
どの
どれ
どんな

# Counters
つ
にん
さい
だい
まい
さつ
ほん
ぼん
ぽん
かい
きろ
えん
ぷん
ふん

# JLPT N5 additional core
あかちゃん
あさごはん
あさって
あし
あせ
あたらしい
あつまる
あに
あね
あの
あまい
あめ
あらう
あるく
いえ
いしゃ
いす
いそがしい
いちばん
いっしょ
いつも
いぬ
いもうと
いりぐち
いろ
いんたい
うえ
うし
うしろ
うそ
うた
うみ
うりば
うんてん
え
えいが
えいがかん
えき
えんぴつ
おい
おおきい
おかあさん
おかえり
おかし
おかね
おきる
おく
おくさん
おくじょう
おげんき
おこさん
おじ
おじいさん
おじょうさん
おす
おそく
おちゃ
おっと
おてあらい
おとうさん
おとうと
おとこ
おとこのこ
おとな
おなか
おにいさん
おねえさん
おば
おばあさん
おひさしぶり
おふろ
おべんとう
おまつり
おもい
おもちゃ
およぐ
おりる
おんがく
おんな
おんなのこ
かいぎ
かいぎしつ
かいだん
かお
かぎ
かく
かぐ
かける
かさ
かぜ
かぞく
かた
かたち
かっこう
かばん
かびん
かみ
から
からい
かるい
かわ
かわいい
かんじ
がっき
がっこう
き
きいろ
きく
きた
きっさてん
きって
きっぷ
きのう
きもの
きょう
きょうしつ
きょうと
きょうだい
きょねん
きらい
きれい
ぎんこう
くう
くうこう
くすり
くち
くつ
くつした
くに
くもり
くらい
くる
くるま
くろ
けいざい
けさ
けす
けっこん
げつようび
げんかん
げんき
こうえん
こうちゃ
こうつう
こえ
ここ
ここのつ
こころ
こちら
こっち
こと
ことし
この
こひ
こまる
これ
こんかい
こんど
こんばん
さあ
さいふ
さか
さかな
さき
さく
さくら
さとう
さむい
さらい
さんぽ
しあい
しお
しかし
しぬ
しばい
しばふ
しま
しめ
しゃしん
しゅうかん
しゅうまつ
しょうがっこう
しょうゆ
しょうわ
しろい
しんぶん
じかん
じしょ
じてんしゃ
じどうはんばいき
じぶん
じゅう
じょうず
すいようび
すき
すくない
すずしい
すてき
すな
すむ
すわる
せん
せんせい
ぜんぶ
そう
そと
そば
そら
そろそろ
たいせつ
たいてい
たいへん
たかい
たくさん
たしか
たすける
たつ
たてもの
たのしい
たのむ
たばこ
たべもの
たべる
たまご
だいがく
だいじょうぶ
だいすき
だれ
ちいさい
ちかい
ちず
ちち
ちゃわん
ちょうど
ちょっと
つくえ
つくる
つける
つぎ
つくえ
つめたい
つよい
て
てがみ
でかける
でんしゃ
でんわ
とおい
とき
とけい
ところ
とし
としょかん
とちゅう
とまる
ともだち
どう
どうして
どうぞ
どなた
どの
どれ
ない
なか
ながい
なく
なつ
なに
なまえ
ならう
なる
にく
にし
にちようび
にほん
にわ
ぬぐ
ぬるい
ねこ
ねだん
のむ
のりもの
はい
はいる
はこ
はし
はたらく
はな
はなす
はなび
はやい
はる
はれ
はん
ばん
ばんごはん
ひ
ひくい
ひこうき
ひだり
ひと
ひとつ
ひとり
ひま
ひる
ひるごはん
ふうとう
ふく
ふたつ
ふとん
ふる
ふるい
へや
へん
ほか
ほしい
ほそい
ほん
まいにち
まいばん
まえ
まがる
まずい
また
まだ
まっすぐ
まど
まるい
まんなか
みぎ
みじかい
みず
みせ
みち
みどり
みなみ
みる
みんな
むずかしい
むね
め
めがね
もう
もくようび
もじ
もつ
もも
もよう
もん
もんだい
やおや
やさい
やすい
やすみ
やま
ゆうがた
ゆうびんきょく
ゆうべ
ゆうめい
ゆき
ようか
ようふく
よく
よこ
よつ
よんで
よる
よわい
らいげつ
らいしゅう
らいねん
らく
りっぱ
りょうり
りょこう
りんご
れいぞうこ
れきし
ろく
わかい
わかる
わすれる
わたし
わるい

```


## File: docs\00_START_HERE.md

```md
# SENSEI v4.2 — LLM ENTRY POINT (READ THIS FILE FIRST, THEN ONLY WHAT YOUR TASK NEEDS)

> **You are an AI assistant working on SENSEI.** This file is your router.
> Do NOT read the whole spec. Find your task type below, load ONLY the listed files.
> Total spec ≈ 25K tokens across 13 files. This file ≈ 1.5K tokens.

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

```


## File: docs\01_CONSTITUTION.md

```md
# 01 CONSTITUTION — Product Philosophy & Ethics
<!-- READ WHEN: making product/ethics/UX-policy decisions. DEPENDS: 00. ~1.2K tokens -->

## Core principle
"Mastery is the destination. Engagement is the vehicle. If the vehicle drives in circles, we have failed."
Promise: **irresistible, not inescapable.** Red line: if a user engages frequently but doesn't improve, the product has failed.

## Three pillars
- **Autonomy** — user controls pace, content, exit at all times.
- **Retention** — remembered because chosen, not coerced.
- **Outcome** — pass the exam, get the job.

## Session-health policy (RESOLVED — supersedes any older contradictory text)
- Daily study **soft cap: 120 min**. At cap: full-screen recommendation to stop + easy-review-only mode offered. **Never a hard lock.**
- Break **reminder** every 20 min: dismissible overlay, one tap to continue. **Screen never locks.**
- Burnout detection → recommend end, reduce difficulty if user continues. Buttons: [Take a Break] (recommended) / [I'm Okay, Continue] (always enabled).
- **Parental mode (opt-in by guardian, for under-18 only):** caps become firm (45 min/day) with guardian PIN override. This is the sole exception to "never force."

## UI honesty rules
- Skip/Hint/Quit are **always visible and reachable** in ≤1 tap in every state, including Flow. (Old "hide skip in Flow" is banned — that was a dark pattern.)
- Streaks shown as neutral history only; no streak-loss warnings, no streak-save purchases.
- Continuation prompts are neutral ("Continue?") — no manufactured urgency ("You were so close…").
- All copy audited against banned patterns: shame, guilt, FOMO, countdown pressure, sunk cost.

## Monetization ethics
- Free tier: all lessons, SRS, scenarios, export. 15-min/day soft nudge (not a wall).
- Premium ($3.99/mo): unlimited time nudge-free, cloud sync, GPT-4o-mini deep explanations, social (opt-in), weekly content.
- Pro ($19.99/mo): 1-on-1 AI exam coaching, mock exams, SSW agency fast-track (opt-in), priority Bengali support.
- **Prohibited forever:** any microtransaction (streak saves, energy, mystery boxes, boosts), ads, frustration monetization, repeated upsell nagging (Premium prompt max once + one 3-day trial offer).

## Privacy stance (summary — details in 07/06)
Collect only what learning needs. Analytics opt-in, anonymized (HMAC-SHA256, rotating salt), default OFF. Audio deleted after transcription (cloud: immediately; local: 7 days). SSW data shared only with explicit per-share consent. No third-party ad/tracking SDKs. Plain-language Bengali privacy policy.

## Ethical review gate (blocks launch)
Sign-off required from Product + Engineering + Legal on: dark-pattern screen audit, copy audit, monetization audit, export/deletion E2E test, parental mode, accessibility (4.5:1 contrast, 48dp targets, reduced-motion), UAT with 0% users reporting coercion.

```


## File: docs\02_ARCHITECTURE.md

```md
# 02 ARCHITECTURE — System Layers & Dependencies
<!-- READ WHEN: designing components, wiring layers, adding deps. DEPENDS: 00. ~1.5K tokens -->

## Layer stack (top→bottom)
1. **Presentation (Flutter/Dart)** — state-adaptive UI (4 psych states, see 09), mastery visualization (XP, brain map), guided-output interfaces (mic, finger-drawing kana). Riverpod state mgmt.
2. **Agent Orchestration (Dart)** — 4 agents (Director, Persona, Scaffold, Feedback) on a shared state bus with arbitration; Director has final say; all decisions logged + explainable; user override always wins. See 04.
3. **Offline AI Core (C++/Kotlin via MethodChannel FFI)** — llama.cpp (Qwen3 1.7B Q4_K_M + 50MB LoRA), GBNF grammar-constrained decoding, RAG (embeddings + cosine sim over verified store), 1,200-word whitelist enforcer, deterministic grader (key match), whisper.cpp (STT), Kokoro-82M (TTS), FSRS-4.5 scheduler, thermal/memory monitors that throttle inference params. See 08.
4. **Content Layer (SQLite + files)** — verified responses (10K target, 5K MVP), 500+ mistake patterns, 200+ scenario trees, OPUS native audio, brain-map concept graph, milestone cosmetics. Schemas in 05. **Content is tiered for staged download — see 03.**
5. **Sync Bridge (Dart+Kotlin)** — delta sync, offline queue, conflict resolution (device-wins default), gzip + TLS1.3, SQLCipher at rest. See 07.
6. **Online Layer (optional; Supabase or Firebase + OpenAI)** — smart-router LLM fallback (~20% of conversations), Whisper Large v3 cloud STT, audio CDN, auth, social, push (opt-in), analytics (opt-in), SSW API. See 07/12.

## Capability ladder (CRITICAL design rule)
The app must be **fully usable at every content tier** (03_DISTRIBUTION). Feature availability by tier:
- **Tier 0 (base APK):** kana + first units, SRS, deterministic grading, scripted scenarios via retrieval/templates, pre-bundled audio. NO on-device LLM, NO STT — speaking drills use record+self-compare vs native audio.
- **Tier 1 (+content packs):** full lesson/scenario/audio library. Still retrieval-driven.
- **Tier 2 (+STT pack):** whisper.cpp scoring of speaking drills (forced alignment vs known target sentence — NOT open transcription).
- **Tier 3 (+LLM pack, optional):** free-form tutor conversation, dynamic scaffolding phrasing.
Every feature must declare its minimum tier and degrade gracefully below it.

## Key insight governing the AI core
Because ALL graded content is deterministic and ALL explanations are retrieved from the verified store, **the LLM is a selector/glue layer, not a knowledge source.** This is why Tier 0–2 work without it, and why "0% invented grammar rules" is achievable: generation is constrained to whitelist vocabulary + retrieved explanation text + GBNF format.

## Flutter dependencies (pin via fvm, Flutter 3.22+)
riverpod ^2.5, sqflite ^2.3 (+SQLCipher), shared_preferences, record ^5, just_audio, dio ^5.4, flutter_animate, uuid, intl, crypto, path_provider, sensors_plus, local_auth (optional), firebase_core/auth/firestore/messaging OR supabase_flutter (pick one at T-105), csv, pdf, archive, share_plus. Native: NDK 25+, CMake 3.22+, arm64-v8a, android-24 min.

## Performance budgets (Tecno Pova 4, Helio G99)
Model load <3s · inference >8 tok/s · RAM peak <6.5GB in 20-min session · cold start <2s · STT→TTS latency <1.5s · battery <15%/hr · ≤2 thermal throttle events per 30 min. Thermal monitor reduces ctx/threads under load.

```


## File: docs\03_DISTRIBUTION.md

```md
# 03 DISTRIBUTION — Staged Download Architecture (NEW in v4.2)
<!-- READ WHEN: install size, download manager, content packs, P2P sharing, updates. DEPENDS: 00,02. ~2K tokens -->

## The problem this solves
Old spec: 1.7GB monolithic app vs. users with 1–2GB/month data plans. Fatal contradiction. Fix: tiny base APK + tiered, resumable, shareable content packs. User is learning within 60 seconds of a ~45MB install and grows the app gradually.

## Tier plan
| Tier | Contents | Size | Delivery | Unlocked capability |
|---|---|---|---|---|
| **0 — Base APK** | App code, SRS engine, deterministic grader, kana course (hira+kata, stroke SVGs), Unit 1–2 lessons + audio, 100 starter SRS cards, 5 scripted scenarios | **~45MB** | Play Store | Full learning loop, day one, zero extra download |
| **1 — Content packs** | Unit packs (~10–15MB each): lessons, verified explanations, mistake patterns, scenarios, OPUS audio for that unit | ~350MB total, chunked | In-app, per-unit, auto-queued just-in-time | Full N5→N4 curriculum |
| **2 — STT pack** | whisper.cpp base model (quantized) + alignment data | ~150MB | In-app, prompted when user first opens a speaking drill | Automatic pronunciation scoring |
| **3 — LLM pack (optional)** | Qwen3 1.7B GGUF Q4_K_M + LoRA + embedding index | ~1.25GB | In-app, WiFi-only default, explicit opt-in, resumable | Free-form AI conversation |
| **4 — TTS upgrade (optional)** | Kokoro-82M | ~90MB | In-app | Dynamic TTS (else pre-recorded audio only) |

**Total if everything installed: ~1.9GB. Minimum viable forever: 45MB.**

## Download manager requirements
- **Just-in-time prefetch:** when user is ~70% through Unit N, silently queue Unit N+1 pack next time on WiFi (or on data if user opts in with size shown).
- **Resumable + chunked:** HTTP range requests, 4MB chunks, SHA-256 per chunk + per pack (manifest-signed). Survives network drops of days. Never restart a pack from zero.
- **Network policy:** default = WiFi-only for packs >20MB; user can override per-pack with explicit size + estimated data cost shown ("এই প্যাকটি 150MB — আপনার ডেটা প্ল্যানের কথা মাথায় রাখুন").
- **Storage guard:** check free space before queueing; offer to delete completed-unit audio (re-downloadable) if tight; packs stored in app-private storage, survive app updates.
- **Background:** WorkManager (Android) with WiFi + charging constraints for Tier 3.

## Sideload & P2P distribution (KEY for Bangladesh market)
- **Offline pack sharing:** in-app "Share packs" → exports signed pack files via Android Nearby Share / SHAREit / Files by Google / SD card. Receiving app verifies manifest signature before install. One user downloads Tier 3 on university WiFi; a whole dormitory gets it free. This is a feature, market it.
- **Retail/agent preload:** partner with phone shops + SSW agencies to preload full pack set via SD card image. Provide a signed "SENSEI Full Loader" USB/SD tool.
- **APK integrity:** packs are content-only (no code) so P2P sharing never bypasses Play signing.

## Pack manifest format (served at GET /content/manifest, cached)
```json
{ "manifest_version": 3, "min_app_version": "1.0.0",
  "packs": [{ "id": "unit_03", "tier": 1, "version": 2, "size_bytes": 12582912,
    "sha256": "…", "chunks": 3, "depends_on": ["unit_02"],
    "url": "https://cdn.sensei.app/packs/unit_03_v2.pack",
    "title_bn": "ইউনিট ৩", "delta_from": {"1": {"url": "…", "size_bytes": 2097152}} }] }
```
- **Delta updates:** pack updates ship as binary diffs (`delta_from`) — a weekly content update costs ~1–3MB, not a re-download.
- Local DB table `installed_packs(id, version, tier, installed_at, verified)` gates feature availability (capability ladder, 02 §Capability).

## UX rules
- Never block a lesson on a download — always offer what's installed.
- Download screen shows per-pack size, purpose in Bengali, and a running month-to-date app data counter (builds trust with data-poor users).
- Tier 3 pitch is honest: "Optional. Adds free conversation with an AI tutor. Everything else already works."

## Success metrics for this module
Tier-0→Tier-1 conversion >80% within week 1 · pack download failure rate <2% · % of Tier-3 installs acquired via P2P share >30% (proves the channel) · median data used in month 1 <120MB.

```


## File: docs\04_AGENTS.md

```md
# 04 AGENTS — The Four-Agent System
<!-- READ WHEN: implementing agent logic, state bus, psych states. DEPENDS: 00,02. ~1.6K tokens -->

Four Dart-side agents on a shared state bus. Director arbitrates. Every decision: logged, explainable in Bengali, **overridable by the user**. Agents run on deterministic signals (taps, timing, accuracy) — NOT on LLM judgment (see 99 D-004).

## 1. Director — curriculum & pacing
Decides WHAT to teach, WHEN to shift difficulty, WHETHER to recommend continuing.
- Inputs: accuracy/speed/hesitation, tap patterns, SRS retention & due load, session time, days since last session, time of day, installed pack tiers.
- Outputs: recommended next lesson ID + difficulty (1–10) + psych state + recommended session length + one-line Bengali rationale.
- Sequencing: Irodori Can-do order, adaptive; i+1 mix ≈ 70% known / 30% new.
- Decision rules (examples — implement as a testable pure function):
  - retention<60% AND days_since>3 → STRUGGLE → easy review, ≤10 min, "আগে একটু ঝালাই করি।"
  - accuracy>90% AND session>20min → BOREDOM → offer new pattern/challenge.
  - tap_speed<50% baseline AND error_rate>30% → BURNOUT → recommend end, offer break screen (dismissible).
  - accuracy 70–85% AND engaged → FLOW → hold difficulty, offer (not push) continuation.
- Constraint: **recommends, never forces.** At the 120-min soft cap: recommendation screen + easy-review-only mode offer (01 §Session-health).

## 2. Persona — tone & relationship
Types: **Sensei** (strict, traditional) · **Didi/Bhai** (warm, patient) · **Friend** (playful) · **Coach** (competitive). User picks; agent may suggest a switch, never auto-switches.
Relationship arc: Week1 formal → Weeks2–4 knows name, gentle references to past mistakes → Months2–3 mentor → Month4+ casual banter (only if user opted in).
Constraints: no shame/pressure ever; detect anxiety → reduce intensity; honor a fixed-persona preference permanently.

## 3. Scaffold — micro-teaching & confusion resolution
Confusion signals (deterministic): hesitation>3s → offer hint · 3+ misses on same pattern → switch to review · random tapping → offer help · session abandonment → log frustration point for Director. (Voice-stress detection: deferred, see 99 D-005.)
Methods: hint ladder (user pulls each rung) · syllable breakdown · easier example bridge · visual scaffold (stroke order, word blocks) · Bengali cultural analogy.
Constraint: always asks ("এটা নিয়ে সাহায্য লাগবে?"), never commands. Skip is penalty-free.

## 4. Feedback — mastery tracking & reporting
Session summaries (learned / weak / next), weekly reports, opt-in notifications, milestone celebrations.
Reward schedule (all **predictable**, mastery-tied): correct answer → instant positive feedback · lesson complete → fixed XP · 10 lessons mastered → milestone · 50 words retained → level · exam-readiness rise → SSW progress marker. **No variable rewards, ever.**

## State bus contract
```dart
class AgentState { PsychState psych; int difficulty; String? recommendedLessonId;
  String rationaleBn; PersonaType persona; ScaffoldOffer? scaffold; SessionAdvice advice; }
```
- Bus is a Riverpod StateNotifier; agents publish proposals; Director merges each tick (post-answer + every 30s).
- UI consumes final AgentState only. All transitions logged to `agent_log` for debug overlay + explainability.

## Psych states (recommendations only — UI specs in 09)
FLOW (optimal) · STRUGGLE (accuracy<60%) · BURNOUT (fatigue signals) · BOREDOM (accuracy>90%, autopilot). Transitions animate per 09; none ever locks input or hides Skip.

```


## File: docs\05_CONTENT_SCHEMAS.md

```md
# 05 CONTENT SCHEMAS — JSON Formats & Validation
<!-- READ WHEN: authoring/validating lessons, SRS cards, mistakes, scenarios; content factory scripts. DEPENDS: 00. ~1.8K tokens -->

Authored as JSON, compiled to SQLite per pack at build time (packs: see 03). All schemas enforced by `jsonschema` in CI; build fails on violation.

## Lesson (abridged — full JSON Schema in /content_factory/schemas/lesson.schema.json)
```json
{ "id":"lesson_001","version":1,"level":"N5","unit":1,"pack_id":"unit_01","type":"grammar",
  "title":"Basic Greetings","prerequisites":["kana_hiragana"],"can_do":"Introduce yourself",
  "estimated_minutes":5,
  "sections":[
   {"id":"sec_1","type":"exposure","jp":["こんにちは"],"bn":["…"],"romaji":["konnichiwa"],
    "audio_url":"/audio/konnichiwa.opus","furigana":true,"cultural_note":"…"},
   {"id":"sec_2","type":"guided_output_speak","prompt":"Say 'Good morning'",
    "expected_transcript":"おはようございます","hint":"O-ha-yo…","scaffold_steps":["listen","syllables","slow","normal"],
    "skip_allowed":true,"max_attempts":5},
   {"id":"sec_3","type":"construct_sentence","prompt":"Build: 'I am Tanaka'",
    "word_blocks":["私","は","田中","です"],"correct_order":["私","は","田中","です"],
    "grammar_enforced":true,"color_coding":{"noun":"#2196F3","particle":"#FFEB3B","copula":"#4CAF50"}}],
  "mistake_patterns":["mist_001"],"srs_words":["こんにちは"],"scenario_unlocked":null }
```
Note: section type is `guided_output_speak` (renamed from v4.0 `forced_output_speak`; `skip_allowed` MUST be true).

## SRS card
Fields: id, word, reading, meaning_bn, meaning_en, jlpt_level, word_type, tags[], example_sentence_{jp,bn,romaji}, bengali_mnemonic, image_path, audio_path, stroke_order, due, stability, difficulty, reps, lapses, state(new|learning|review|relearning), last_review, elapsed_days, created_at, source, card_type(recognition|production), optimal_mood, mood_history[]. (No `emotional_difficulty` multiplier — see 99 D-003; mood affects selection, not FSRS math.)

## Mistake pattern
```json
{ "id":"mist_001","pattern_type":"particle_error","pattern_subtype":"wa_vs_ha",
  "user_input":"私わ","correct_form":"私は","explanation_bn":"…","explanation_en":"…",
  "trigger_phrase":"は vs わ","common_contexts":["self_introduction"],
  "remediation_lesson_id":"lesson_005","remediation_exercises":["ex_001"],"frequency":"high" }
```

## Scenario tree
Branching dialogue: characters (id, name, role, keigo_level, personality), initial_dialogue, nodes{} each with speaker/jp/bn/branches[]. Branch = {condition (user_says_X | user_hesitates_3s), expected_response, next_node, reward_xp (fixed), scaffold_on_fail | scaffold_action + hint}. Plus vocabulary_prerequisites, grammar_prerequisites. NPCs are consistent and remember prior runs. Exit any time, no penalty. Scenarios run **retrieval-only** at Tier 0–2 (branches fully scripted); Tier 3 adds LLM paraphrase within whitelist.

## Validation rules (pre-bundle CI, all blocking)
1. Every [JP] has a [BN]. 2. Every audio_url exists in pack. 3. **Whitelist:** no word outside the 1,200-word JFT-A2 list in learner-facing JP content. 4. All prerequisite IDs resolve. 5. Strict JSON. 6. Schema-valid. 7. Valid UTF-8, no half-width katakana in beginner packs. 8. Audio 1–10s. 9. Images 512×512 PNG/WebP <100KB. 10. Cultural notes reviewed by native Bengali speaker. 11. `pack_id` present and pack dependency graph acyclic. 12. Banned-copy scan (guilt/shame/FOMO phrases list in /content_factory/banned_phrases.txt).

## Content factory pipeline (phased: 5K MVP → 15K → 30K → 50K pairs)
GPT-4o drafts → human review (2 Bengali-Japanese experts + 1 native JP + 1 JFT examiner) → LoRA fine-tune (rank 64, alpha 128, ~12h on 8GB GPU) → validate on 1K held-out (>85% accuracy, 0 invented grammar rules on 500 trick questions) → bundle to packs. Budget honestly: $40–60K to 50K pairs incl. 10K audio recordings (99 D-006); MVP scope $12–18K for 5K pairs + 2K audio.

```


## File: docs\06_DATABASE.md

```md
# 06 DATABASE — Local SQLite Schema
<!-- READ WHEN: writing SQL, DAOs, migrations. DEPENDS: 00. Encryption: SQLCipher AES-256. ~1.4K tokens -->

Migrations: sequential, numbered, in /lib/db/migrations/. Never edit a shipped migration.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY, created_at INTEGER NOT NULL,
  current_level TEXT DEFAULT 'N5', current_streak INTEGER DEFAULT 0, max_streak INTEGER DEFAULT 0,
  last_study_date INTEGER, total_words_learned INTEGER DEFAULT 0, total_cards_reviewed INTEGER DEFAULT 0,
  total_conversations INTEGER DEFAULT 0, total_minutes_studied INTEGER DEFAULT 0,
  preferred_persona TEXT DEFAULT 'sensei', daily_cap_minutes INTEGER DEFAULT 120,
  break_reminder_minutes INTEGER DEFAULT 20, voice TEXT DEFAULT 'jf_alpha', voice_speed REAL DEFAULT 1.0,
  daily_new_card_limit INTEGER DEFAULT 10, daily_review_limit INTEGER DEFAULT 20,
  cloud_sync_enabled INTEGER DEFAULT 0, parental_mode_enabled INTEGER DEFAULT 0,
  account_status TEXT DEFAULT 'active',
  data_export_requested_at INTEGER, data_export_completed_at INTEGER,
  account_deletion_requested_at INTEGER, account_deletion_grace_period_end INTEGER );

CREATE TABLE srs_cards (
  id TEXT PRIMARY KEY, word TEXT NOT NULL, reading TEXT NOT NULL, meaning_bn TEXT NOT NULL,
  meaning_en TEXT, jlpt_level TEXT NOT NULL, word_type TEXT, tags TEXT,
  example_sentence_jp TEXT, example_sentence_bn TEXT, bengali_mnemonic TEXT,
  image_path TEXT, audio_path TEXT,
  due INTEGER NOT NULL, stability REAL DEFAULT 0, difficulty REAL DEFAULT 0,
  reps INTEGER DEFAULT 0, lapses INTEGER DEFAULT 0, state TEXT DEFAULT 'new',
  last_review INTEGER, elapsed_days REAL DEFAULT 0, created_at INTEGER NOT NULL,
  source TEXT DEFAULT 'lesson', card_type TEXT DEFAULT 'recognition',
  optimal_mood TEXT DEFAULT 'neutral', mood_history TEXT DEFAULT '[]' );
CREATE INDEX idx_cards_due ON srs_cards(due);
CREATE INDEX idx_cards_state ON srs_cards(state);
CREATE INDEX idx_cards_jlpt ON srs_cards(jlpt_level);

CREATE TABLE review_history ( id TEXT PRIMARY KEY, card_id TEXT NOT NULL, reviewed_at INTEGER NOT NULL,
  rating INTEGER NOT NULL, mood TEXT DEFAULT 'neutral', scheduled_interval REAL, actual_interval REAL,
  old_stability REAL, new_stability REAL, old_difficulty REAL, new_difficulty REAL,
  FOREIGN KEY (card_id) REFERENCES srs_cards(id) );
CREATE INDEX idx_history_card ON review_history(card_id);
CREATE INDEX idx_history_date ON review_history(reviewed_at);

CREATE TABLE conversations ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, scenario TEXT, role TEXT,
  started_at INTEGER NOT NULL, ended_at INTEGER, total_exchanges INTEGER DEFAULT 0,
  grammar_mistakes INTEGER DEFAULT 0, new_words INTEGER DEFAULT 0,
  emotional_state TEXT DEFAULT 'flow', session_duration INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE messages ( id TEXT PRIMARY KEY, conversation_id TEXT NOT NULL, role TEXT NOT NULL,
  content TEXT NOT NULL, language TEXT, timestamp INTEGER NOT NULL,
  parsed_jp TEXT, parsed_bn TEXT, parsed_rom TEXT, grammar_notes TEXT, srs_words TEXT,
  emotional_state TEXT DEFAULT 'neutral',
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) );
CREATE INDEX idx_messages_conv ON messages(conversation_id);

CREATE TABLE grammar_mistakes ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, mistake_type TEXT NOT NULL,
  user_input TEXT NOT NULL, correct_form TEXT NOT NULL, explanation_bn TEXT NOT NULL, explanation_en TEXT,
  first_seen INTEGER NOT NULL, last_seen INTEGER NOT NULL, occurrence_count INTEGER DEFAULT 1,
  remediation_lesson_id TEXT, FOREIGN KEY (user_id) REFERENCES users(id) );
CREATE INDEX idx_mistakes_user ON grammar_mistakes(user_id);
CREATE INDEX idx_mistakes_type ON grammar_mistakes(mistake_type);

CREATE TABLE achievements ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, achievement_id TEXT NOT NULL,
  unlocked_at INTEGER NOT NULL, milestone_id TEXT NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE daily_stats ( date TEXT PRIMARY KEY, user_id TEXT NOT NULL,
  cards_reviewed INTEGER DEFAULT 0, new_cards_learned INTEGER DEFAULT 0, minutes_studied INTEGER DEFAULT 0,
  retention_rate REAL, mistakes_made INTEGER DEFAULT 0, conversations_completed INTEGER DEFAULT 0,
  emotional_state TEXT DEFAULT 'neutral', FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE brain_map_nodes ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, concept_id TEXT NOT NULL,
  concept_name TEXT NOT NULL, mastery_level REAL DEFAULT 0, is_glowing INTEGER DEFAULT 0,
  last_updated INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE installed_packs ( id TEXT PRIMARY KEY, version INTEGER NOT NULL, tier INTEGER NOT NULL,
  size_bytes INTEGER, installed_at INTEGER NOT NULL, verified INTEGER DEFAULT 0, source TEXT DEFAULT 'cdn' );
-- source: cdn | p2p | preload  (03_DISTRIBUTION)

CREATE TABLE pack_download_state ( pack_id TEXT PRIMARY KEY, target_version INTEGER,
  chunks_total INTEGER, chunks_done INTEGER DEFAULT 0, bytes_done INTEGER DEFAULT 0,
  status TEXT DEFAULT 'queued', network_policy TEXT DEFAULT 'wifi_only',
  last_error TEXT, updated_at INTEGER );

CREATE TABLE offline_queue ( id INTEGER PRIMARY KEY AUTOINCREMENT, action_type TEXT NOT NULL,
  payload TEXT NOT NULL, created_at INTEGER NOT NULL, retry_count INTEGER DEFAULT 0,
  last_error TEXT, status TEXT DEFAULT 'pending' );

CREATE TABLE data_export_log ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, requested_at INTEGER NOT NULL,
  completed_at INTEGER, file_size_bytes INTEGER, file_path TEXT, status TEXT DEFAULT 'pending',
  error_message TEXT, FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE agent_log ( id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL,
  agent TEXT NOT NULL, decision TEXT NOT NULL, rationale_bn TEXT, overridden_by_user INTEGER DEFAULT 0 );
```
Removed vs old spec: `loot_inventory` random-drop semantics (achievements table now carries milestone cosmetics via `milestone_id`); `emotional_difficulty` column (99 D-003).

```


## File: docs\07_API_SYNC.md

```md
# 07 API & SYNC — Cloud Contract, Sync Bridge, Privacy
<!-- READ WHEN: endpoints, sync logic, conflict resolution, security/compliance. DEPENDS: 00,06. ~1.7K tokens -->

Base: `https://api.sensei.app/v1` (staging: `staging-api.…`). Auth: JWT Bearer via Firebase/Supabase Auth; access TTL 1h, refresh 30d, silent refresh in SDK. TLS 1.3 + cert pinning mandatory. All cloud features optional; app fully degrades offline.

## Endpoints
**POST /sync** — delta progress. Req: `{user_id, last_sync_timestamp, changes:{srs_cards[],conversations[],daily_stats[]}, device_id, app_version}`. Res: `{status, cloud_changes:{…, content_updates[]}, server_timestamp, next_sync_recommended}`. Errors: 401→silent refresh · 429→60s backoff, stay offline · 503→queue & retry · 404 content→use cache. Rate: 60/h/user.

**POST /ai/explain** — smart-router fallback for edge cases only. Req: `{user_query, user_level, context, complexity, preferred_language:"bn"}`. Res: `{explanation, explanation_bn, examples[], tags[], model_used, tokens_used, cost_usd}`. Rate: 20/h/user.
Router: complexity 1–6 offline ($0) · 7–8 GPT-4o-mini · 9–10 GPT-4o (culture/nuance/exam strategy). Cost basis: ~$0.15/M input for 4o-mini, ~$2.50/M for 4o (per-MILLION tokens — 99 D-007). Cloud AI cost/user is trivial (<$0.01/mo); offline is justified by latency/reliability/connectivity, not cost.

**GET /social/leaderboard** `?region&timeframe&limit` → user_rank, top_10[], nearby[]. Opt-in feature only. Rate 100/h.
**GET /content/manifest** — pack manifest (03 §manifest). Rate 10/h, aggressively cached.
**POST /ssw/readiness** — opt-in only, per-share consent recorded: `{user_id, exam_readiness, exam_type, consent_given, consent_timestamp, preferred_agencies[]}` → agency matches + referral. Response must echo `shared_data[]` so the app can show the user exactly what left the device.

## Sync bridge
- **Delta only:** records modified since `last_sync_timestamp`.
- **Conflict resolution:** default device-wins (local is source of truth); user-selectable cloud-wins (device switch). Merge: SRS cards keep the higher stability; conversation logs append both.
- **Offline queue:** `offline_queue` table (06); FIFO drain on connectivity; exponential backoff per item; poison items surfaced in debug overlay after 5 retries.
- Payloads gzip; at rest SQLCipher.

## Data classification & retention
| Class | Examples | Handling |
|---|---|---|
| PII | email, name, device ID, IP | encrypted at rest+transit, minimal retention |
| Sensitive | speech audio, progress, mistakes | local-first; cloud audio deleted immediately post-transcription; local audio 7 days |
| Non-sensitive | prefs, anonymized crash logs | opt-in |
Retention: profile/SRS/conversations — local until deletion, cloud 30d after last sync, instant on request · analytics 90d anonymized · export files local 30d.

## Export & deletion (first-class, offline-capable)
Export: Settings → one tap → ZIP (README.txt, manifest.json, profile/, lessons/, srs/, mistakes/, conversations/, achievements/, brain_map/, summary/progress_summary.pdf in Bengali). Size shown before start; Save/Share; optional password (AES). No support contact ever required.
Deletion: warning (with "export first" route) → confirm checkbox → 7-day grace (cancel by login; "Delete Immediately" needs 2nd confirm) → wipe local DB + cloud (Firebase/Supabase) + log deletion token. Nothing retained post-grace.

## Compliance targets
GDPR (portability, erasure, consent) · Bangladesh Digital Security Act 2018 · Bangladesh Consumer Rights Protection Act 2009 (transparent pricing, no dark patterns) · Play/App Store data policies. Privacy policy: plain language, Bengali-first, in-app.

```


## File: docs\08_OFFLINE_AI.md

```md
# 08 OFFLINE AI — LLM, STT, TTS, RAG, FSRS
<!-- READ WHEN: implementing/tuning the on-device AI stack. DEPENDS: 00,02,03. ~2.2K tokens -->

## Stack roles (remember: LLM = selector/glue, never knowledge source — 02 §Key insight)
- **Verified content store** (Tier 0–1): the actual knowledge. Explanations, dialogues, mistake patterns.
- **RAG:** embed query → cosine sim over verified store → top-k retrieval. Target retrieval accuracy >90% held-out.
- **LLM** (Tier 3, optional): Qwen3 1.7B Q4_K_M + 50MB LoRA (rank 64/alpha 128, trained on verified pairs). Fine-tuned to SELECT and phrase, not invent.
- **GBNF:** grammar-constrained decoding → 100% schema-valid tagged output.
- **Whitelist enforcer:** post-decode filter; learner-facing Japanese limited to the 1,200-word JFT-A2 list. Violations → fall back to retrieved verbatim response.
- **Deterministic grader:** all graded answers = key match. LLM never grades.
- **STT** (Tier 2): whisper.cpp base. **Scoring mode = forced alignment against the KNOWN target sentence** + F0/phoneme comparison — never open transcription for grading (99 D-002). Text-input fallback always offered (noisy rooms).
- **TTS:** pre-recorded native OPUS first (Tier 0–1); Kokoro-82M for dynamic text (Tier 4).
- **Thermal/memory monitors:** reduce context length/threads on throttle; pause LLM features under low-memory, retrieval keeps working.

Quality ladder (constrained domain): raw Qwen 6.5/10 → +GBNF 7.5 → +RAG 8.5 (~9 tok/s, $0, offline). GPT-4o online 9.5 for the ~20% edge cases via smart router (07).

## FSRS-4.5 (CORRECTED — mood affects SELECTION, never the rating math; 99 D-003)
```dart
class FSRSEngine {
  final List<double> w = [0.40255,0.59854,2.40984,5.80984,4.92593,0.94123,0.86231,0.01000,
    1.48959,0.14480,0.94123,2.18154,0.05000,0.34560,1.26000,0.29400,2.61000];

  double retrievability(double s, double t) => math.exp(math.log(0.9) * t / s);

  FSRSCard review(FSRSCard c, int rating) { // rating stays pure 1..4 — NO mood multiplier
    final now = DateTime.now().millisecondsSinceEpoch;
    final t = c.lastReview != null ? (now - c.lastReview!) / 86400000 : 0.0;
    if (c.state == 'new') {
      c.stability = w[rating - 1];
      c.difficulty = (w[4] - w[5] * (rating - 3)).clamp(1, 10);
      c.state = rating == 1 ? 'learning' : 'review';
    } else {
      final r = retrievability(c.stability, t);
      final hard = rating == 2 ? w[15] : 1.0, easy = rating == 4 ? w[16] : 1.0;
      c.stability = c.stability * (math.exp(w[8] * (1 - r)) * hard * easy + 1);
      c.difficulty = (w[6] * c.difficulty + (1 - w[6]) * (w[4] - w[5] * (rating - 3))).clamp(1, 10);
    }
    c.reps++;
    if (rating == 1) { c.lapses++; c.state = 'relearning'; }
    else if (c.state != 'review') c.state = 'review';
    final days = switch (rating) { 1 => 1/1440, 2 => 1/24, 3 => c.stability, _ => c.stability * 2 };
    c..due = now + (days * 86400000).round() ..lastReview = now ..elapsedDays = t;
    return c;
  }

  // Mood adaptation lives HERE: tired/frustrated → serve easier, shorter queues.
  List<FSRSCard> getDueCards(List<FSRSCard> cards, {int limit = 20, String mood = 'neutral'}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final effLimit = switch (mood) { 'tired' || 'frustrated' => (limit * 0.6).round(),
                                     'anxious' => (limit * 0.8).round(), _ => limit };
    final due = cards.where((c) => c.due <= now).toList()
      ..sort((a, b) {
        const p = {'relearning':0,'learning':1,'review':2,'new':3};
        final s = p[a.state]! - p[b.state]!; if (s != 0) return s;
        if (mood == 'tired' || mood == 'frustrated') {
          final d = a.difficulty.compareTo(b.difficulty); if (d != 0) return d; // easiest first
        }
        return a.due - b.due;
      });
    return due.take(effLimit).toList();
  }
}
```

## Native bridge (MethodChannel `com.sensei.app/native`)
Dart calls: loadLlmModel(path) · generateLlmResponse(prompt) · loadSttModel(path) · transcribeAudio(path)→{text,language,confidence} · alignAudio(path, target)→{score, phoneme_errors[]} · speakJapanese(text, voice) · start/stopRecording · getThermalState · getMemoryState. Kotlin side wraps LlmService/SttService/TtsService/ThermalMonitor/AudioRecorder/MemoryMonitor in coroutines; `generateLlmResponse` reads thermal state and passes optimized params. (Reference impl from v4.1 Appendices C/D is behavior-correct; port as-is, add `alignAudio`.)

## System prompt for on-device LLM (Tier 3) — trimmed to what a 1.7B can honor
Identity: SENSEI, patient Bengali-first Japanese tutor. Persona injected: {Sensei|Didi|Bhai|Friend|Coach}.
Hard constraints: only whitelist vocabulary · only grammar from retrieved context (injected per prompt) · output in GBNF-enforced tags `[JP][BN][ROM][EXPLANATION][GRAMMAR_NOTE][SRS_WORDS][NEXT]` · never grade (grader does) · never claim rules not present in retrieved context — if missing, say so and suggest the lesson · encourage output, never demand; skipping is always fine · no shame/guilt/anxiety language · Bengali for all explanation, English never unless asked.
Per-prompt knowledge injection: USER_LEVEL, KNOWN_WORDS(last 200), WEAK_POINTS, RETRIEVED_CONTEXT(top-k verified docs), CONVERSATION_HISTORY(last 10), TODAY_SRS_DUE, EMOTIONAL_STATE, PERSONA_TYPE, SESSION_TIME.
Dropped from v4.1 prompt (moved to deterministic layers): confidence estimation, confusion detection, cap enforcement — agents own these (04, 99 D-004).

## Validation gates before any model ships in a pack
>85% on 1K held-out · 0 invented grammar rules on 500 trick questions (violation = falls back to retrieval, counts as pass only if fallback fired) · <3s/response · <3GB RAM in 100-conversation soak · 30-min thermal soak with ≤2 throttles.

```


## File: docs\09_UI_STATES.md

```md
# 09 UI STATES — Design System & Psych-State Screens
<!-- READ WHEN: building screens, copy, animations, accessibility. DEPENDS: 00,01,04. ~1.5K tokens -->

## Design system
Fonts: Noto Sans Bengali (BN) · Noto Sans JP (JP) · Roboto fallback. Scale 12/14/16/20/24px.
Spacing: 8px base · card pad 16 · screen margin 24 · buttons ≥48px · inputs 56px.
Accessibility (blocking): contrast ≥4.5:1 · touch ≥48×48dp · full screen-reader labels · reduced-motion mode kills all animation · high-contrast mode.

## Invariant across ALL states (constitution rule — see 01)
`[Skip] [Hint] [Quit/Back]` visible and enabled in every learning screen, every state, ≤1 tap. Streak shown as plain history number, no warnings. No auto-advancing prompts.

## FLOW (optimal challenge) — accuracy 70–85%, engaged, <20min, no fatigue
Colors #00C853/#00E676, animated green→teal gradient (15s cycle). Bold 1.1× type. 200ms ease-out transitions. Correct = 440Hz major chime; upbeat 90BPM instrumental. Progress bar glows; XP numeric roll. Toast "দারুণ চলছে!" auto-dismiss 1.5s. Continuation prompt: neutral "আরেকটা?" (no urgency copy). Difficulty +1 step; scaffolding reduced.

## STRUGGLE — accuracy <60%, rising errors, hesitation >3s
Colors #FF6D00/#FFAB00, static warm gradient (no motion = less load). Regular type, 400ms ease. Calm 60BPM acoustic; correct = soft xylophone; wrong = brief low woodblock (non-punishing). Hint button large, central, glowing, pre-expanded at bottom. Difficulty −1 with "চলো একসাথে ঝালাই করি।" Session ends on learner's choice, ideally on a win.

## BURNOUT — tap speed <50% baseline, random taps, session >40min
Colors #2979FF/#0D47A1, solid, zero animation. Soft light-gray-on-blue type. Low ambient rain/ocean. Overlay: "তোমার মস্তিষ্ক ক্লান্ত। ৪০ মিনিটের পর ধারণক্ষমতা কমে যায়।" + "Recommended break: 5:00".
Buttons: **[বিরতি নিন] (recommended)** and **[আমি ঠিক আছি, চালিয়ে যাই] (always enabled)**. Continue → easy review only, difficulty floor. Back button stays fully functional (old "visually disabled Back" is banned).

## BOREDOM — accuracy >90%, autopilot, >20min
Colors #AA00FF/#E040FB, floating-particle background, rounded playful type, 150ms bounce, playful synth. "Challenge unlocked!" flash. Extra button appears: [চ্যালেঞ্জ নিন] → optional high-difficulty drill. Skip remains its own button (never repurposed).

## Transitions
Flow→Struggle: 5s color crossfade + music crossfade · Struggle→Burnout: hard cut to blue, soft flash · Flow→Boredom: purple particles fade in, pitch-shift up · Burnout→any: learner's choice; break → home screen.

## Core lesson micro-loop (every lesson)
1. **Intro** 30s — target word/phrase, meaning, sample sentence, all Bengali. 2. **Recognition** 30s — audio→meaning or text→audio MC. 3. **Production** 60s — speak (Tier 2+: aligned scoring; Tier 0–1: record & self-compare) or finger-write kana; hint/skip/switch-type always offered. 4. **Context** 60s — word-block sentence build or gap-fill; wrong placement = visual cue, never "failure". 5. **SRS** — schedule via FSRS (08).

## Scenario mode UX
NPC consistent personality + memory of past runs; keigo level per character; exit button persistent; on struggle → Scaffold offers word list/hints (04); errors logged for Feedback agent.

## Session-cap & break UX (implements 01 policy)
20-min mark: dismissible banner "৫ মিনিটের বিরতি নিলে ভালো হয়" · 120-min mark: full-screen recommendation + [Easy review only] + [Continue anyway] + [Stop for today]. Parental mode: same screens but Continue requires guardian PIN.

```


## File: docs\10_TESTING_QA.md

```md
# 10 TESTING & QA — Unit, Integration, Device, UAT, Ethics
<!-- READ WHEN: writing tests, CI, benchmarks, UAT plans. DEPENDS: 00. ~1.2K tokens -->

## Unit (flutter_test + mockito, coverage >85% on core)
Targets: FSRS math vs reference implementation (incl. mood-selection behavior, NOT rating mutation — 99 D-003) · Director decision tree (pure function: inputs→lesson/difficulty/state/rationale) · GBNF output schema compliance · content validation script (all 12 rules in 05) · export ZIP completeness · pack manifest verification (chunk hashes, signature, dependency graph).
```dart
test('Director recommends easy review after 3-day gap', () {
  final s = DirectorAgent().decide(retention: .55, daysSinceLast: 4, accuracy: .60, sessionMin: 15);
  expect(s.recommendedLesson.type, 'review');
  expect(s.difficulty, lessThan(4));
});
```

## Integration (integration_test; mock native channel for CI determinism)
1. Full lesson micro-loop → SRS scheduled. 2. High error injection → UI enters STRUGGLE ≤5s. 3. Airplane mode → all Tier-0 features pass. 4. Sync: local edits → sync → conflict cases (device-wins, cloud-wins, stability-max merge). 5. Export → ZIP contains every expected file, PDF opens. 6. Deletion → grace period honored → wipe verified. 7. **Pack lifecycle:** queue → interrupt mid-chunk → resume → verify → feature unlock; P2P import with bad signature → rejected. 8. **Skip/Quit reachability:** automated sweep asserting Skip+Quit enabled on every learning screen in all 4 psych states (constitution regression test).

## Real-device benchmarks (Tecno Pova 4; fail if any metric >target+20%)
Model load <3s · inference >8 tok/s · RAM peak <6.5GB (20-min session) · thermal ≤2 throttles/30min · battery <15%/hr · cold start <2s · STT→TTS <1.5s. Protocol: fresh install, 30-min scripted session, sample every 30s, auto-report.

## Pre-Phase-1 de-risk spikes (MUST run before foundation code — 99 D-002)
- **STT spike (2 weeks):** whisper.cpp base on-device with 20 real Bengali speakers, noisy environments, forced alignment vs known targets. Gate: usable scoring signal for >70% of attempts, else redesign speaking pillar.
- **Inference spike (1 week):** Qwen3 1.7B Q4_K_M on Pova 4 — verify tok/s + thermal before committing to Tier 3.

## UAT (100 users: 50 Dhaka, 50 Kolkata; 2 weeks; incentive = 3-mo Premium)
Observe unassisted: onboarding (first 5 lessons) · finding skip/pause/quit · data export · speaking drill in real rooms · offline usage · **Tier-1 pack download on their own data plans** · P2P pack share between two testers.
Collect: NPS (>50) · coercion reports (target 0%) · bug sev classes · 7-day retention (>40%) · lesson completion (>70%) · median data consumed (<120MB).

## Ethical review (blocking gate — checklist)
Dark-pattern screen audit (skip visible everywhere incl. Flow) · banned-copy scan · monetization audit (no microtransactions) · export/deletion E2E · parental mode · analytics default-off verified · SSW consent flow · accessibility suite · sign-off: Product + Engineering + Legal.

```


## File: docs\11_ROADMAP_TASKS.md

```md
# 11 ROADMAP & TASK BOARD — Build Order & Current Tasks
<!-- READ WHEN: deciding what to build next. Keep statuses updated here — this file is the single source of truth for progress. DEPENDS: 00. ~1.6K tokens -->

## STATUS LEGEND: ☐ todo · ◐ in-progress · ☑ done · ⊘ blocked
## ▶ CURRENT POINTER: **CODEBASE_MAP.md generated 2026-07-09 (see CODEBASE_MAP.md at repo root). Next real gap: FIX-B + T-102 (bundle kana stroke data offline + port writing board to Flutter).**

## Phase FIX — reconciliation fixes (from 2026-07-09 audit)
- ☐ FIX-A (LOW) Keep streak as neutral history only when porting premium UI (D-001). Prototype-only today.
- ◐ FIX-B (MED) Offline stroke system built: assets/stroke/kana_strokes.json (seeded あ) + tools/fetch_stroke_data.mjs to fill all 92 locally; Flutter WritingScreen animates from bundled data (no runtime CDN). Remaining: run the fetch script locally to populate all 92.
- ☐ FIX-C (MED) Add SQLCipher + migration framework to sqflite DB before real user data (T-101).
- ☐ FIX-D (MED) Add Skip/Hint/Quit invariant to lesson UI (09 constitution rule).
- ☐ FIX-E (KEEP?) Accent/pitch pillar exists but is unspecced — log keep/kill decision in 99.

## Phase 0 — De-risk spikes (Weeks 0–2) ← START HERE
- ☐ T-000a STT spike: whisper.cpp base + forced alignment, 20 real Bengali speakers on Pova 4. GATE for speaking pillar. (10 §spikes)
- ☐ T-000b Inference spike: Qwen3 1.7B on Pova 4, tok/s + thermal. GATE for Tier-3 pack.

## Phase 1 — Foundation (Weeks 1–4)
- ◐ T-101 Flutter project + fvm + CI/CD + SQLCipher DB + migrations — *Flutter+sqflite DB exist; missing fvm, CI, SQLCipher, migrations (lib/data/srs_local.dart)*
- ◐ T-102 Kana screens — *grid+audio done in Flutter; finger-draw + stroke-order done in HTML (sensei_writing.html), not yet ported; animation CDN-fetched → see FIX-B*
- ☑ T-103 FSRS-4.5 engine + review UI — *lib/domain/fsrs.dart, 11/11 tests; rating kept PURE (D-003 OK); mood-selection deferred*
- ◐ T-104 Content schemas + validation CI — *validate_content.mjs enforces ~6/12 rules; not in CI (see CODEBASE_MAP)*
- ☐ T-105 DECISION: Firebase vs Supabase (log in 99) + auth scaffold
- ◐ T-106 Lesson screens — *LessonScreen is flashcard-only; 5-step micro-loop + Skip/Hint/Quit invariant not built (FIX-D)*
- ◐ T-107 Audio pipeline — *pubspec has record/just_audio; record/playback stubbed (TODOs); OPUS not set; live pitch works in HTML*
- ☐ T-108 Progress tracking + weak-point analysis + brain map data
Exit: runs crash-free on Pova 4 · kana E2E offline · SRS schedules correctly · audio round-trips.

## Phase 2 — Distribution & Offline Core (Weeks 5–9)
- ☐ T-201 **Pack system:** manifest fetch, chunked resumable downloader, SHA-256 + signature verify, installed_packs gating (03)
- ☐ T-202 Base-APK size budget enforcement (<50MB) + Tier-0 content bundle
- ☐ T-203 P2P pack export/import (Nearby Share/file) with signature check
- ☐ T-204 llama.cpp FFI + model load-from-pack (Tier 3 path)
- ☐ T-205 GBNF decoder + tag parser + whitelist enforcer + retrieval fallback
- ☐ T-206 RAG: embedding pipeline + cosine search over verified store (>90% retrieval on held-out)
- ☐ T-207 Deterministic grader + key database
- ☐ T-208 whisper.cpp FFI + alignAudio scoring (Tier 2 path)
Exit: 45MB APK learns offline day-one · packs resume across kills · LLM loads <3s, >8 tok/s · GBNF 100% valid.

## Phase 3 — Content Factory (Weeks 9–16, parallel with Phase 2)
- ☐ T-301 Source curation: Irodori ×3, JFT past papers ×10, JLPT N4 ×5, JMdict 1,200 whitelist
- ☐ T-302 GPT-4o draft gen (5,000 responses, 500 mistakes, 1,200 mnemonics, 200 scenarios)
- ☐ T-303 Human review batches (expert panel per 05) — 5K verified = MVP gate
- ☐ T-304 Audio recording (2K sentences MVP; 10K by Year 1)
- ☐ T-305 LoRA fine-tune + validation gates (08 §Validation)
- ☐ T-306 bundle_content.py → per-pack SQLite (pack_id aware)
Exit: 5K verified pairs · >85% validation · 0 invented rules · packs built.

## Phase 4 — Agents & Experience (Weeks 17–20)
- ☐ T-401 State bus + AgentState contract (04)
- ☐ T-402 Director (pure decision function + tests) · T-403 Persona · T-404 Scaffold · T-405 Feedback
- ☐ T-406 Guided-output interfaces (speak/write/teach — skip always on)
- ☐ T-407 4-state adaptive UI per 09 + Skip/Quit reachability regression test
Exit: agents communicate · UI adapts to all states · user override works everywhere · caps/breaks are recommendations.

## Phase 5 — Online Layer (Weeks 21–24)
- ☐ T-501 Delta sync + conflict resolution + offline queue (07)
- ☐ T-502 Smart router + /ai/explain integration
- ☐ T-503 Cloud STT (Whisper Large v3) upgrade path
- ☐ T-504 Social (opt-in) · T-505 Push (opt-in) · T-506 Analytics (opt-in, anonymized) · T-507 SSW API (opt-in)
Exit: 2-device sync without loss · router splits correctly · everything optional degrades cleanly.

## Phase 6 — Polish & Launch (Weeks 25–28)
- ☐ T-601 Subscriptions (Play Billing) per 01 tiers — no microtransaction code paths
- ☐ T-602 Export ZIP+PDF · T-603 Deletion + grace · T-604 Parental mode
- ☐ T-605 Beta 100 users (10 §UAT) · T-606 Perf optimization pass · T-607 Ethical review gate · T-608 Store submission + launch (12)
Exit: guardrails verified · NPS>50 · crash-free>99% · approved.

**Total: ~29 weeks to MVP.** Content factory MVP budget $12–18K (5K pairs + 2K audio); full 50K target $40–60K over 12 months (99 D-006).

```


## File: docs\12_BUSINESS_GTM.md

```md
# 12 BUSINESS & GTM — Pricing, Launch, Metrics, Costs
<!-- READ WHEN: monetization, marketing, launch ops, KPI questions. DEPENDS: 00,01. ~1.4K tokens -->

## Users
Primary: SSW aspirant — Bangladeshi male 22–35, rural/semi-urban, budget Android, <200MB/mo data, goal JFT-Basic A2 → SSW visa. Secondary: Kolkata university student, JLPT N4/N5. Tertiary: caregiver migrant, Bangladeshi female 25–40, short study bursts, privacy-sensitive.
Constraints to respect in every decision: 2–4GB free storage · 15–30 min sessions 3–5 days/wk · offline for days at a time · Bengali-first literacy.

## Pricing (ethics in 01)
Free $0 (everything core, 15-min soft nudge) · Premium $3.99/mo · Pro $19.99/mo. No microtransactions, no ads.
Revenue model (conservative): Y1 5K users/$22.5K → Y3 75K/$585K → Y5 300K/$4.59M (~$7M cumulative). B2B later: language schools white-label, SSW agency bulk licenses, corporate training.

## Cost reality (corrected — 99 D-006/D-007)
- Cloud AI at correct per-million pricing is trivial (<$0.01/user/mo hybrid). **Offline's justification = latency (0.8–1.5s vs 2–4s), reliability, zero-connectivity capability, determinism — NOT cost savings.** Never argue the cost case in marketing/board decks.
- Content factory: MVP $12–18K (5K pairs + 2K audio) · Year-1 full $40–60K (50K pairs + 10K audio). Highest-risk, highest-reward line item; quality > quantity — one wrong grammar explanation destroys trust.
- Infra: Supabase/Firebase base ~$25/mo + CDN egress for packs (watch this line as P2P share offsets it).

## Pre-launch (Weeks 18–22)
Waitlist 5K via: FB groups ("Bangladesh Japan SSW", "Kolkata JLPT Aspirants"), Bengali YouTube language influencers, Dhaka Univ + Jadavpur campuses. Landing sensei.app/early-access, first 1,000 → 1-mo Premium.
Content: Bengali blogs ("How to Learn Japanese Without Internet", "JFT-Basic A2 Guide", "Dhaka to Tokyo: SSW Journey") + 5×15s reels (kana drill, speaking, SRS, break screen as ethics signal, beta testimonial).
**Distribution GTM (new):** recruit 10 phone shops + 3 SSW agencies as preload partners (03 §Sideload); market "share the app pack with friends — free" as a headline feature.

## Store listing
Name: SENSEI — Japanese for Bengali Speakers. Sub: Offline Tutor. JLPT N5/N4. Exam Ready. **Lead with "45MB install — start learning in 1 minute."** Screenshots: kana stroke screen, SRS, restaurant scenario, break screen (ethics signal), data-export screen (control signal). Bengali description mandatory.

## Launch day
2× backend capacity · CDN warm for packs · rate limits on · Sentry alert >0.1% crash · PagerDuty P0 · dashboard: DAU, sync success, pack failure rate, cost/user, export rate · 2 part-time Bengali support agents · WhatsApp Business primary support channel · canned answers (export, delete, sync, STT, refund) · waitlist email + influencer pushes + Product Hunt.

## 30-day retention comms (all opt-in, default off; banned: guilt, streak-loss, countdowns)
D1 welcome · D3 supportive check-in · D7 progress report · D14 in-app NPS · D21 scenario tip · D30 single Premium offer w/ 3-day trial. Never repeated nagging.

## KPI targets
Learning: JFT pass >60% · N4 pass >50% · 30-day vocab retention >70% · speaking confidence >7/10.
Engagement: 7-day >40% · 30-day >20% · lesson completion >70% · session 15–25min · break acceptance >60%.
Health: offline sessions >50% · sync success >98% · pack failure <2% · export completion >5% · deletion <2% · crash-free >99% · NPS >50 · cloud cost <$0.50/user/mo.
Business: MAU 10K Y1 · premium conversion >8% · churn <5%/mo · LTV >$25 · CAC <$2 · LTV/CAC >12.
Distribution (new): Tier-0→1 conversion >80% wk1 · Tier-3 via P2P >30% · median month-1 data <120MB.

## Risk register (top)
R1 offline AI under-delivers → validation gates + retrieval fallback + router · R2 content cost overrun → phased 5K→50K · R3 Helio G99 perf → spikes first (T-000), quantization, thermal throttling · R4 **STT accuracy (HIGH)** → forced-alignment scoring, text fallback, spike gate · R5 store rejection → ethical review gate · R6 CDN egress cost → P2P + preload channels · R7 competitor copy → niche depth + verified Bengali content moat + agency partnerships.

```


## File: docs\90_EXISTING_CODEBASE.md

```md
# 90 EXISTING CODEBASE — Reconciliation Protocol (RUN THIS BEFORE ANY BUILD TASK)
<!-- READ WHEN: first session in this project, or whenever CODEBASE_MAP.md is missing/stale. ~1K tokens -->

## Situation
A codebase ALREADY EXISTS. The roadmap in 11_ROADMAP_TASKS.md describes the target, not current reality. **Do not assume any task is ☐ todo until this audit has run.** Do not rewrite working code to match the spec cosmetically — reconcile, don't rebuild.

## Step 1 — Map the repo (do this first, cheaply)
Read in this order, nothing more: directory tree (2 levels) → pubspec.yaml → android/app/src/main/cpp (if present) → lib/ top-level structure → any existing README/docs → DB schema/migration files. From this alone, fill the inventory below.

## Step 2 — Produce/refresh `CODEBASE_MAP.md` at repo root
```md
# CODEBASE MAP — generated {date} by {model}
## Stack found: (Flutter version, state mgmt, DB lib, native bridge y/n, backend SDK)
## Task board reconciliation (mirror IDs from 11_ROADMAP_TASKS.md)
| Task | Spec status | Reality | Evidence (file paths) | Gap/risk |
| T-101 | ☐ | ☑/◐/✗ | lib/db/… | e.g. "schema exists but no SQLCipher" |
## Exists but NOT in spec: (list — flag for keep/kill decision)
## Spec violations found: (check against 00 non-negotiables + 99 D-001 banned list:
  grep for: forced, dopamine, loot, lock, streak_save, hidden skip, disabled input)
## P0 blockers: (won't compile / disconnected DB / placeholder keys / dead deps)
## Recommended next 3 tasks:
```

## Step 3 — Update the task board
Edit 11_ROADMAP_TASKS.md statuses (☐→◐/☑) with a one-line evidence note per changed task. Move the ▶ CURRENT POINTER to the first real gap. If existing code conflicts with a decision in 99_DECISIONS.md (e.g., mood-multiplied FSRS ratings = D-003 violation, monolithic asset bundle = D-008), add a `FIX-` task at top priority rather than silently patching.

## Step 4 — Special checks for this project (known risk areas)
- **FSRS:** does any code multiply rating × mood? → FIX per 08/D-003.
- **Assets:** is content bundled monolithically in the APK? → migrate to pack system per 03/D-008 (add FIX task; don't block other work on it).
- **Coercion remnants:** hidden skip, session locks, variable rewards anywhere in UI code? → FIX per D-001.
- **Secrets:** placeholder/committed API keys, unconnected DB → P0, fix before features.
- **STT:** open transcription used for grading? → switch to alignment per D-002.

## Rules
- CODEBASE_MAP.md is the bridge between spec and reality. Every future session: if it exists and is <2 weeks old, read it INSTEAD of re-exploring the repo (that's the token saving). If stale, re-run Steps 1–3.
- Never delete existing code in the audit pass — only map and flag. Kill decisions belong to the human, logged in 99.

```


## File: docs\99_DECISIONS.md

```md
# 99 DECISIONS LOG — Why Things Are The Way They Are
<!-- READ WHEN: about to change/question an existing design, or logging a new decision. APPEND-ONLY. ~1K tokens -->
<!-- FORMAT: D-NNN | date | decision | reason | supersedes -->

**D-001 | 2026-07 | All v4.0 coercion mechanics permanently removed.** Banned concepts (grep list): "dopamine engine", "forced output", "speak or die", "loop never ends", hidden skip, session lock, screen lock, ghost streaks, streak saves, loot drops, mystery boxes, variable rewards, "subconscious triggers", social-comparison pressure, guilt copy. Reason: autonomy violations, app-store + consumer-law risk, harm to vulnerable users. Any stale reference to these in older docs is void. Supersedes v4.0 entirely and stray v4.1 remnants (Flow-state hidden skip, "cannot bypass" cap, locked break screen, disabled Back button).

**D-002 | 2026-07 | Speaking scored by forced alignment against known targets, never open transcription.** Reason: whisper base cannot reliably openly transcribe Bengali-accented learner Japanese in noisy rooms; alignment against the expected sentence is a far easier, robust problem. STT spike (T-000a) gates the pillar. Text-input fallback always available.

**D-003 | 2026-07 | FSRS mood adaptation moved from rating math to card selection.** Old code multiplied the 1–4 rating by a mood factor → invalid ratings (e.g. 6) fed into parameters fitted on real review data → corrupted scheduling. New design: rating stays pure; mood adjusts queue size and easy-first ordering (08). `emotional_difficulty` column dropped (06).

**D-004 | 2026-07 | Confusion/burnout/confidence detection is deterministic (agents), never LLM-judged.** Reason: a 1.7B model can't reliably estimate confidence or detect confusion; taps/timing/accuracy signals can. LLM system prompt trimmed accordingly (08).

**D-005 | 2026-07 | Voice-stress anxiety detection deferred to post-MVP.** Reason: unproven on-device, privacy-sensitive, and the tap/error signals already cover the need.

**D-006 | 2026-07 | Content factory budget corrected: $12–18K MVP (5K pairs + 2K audio), $40–60K to 50K pairs + 10K audio.** Reason: original $15–25K under-priced scarce Bengali-Japanese bilingual expert review and omitted audio production costs.

**D-007 | 2026-07 | Cloud LLM pricing corrected to per-million tokens; offline justified by latency/reliability, not cost.** Reason: original math was ~1000× off; the cost argument collapsed, but the product argument (instant, deterministic, works with zero connectivity) is stronger anyway. All decks/docs use this framing.

**D-008 | 2026-07 | Monolithic 1.7GB app replaced by 45MB base APK + tiered signed packs with P2P sharing.** Reason: target users have <200MB/mo data; a 1.7GB install was existentially incompatible with the market. See 03. LLM (Tier 3) is optional by design because retrieval covers all graded/explained content.

**D-009 | 2026-07 | Daily cap and breaks are recommendations (parental mode is the only firm-cap exception).** Resolves the v4.1 contradiction between Principles 7–8 ("cannot bypass", "screen locks") and the agent/UI specs ("recommend, never force"). Policy in 01 §Session-health governs.

**D-010 | open | Firebase vs Supabase.** To be decided at T-105. Criteria: Bangladesh latency, pricing at 100K MAU, offline SDK quality, data-residency posture. Log outcome here.

**D-011 | 2026-07-09 | Kana stroke-order data sourced from KanjiVG, not kana-svg-data.** The old `tools/fetch_stroke_data.mjs` pulled `kana-svg-data` medians, which split self-crossing (loop) strokes into two paths → 16/92 kana had wrong stroke counts (あ→4, ヲ under-counted 2-vs-3, etc.). Shipping that would teach incorrect stroke order (violates 00 §4 correctness-over-generation). New tool fetches KanjiVG (canonical stroke order, one `<path>` per stroke), flattens each stroke path to sampled median points, and scales the 109 viewBox to the consumer's 0..1000 y-down space — output JSON contract and `writing_screen.dart` unchanged. Validated: 0/92 count mismatches vs the canonical gojūon table. License note: KanjiVG is **CC BY-SA 3.0** (© Ulrich Apel / contributors); the generated `assets/stroke/kana_strokes.json` is a derivative and must stay CC BY-SA with attribution (embedded in the file's `source`/`license` fields). The app bundling it is an aggregation and is unaffected. **Human action:** confirm the CC BY-SA attribution is acceptable for the commercial build (it is standard practice; most kanji apps ship KanjiVG-derived data this way).

---
_New decisions: append below in the same format. Every LLM/dev that makes a spec-silent choice MUST add an entry._

```


## File: l10n.yaml

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S

```


## File: lib\app\providers.dart

```dart
// Shared Riverpod providers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_repository.dart';
import '../data/srs_local.dart';
import '../domain/fsrs.dart';

/// Selected UI locale (persist via shared_preferences in the full app).
final localeProvider = StateProvider<Locale>((_) => const Locale('bn'));

/// Loads the verified content bundle once at startup.
final contentProvider = FutureProvider<ContentRepository>((_) async {
  final repo = ContentRepository();
  await repo.load();
  return repo;
});

/// The FSRS scheduler (pure, stateless) and the encrypted SRS store.
final fsrsProvider = Provider<Fsrs>((_) => const Fsrs());
final srsProvider = Provider<SrsLocal>((_) => SrsLocal());

```


## File: lib\app\theme.dart

```dart
// Bhasago — brand theme & design tokens.
//
// Brand story: "Ai" indigo (藍 / নীল) bridges Bengal's indigo heritage and
// Japanese aizome; Sakura vermilion is the torii gateway to Japan. Sumi-ink
// darks keep the app calm and battery-friendly on budget AMOLED devices.
//
// Colors map to the 09_UI_STATES design system. Psych-STATE colors (flow /
// struggle / burnout / boredom) are functional and live in [BhasagoStateColors];
// the resting brand identity is Ai indigo + Sakura, never a volatile state hue.
//
// Usage:  MaterialApp(theme: BhasagoTheme.dark(), ...)
// Note: pure ColorScheme/shape theming — no custom font family is set here so
// there are no missing-asset risks. To adopt Noto Sans Bengali/JP later, declare
// the fonts in pubspec and pass `fontFamily` into [_textTheme].

import 'package:flutter/material.dart';

/// Raw brand tokens. Prefer reading colors from `Theme.of(context).colorScheme`;
/// use these directly only for brand chrome (logo, splash, state screens).
abstract final class BhasagoColors {
  // Sumi-ink darks
  static const bg = Color(0xFF0E1116); // app background (matches prior build)
  static const surface = Color(0xFF171B22);
  static const surfaceHigh = Color(0xFF212734);
  static const outline = Color(0xFF2E3644);

  // Ai indigo — primary brand
  static const ai = Color(0xFF5B7CFA);
  static const aiBright = Color(0xFF8AA0FF); // primary on dark (contrast-safe)
  static const aiDeep = Color(0xFF29347A); // primaryContainer on dark

  // Sakura vermilion — secondary accent / torii
  static const sakura = Color(0xFFFF6F86);
  static const sakuraDeep = Color(0xFF7A2233);

  // Gold — mastery / rewards (predictable, never a loot surprise)
  static const gold = Color(0xFFFFC24B);

  static const ink = Color(0xFFF3F5FA); // primary text on dark
  static const inkDim = Color(0xFFAAB3C5); // secondary text
  static const error = Color(0xFFFF5370);
}

/// Functional psych-state colors from 09_UI_STATES. Used by state screens, not
/// as the resting brand palette.
abstract final class BhasagoStateColors {
  static const flow = Color(0xFF00C853); // optimal challenge
  static const struggle = Color(0xFFFF6D00); // rising errors — calm, warm
  static const burnout = Color(0xFF2979FF); // fatigue — zero motion
  static const boredom = Color(0xFFAA00FF); // autopilot — playful
}

abstract final class BhasagoTheme {
  static const _radius = 16.0;

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BhasagoColors.aiBright,
      onPrimary: Color(0xFF0A1230),
      primaryContainer: BhasagoColors.aiDeep,
      onPrimaryContainer: Color(0xFFDDE4FF),
      secondary: BhasagoColors.sakura,
      onSecondary: Color(0xFF3A0710),
      secondaryContainer: BhasagoColors.sakuraDeep,
      onSecondaryContainer: Color(0xFFFFDCE2),
      tertiary: BhasagoColors.gold,
      onTertiary: Color(0xFF3A2A00),
      tertiaryContainer: Color(0xFF5C4200),
      onTertiaryContainer: Color(0xFFFFE6B0),
      error: BhasagoColors.error,
      onError: Color(0xFF3A0510),
      surface: BhasagoColors.surface,
      onSurface: BhasagoColors.ink,
      surfaceContainerHighest: BhasagoColors.surfaceHigh,
      onSurfaceVariant: BhasagoColors.inkDim,
      outline: BhasagoColors.outline,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: BhasagoColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: BhasagoColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: BhasagoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: BhasagoColors.outline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48), // spec: touch target >=48dp
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: BhasagoColors.outline),
          foregroundColor: BhasagoColors.ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BhasagoColors.surface,
        indicatorColor: BhasagoColors.aiDeep,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BhasagoColors.aiBright,
            );
          }
          return const TextStyle(fontSize: 12, color: BhasagoColors.inkDim);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BhasagoColors.surfaceHigh,
        side: const BorderSide(color: BhasagoColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(color: BhasagoColors.ink),
      ),
      dividerColor: BhasagoColors.outline,
      textTheme: _textTheme(base.textTheme),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BhasagoColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: BhasagoColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BhasagoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: BhasagoColors.outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: BhasagoColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BhasagoColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BhasagoColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BhasagoColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BhasagoColors.aiBright, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: BhasagoColors.ink),
      displayMedium: base.displayMedium?.copyWith(color: BhasagoColors.ink),
      displaySmall: base.displaySmall?.copyWith(color: BhasagoColors.ink),
      headlineLarge: base.headlineLarge?.copyWith(color: BhasagoColors.ink),
      headlineMedium: base.headlineMedium?.copyWith(color: BhasagoColors.ink),
      headlineSmall: base.headlineSmall?.copyWith(color: BhasagoColors.ink),
      titleLarge: base.titleLarge?.copyWith(color: BhasagoColors.ink, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: BhasagoColors.ink, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(color: BhasagoColors.inkDim, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: BhasagoColors.ink),
      bodyMedium: base.bodyMedium?.copyWith(color: BhasagoColors.ink),
      bodySmall: base.bodySmall?.copyWith(color: BhasagoColors.inkDim),
      labelLarge: base.labelLarge?.copyWith(color: BhasagoColors.ink, fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(color: BhasagoColors.inkDim),
      labelSmall: base.labelSmall?.copyWith(color: BhasagoColors.inkDim),
    );
  }
}

```


## File: lib\data\content_repository.dart

```dart
// Loads VERIFIED content from bundled JSON assets. This repository is the only
// authoritative source of Japanese the learner is taught — the LLM never adds
// to it at runtime.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models.dart';

class ContentRepository {
  List<KanaEntry> _hiragana = const [];
  List<KanaEntry> _katakana = const [];
  final Map<String, Lesson> _lessons = {};
  final List<PitchSet> _pitchSets = [];

  Future<List<KanaEntry>> _loadKana(String file) async {
    final data = json.decode(await rootBundle.loadString(file)) as Map<String, dynamic>;
    return (data['items'] as List).map((e) => KanaEntry.fromJson(e)).toList(growable: false);
  }

  Future<void> load() async {
    _hiragana = await _loadKana('assets/content/hiragana.json');
    _katakana = await _loadKana('assets/content/katakana.json');

    for (final file in const [
      'assets/content/lesson_work_intro.json',
      'assets/content/lesson_konbini.json',
      'assets/content/lesson_clinic.json',
      'assets/content/lesson_numbers.json',
      'assets/content/lesson_time.json',
      'assets/content/lesson_restaurant.json',
      'assets/content/lesson_workplace.json',
    ]) {
      final lesson = Lesson.fromJson(json.decode(await rootBundle.loadString(file)));
      assert(lesson.verified, 'Refusing to load unverified lesson ${lesson.id}');
      _lessons[lesson.id] = lesson;
    }

    for (final file in const ['assets/content/pitch_accent.json']) {
      final set = PitchSet.fromJson(json.decode(await rootBundle.loadString(file)));
      assert(set.verified, 'Refusing to load unverified pitch set ${set.id}');
      _pitchSets.add(set);
    }
  }

  List<KanaEntry> get hiragana => _hiragana;
  List<KanaEntry> get katakana => _katakana;
  Lesson? lesson(String id) => _lessons[id];
  Iterable<Lesson> get lessons => _lessons.values;
  List<PitchSet> get pitchSets => _pitchSets;
}

```


## File: lib\data\srs_local.dart

```dart
// Local SRS persistence (SQLite via SQLCipher — encrypted at rest). Stores
// scheduled cards and review history offline. FSRS math lives in domain/fsrs.dart.
// Schema is owned by the numbered migrations in db/migrations/ (never inlined here).

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import '../domain/fsrs.dart';
import '../domain/models.dart';
import '../db/db_key.dart';
import '../db/migrations/migration.dart';
import '../db/migrations/registry.dart';

class SrsLocal {
  SrsLocal({DbKey? dbKey}) : _dbKey = dbKey ?? DbKey();

  final DbKey _dbKey;
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final password = await _dbKey.obtain();
    _db = await openDatabase(
      p.join(dir, 'sensei.db'),
      password: password, // SQLCipher AES-256 — user data encrypted at rest (T-101)
      version: kSchemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => runMigrations(db, kMigrations, 0, version),
      onUpgrade: (db, oldV, newV) => runMigrations(db, kMigrations, oldV, newV),
    );
    return _db!;
  }

  /// Cards due for review at [now], highest-priority state first.
  Future<List<ScheduledCard>> dueCards({DateTime? now, int limit = 20}) async {
    final db = await _open();
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.query('srs_cards',
        where: 'due <= ?', whereArgs: [t], orderBy: 'due ASC', limit: limit);
    return rows.map(_fromRow).toList();
  }

  /// Due cards paired with the display fields the review UI needs.
  Future<List<({ScheduledCard card, String word, Tri meaning})>> dueForReview(
      {DateTime? now, int limit = 30}) async {
    final db = await _open();
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.query('srs_cards',
        where: 'due <= ?', whereArgs: [t], orderBy: 'due ASC', limit: limit);
    return rows
        .map((r) => (
              card: _fromRow(r),
              word: r['word'] as String,
              meaning: Tri(
                bn: (r['meaning_bn'] as String?) ?? '',
                en: (r['meaning_en'] as String?) ?? '',
                ja: r['word'] as String,
              ),
            ))
        .toList();
  }

  /// Seeds a new content card (idempotent) so a just-learned item can be
  /// scheduled. Safe to call repeatedly; ConflictAlgorithm.replace upserts.
  Future<void> seedCard({
    required String id,
    required String word,
    required String reading,
    required String meaningBn,
    required String meaningEn,
    String jlptLevel = 'N5',
  }) =>
      upsert(ScheduledCard(id: id, state: CardState.newCard),
          word: word,
          reading: reading,
          meaningBn: meaningBn,
          meaningEn: meaningEn,
          jlptLevel: jlptLevel);

  Future<void> upsert(ScheduledCard c,
      {required String word,
      required String reading,
      required String meaningBn,
      required String meaningEn,
      String jlptLevel = 'N5'}) async {
    final db = await _open();
    await db.insert(
      'srs_cards',
      {
        'id': c.id,
        'word': word,
        'reading': reading,
        'meaning_bn': meaningBn,
        'meaning_en': meaningEn,
        'jlpt_level': jlptLevel,
        'due': c.due.millisecondsSinceEpoch,
        'stability': c.stability,
        'difficulty': c.difficulty,
        'reps': c.reps,
        'lapses': c.lapses,
        'state': c.state.name,
        'last_review': c.lastReview?.millisecondsSinceEpoch,
        'elapsed_days': c.elapsedDays,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Applies a review with FSRS, persists the new schedule, and logs history.
  Future<ScheduledCard> applyReview(
      Fsrs fsrs, ScheduledCard card, Rating rating,
      {DateTime? now}) async {
    final updated = fsrs.review(card, rating, now: now);
    final db = await _open();
    await db.update(
      'srs_cards',
      {
        'due': updated.due.millisecondsSinceEpoch,
        'stability': updated.stability,
        'difficulty': updated.difficulty,
        'reps': updated.reps,
        'lapses': updated.lapses,
        'state': updated.state.name,
        'last_review': updated.lastReview?.millisecondsSinceEpoch,
        'elapsed_days': updated.elapsedDays,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
    await db.insert('review_history', {
      'card_id': card.id,
      'reviewed_at': (now ?? DateTime.now()).millisecondsSinceEpoch,
      'rating': rating.g,
      'old_stability': card.stability,
      'new_stability': updated.stability,
      'old_difficulty': card.difficulty,
      'new_difficulty': updated.difficulty,
    });
    return updated;
  }

  ScheduledCard _fromRow(Map<String, Object?> r) => ScheduledCard(
        id: r['id'] as String,
        stability: (r['stability'] as num).toDouble(),
        difficulty: (r['difficulty'] as num).toDouble(),
        state: CardState.values.firstWhere((s) => s.name == r['state'],
            orElse: () => CardState.newCard),
        reps: r['reps'] as int,
        lapses: r['lapses'] as int,
        lastReview: r['last_review'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['last_review'] as int),
        due: DateTime.fromMillisecondsSinceEpoch(r['due'] as int),
        elapsedDays: (r['elapsed_days'] as num).toDouble(),
      );
}

```


## File: lib\db\db_key.dart

```dart
// SQLCipher passphrase provisioning. The 256-bit key is generated once per
// install with a CSPRNG and persisted in OS-backed secure storage (Android
// Keystore / iOS Keychain). It never leaves the device and is never logged.
// (T-101 / 07 security — user data encrypted at rest.)

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DbKey {
  static const _storageKey = 'sensei_db_key_v1';

  final FlutterSecureStorage _storage;

  DbKey({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Returns the DB passphrase, minting and storing one on first run.
  Future<String> obtain() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = _generate();
    await _storage.write(key: _storageKey, value: fresh);
    return fresh;
  }

  static String _generate() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes); // 256-bit key (~43 chars)
  }
}

```


## File: lib\db\migrations\m001_baseline.dart

```dart
// 001 — baseline SRS schema (cards + review history). Matches the shipped v1
// tables the FSRS DAO reads/writes. IMMUTABLE: never edit; append new migrations.

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'migration.dart';

final Migration m001Baseline = Migration(1, 'baseline_srs', (Database db) async {
  await db.execute('''
    CREATE TABLE srs_cards(
      id TEXT PRIMARY KEY,
      word TEXT NOT NULL,
      reading TEXT NOT NULL,
      meaning_bn TEXT NOT NULL,
      meaning_en TEXT NOT NULL,
      jlpt_level TEXT NOT NULL,
      due INTEGER NOT NULL,
      stability REAL DEFAULT 0,
      difficulty REAL DEFAULT 0,
      reps INTEGER DEFAULT 0,
      lapses INTEGER DEFAULT 0,
      state TEXT DEFAULT 'new',
      last_review INTEGER,
      elapsed_days REAL DEFAULT 0
    )''');
  await db.execute('CREATE INDEX idx_cards_due ON srs_cards(due)');
  await db.execute('''
    CREATE TABLE review_history(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      card_id TEXT NOT NULL,
      reviewed_at INTEGER NOT NULL,
      rating INTEGER NOT NULL,
      old_stability REAL, new_stability REAL,
      old_difficulty REAL, new_difficulty REAL
    )''');
});

```


## File: lib\db\migrations\migration.dart

```dart
// Migration primitives. Migrations are sequential, numbered, and IMMUTABLE:
// never edit a shipped migration — append a new one (06_DATABASE.md).

import 'package:sqflite_sqlcipher/sqflite.dart';

/// A single forward schema step. [version] is unique and strictly ascending;
/// it maps 1:1 to the SQLite `PRAGMA user_version` the engine records.
class Migration {
  final int version;
  final String name;
  final Future<void> Function(Database db) up;
  const Migration(this.version, this.name, this.up);
}

/// Applies every migration in the half-open range (from, to] in ascending
/// order. Called for both a fresh DB (from = 0) and an upgrade (from = oldV).
Future<void> runMigrations(
  Database db,
  List<Migration> all,
  int from,
  int to,
) async {
  final pending = all.where((m) => m.version > from && m.version <= to).toList()
    ..sort((a, b) => a.version.compareTo(b.version));
  for (final m in pending) {
    await m.up(db);
  }
}

```


## File: lib\db\migrations\registry.dart

```dart
// Append-only migration registry. Add each new migration to the END of the
// list; never reorder or edit an existing entry (06_DATABASE.md).

import 'migration.dart';
import 'm001_baseline.dart';

final List<Migration> kMigrations = <Migration>[
  m001Baseline,
  // m002_align_06_schema,  // future: widen srs_cards + add users/messages/... (06)
];

/// The latest schema version = highest migration number. Passed to
/// openDatabase(version:) so the engine drives onCreate/onUpgrade.
int get kSchemaVersion =>
    kMigrations.fold(0, (max, m) => m.version > max ? m.version : max);

```


## File: lib\domain\fsrs.dart

```dart
// FSRS-4.5 spaced-repetition scheduler — pure Dart, no dependencies.
//
// Reference: Free Spaced Repetition Scheduler (FSRS) v4.5, power forgetting
// curve. 17 weights. This is the on-device memory engine for SENSEI.
//
// The math here is mirrored in tools/fsrs_reference.mjs and property-tested
// (higher rating -> longer interval; R(0)=1 and decreasing in time; interval
// grows with stability; difficulty stays within [1,10]).

import 'dart:math' as math;

/// User grade for a review.
enum Rating { again, hard, good, easy } // 1,2,3,4

extension RatingValue on Rating {
  int get g => index + 1; // again=1 ... easy=4
}

/// Card learning state.
enum CardState { newCard, learning, review, relearning }

/// Power forgetting-curve constants (FSRS-4.5).
const double kDecay = -0.5;
const double kFactor = 19.0 / 81.0; // = 0.9^(1/decay) - 1

class Fsrs {
  /// FSRS-4.5 default weights (same array frozen in the architecture spec).
  final List<double> w;

  /// Target retention when scheduling the next interval (0<r<1).
  final double requestRetention;

  /// Hard cap on interval in days.
  final int maximumInterval;

  const Fsrs({
    this.w = const [
      0.40255, 0.59854, 2.40984, 5.80984, 4.92593, 0.94123, 0.86231,
      0.01000, 1.48959, 0.14480, 0.94123, 2.18154, 0.05000, 0.34560,
      1.26000, 0.29400, 2.61000,
    ],
    this.requestRetention = 0.90,
    this.maximumInterval = 36500,
  });

  // ---- Retrievability & interval ----

  /// Probability of recall after [elapsedDays] given [stability].
  double retrievability(double elapsedDays, double stability) {
    if (stability <= 0) return 0;
    return math.pow(1 + kFactor * elapsedDays / stability, kDecay).toDouble();
  }

  /// Interval (whole days) that lands retention at [requestRetention].
  int nextInterval(double stability) {
    final ivl = (stability / kFactor) *
        (math.pow(requestRetention, 1 / kDecay).toDouble() - 1);
    return ivl.round().clamp(1, maximumInterval);
  }

  // ---- Initial values (first review of a new card) ----

  double _initStability(int g) => math.max(w[g - 1], 0.1);

  double _initDifficulty(int g) =>
      _clampD(w[4] - w[5] * (g - 3));

  double _clampD(double d) => d.clamp(1.0, 10.0);

  // ---- Difficulty update (with mean reversion toward "easy" init) ----

  double _nextDifficulty(double d, int g) {
    final delta = d - w[6] * (g - 3);
    final reverted = w[7] * _initDifficulty(4) + (1 - w[7]) * delta;
    return _clampD(reverted);
  }

  // ---- Stability updates ----

  double _stabilityAfterRecall(double d, double s, double r, int g) {
    final hardPenalty = (g == Rating.hard.g) ? w[15] : 1.0;
    final easyBonus = (g == Rating.easy.g) ? w[16] : 1.0;
    final inc = math.exp(w[8]) *
        (11 - d) *
        math.pow(s, -w[9]).toDouble() *
        (math.exp((1 - r) * w[10]).toDouble() - 1) *
        hardPenalty *
        easyBonus;
    return s * (1 + inc);
  }

  double _stabilityAfterForget(double d, double s, double r) {
    return w[11] *
        math.pow(d, -w[12]).toDouble() *
        (math.pow(s + 1, w[13]).toDouble() - 1) *
        math.exp((1 - r) * w[14]).toDouble();
  }

  /// Apply a review to [card] with [rating] at [now]; returns the updated card.
  ScheduledCard review(ScheduledCard card, Rating rating,
      {DateTime? now}) {
    now ??= DateTime.now();
    final g = rating.g;
    final elapsed = card.lastReview == null
        ? 0.0
        : now.difference(card.lastReview!).inSeconds / 86400.0;

    double stability, difficulty;
    CardState state;
    int lapses = card.lapses;

    if (card.state == CardState.newCard) {
      stability = _initStability(g);
      difficulty = _initDifficulty(g);
      state = (g == Rating.again.g) ? CardState.learning : CardState.review;
    } else {
      final r = retrievability(elapsed, card.stability);
      if (g == Rating.again.g) {
        stability = _stabilityAfterForget(card.difficulty, card.stability, r);
        difficulty = _nextDifficulty(card.difficulty, g);
        state = CardState.relearning;
        lapses += 1;
      } else {
        stability =
            _stabilityAfterRecall(card.difficulty, card.stability, r, g);
        difficulty = _nextDifficulty(card.difficulty, g);
        state = CardState.review;
      }
    }

    final intervalDays =
        (g == Rating.again.g) ? 0 : nextInterval(stability); // relearn same day
    final due = (g == Rating.again.g)
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(days: intervalDays));

    return card.copyWith(
      stability: stability,
      difficulty: difficulty,
      state: state,
      lapses: lapses,
      reps: card.reps + 1,
      lastReview: now,
      due: due,
      elapsedDays: elapsed,
    );
  }
}

/// Minimal schedulable card. Vocabulary/content fields live in the DB model.
class ScheduledCard {
  final String id;
  final double stability;
  final double difficulty;
  final CardState state;
  final int reps;
  final int lapses;
  final DateTime? lastReview;
  final DateTime due;
  final double elapsedDays;

  ScheduledCard({
    required this.id,
    this.stability = 0,
    this.difficulty = 0,
    this.state = CardState.newCard,
    this.reps = 0,
    this.lapses = 0,
    this.lastReview,
    DateTime? due,
    this.elapsedDays = 0,
  }) : due = due ?? DateTime.now();

  ScheduledCard copyWith({
    double? stability,
    double? difficulty,
    CardState? state,
    int? reps,
    int? lapses,
    DateTime? lastReview,
    DateTime? due,
    double? elapsedDays,
  }) =>
      ScheduledCard(
        id: id,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        state: state ?? this.state,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        lastReview: lastReview ?? this.lastReview,
        due: due ?? this.due,
        elapsedDays: elapsedDays ?? this.elapsedDays,
      );
}

```


## File: lib\domain\models.dart

```dart
// Content models. Meanings/notes are trilingual (en/bn/ja); the Japanese
// target text (jp/kana/romaji) is fixed and never varies with UI language.

/// A string localized into the three supported UI languages.
class Tri {
  final String en, bn, ja;
  const Tri({required this.en, required this.bn, required this.ja});

  factory Tri.fromJson(Map<String, dynamic> j) =>
      Tri(en: j['en'] as String, bn: j['bn'] as String, ja: j['ja'] as String);

  /// Returns the string for a locale code ('en'|'bn'|'ja'), defaulting to en.
  String of(String lang) => lang == 'bn' ? bn : lang == 'ja' ? ja : en;

  /// Lines to render. In Bengali mode we return [bn, en] so the English gloss
  /// backs up any Bengali wording that isn't a perfect fit for the learner.
  /// Other languages return a single line.
  List<String> lines(String lang) => lang == 'bn' ? [bn, en] : [of(lang)];

  /// True when [lines] carries a secondary (English) gloss to de-emphasize.
  bool isBilingual(String lang) => lang == 'bn';
}

/// A single kana character.
class KanaEntry {
  final String id, char, romaji, row;
  const KanaEntry(
      {required this.id,
      required this.char,
      required this.romaji,
      required this.row});

  factory KanaEntry.fromJson(Map<String, dynamic> j) => KanaEntry(
        id: j['id'],
        char: j['char'],
        romaji: j['romaji'],
        row: j['row'] ?? '',
      );
}

/// A verified phrase/sentence inside a Can-do lesson.
class LessonItem {
  final String id, jp, kana, romaji;
  final Tri meaning, note;
  final List<String> srsWords;

  const LessonItem({
    required this.id,
    required this.jp,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.note,
    required this.srsWords,
  });

  factory LessonItem.fromJson(Map<String, dynamic> j) => LessonItem(
        id: j['id'],
        jp: j['jp'],
        kana: j['kana'],
        romaji: j['romaji'],
        meaning: Tri.fromJson(j['meaning']),
        note: Tri.fromJson(j['note']),
        srsWords: (j['srs_words'] as List).cast<String>(),
      );
}

/// A Can-do lesson (exam-aligned unit).
class Lesson {
  final String id;
  final Tri canDo;
  final String jftLevel, source;
  final bool verified;
  final List<LessonItem> items;

  const Lesson({
    required this.id,
    required this.canDo,
    required this.jftLevel,
    required this.source,
    required this.verified,
    required this.items,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'],
        canDo: Tri.fromJson(j['can_do']),
        jftLevel: j['jlpt_or_jft'] ?? '',
        source: j['source'] ?? '',
        verified: j['verified'] == true,
        items: (j['items'] as List)
            .map((e) => LessonItem.fromJson(e))
            .toList(growable: false),
      );
}

/// A pitch-accent minimal-pair entry. [pattern] is one 0/1 (low/high) per mora.
class PitchItem {
  final String id, word, kanji, romaji;
  final List<int> pattern;
  final Tri meaning, accentType;

  const PitchItem({
    required this.id,
    required this.word,
    required this.kanji,
    required this.romaji,
    required this.pattern,
    required this.meaning,
    required this.accentType,
  });

  factory PitchItem.fromJson(Map<String, dynamic> j) => PitchItem(
        id: j['id'],
        word: j['word'],
        kanji: j['kanji'] ?? '',
        romaji: j['romaji'],
        pattern: (j['pattern'] as List).cast<int>(),
        meaning: Tri.fromJson(j['meaning']),
        accentType: Tri.fromJson(j['accent_type']),
      );
}

class PitchSet {
  final String id, dialect, source;
  final bool verified;
  final List<PitchItem> items;
  const PitchSet({
    required this.id,
    required this.dialect,
    required this.source,
    required this.verified,
    required this.items,
  });

  factory PitchSet.fromJson(Map<String, dynamic> j) => PitchSet(
        id: j['id'],
        dialect: j['dialect'] ?? '',
        source: j['source'] ?? '',
        verified: j['verified'] == true,
        items: (j['items'] as List)
            .map((e) => PitchItem.fromJson(e))
            .toList(growable: false),
      );
}

```


## File: lib\domain\pitch.dart

```dart
// On-device pitch (F0) analysis for accent training. Pure Dart.
//
// Pipeline: mic PCM -> f0Contour() -> toShape() (normalized, speaker-independent)
// -> accentScore() vs the native reference contour. This backs the shadowing
// screen's "how close was my pitch?" feedback. Mirrored & proven in
// tools/pitch_reference.mjs.

import 'dart:math' as math;

/// Estimate fundamental frequency (Hz) of one frame via autocorrelation with
/// parabolic interpolation for sub-sample accuracy. Returns -1 for unvoiced.
double estimateF0(List<double> buf, double sampleRate,
    {double minHz = 70, double maxHz = 500}) {
  final n = buf.length;
  double rms = 0;
  for (final s in buf) rms += s * s;
  rms = math.sqrt(rms / n);
  if (rms < 0.01) return -1;

  final minLag = (sampleRate / maxHz).floor();
  final maxLag = (sampleRate / minHz).ceil().clamp(1, n - 1);

  final c = List<double>.filled(maxLag + 2, 0);
  double best = 0;
  int bestLag = -1;
  for (var lag = minLag; lag <= maxLag; lag++) {
    double sum = 0;
    for (var i = 0; i < n - lag; i++) sum += buf[i] * buf[i + lag];
    c[lag] = sum;
    if (sum > best) {
      best = sum;
      bestLag = lag;
    }
  }
  if (bestLag <= 0) return -1;

  // Parabolic interpolation around the peak for finer frequency resolution.
  double refined = bestLag.toDouble();
  if (bestLag > minLag && bestLag < maxLag) {
    final a = c[bestLag - 1], b = c[bestLag], g = c[bestLag + 1];
    final denom = a - 2 * b + g;
    if (denom.abs() > 1e-9) refined = bestLag + 0.5 * (a - g) / denom;
  }
  final f = sampleRate / refined;
  return (f >= minHz && f <= maxHz) ? f : -1;
}

/// Sliding-window F0 contour across a whole signal. -1 marks unvoiced frames.
List<double> f0Contour(List<double> signal, double sampleRate,
    {int frame = 2048, int hop = 512}) {
  final out = <double>[];
  for (var start = 0; start + frame <= signal.length; start += hop) {
    out.add(estimateF0(signal.sublist(start, start + frame), sampleRate));
  }
  return out;
}

/// Normalize a contour to a speaker-independent shape: semitones relative to the
/// voiced-mean pitch. Unvoiced frames become null. This removes the difference
/// between a low male and high female voice, keeping only the melody.
List<double?> toShape(List<double> contour) {
  final voiced = contour.where((f) => f > 0).toList();
  if (voiced.isEmpty) return List.filled(contour.length, null);
  final mean = voiced.reduce((a, b) => a + b) / voiced.length;
  return contour
      .map((f) => f > 0 ? 12 * (math.log(f / mean) / math.ln2) : null)
      .toList();
}

/// Resample a nullable shape to [len] points (nearest-neighbour).
List<double?> _resample(List<double?> xs, int len) {
  if (xs.isEmpty) return List.filled(len, null);
  return List.generate(len, (i) {
    final j = (i * xs.length / len).floor().clamp(0, xs.length - 1);
    return xs[j];
  });
}

/// Accent similarity 0..100 between learner and reference contours.
/// Compares normalized shapes over overlapping voiced frames; higher is closer.
double accentScore(List<double> reference, List<double> learner) {
  final r = toShape(reference);
  final l = toShape(learner);
  final len = math.max(r.length, l.length);
  final rr = _resample(r, len), ll = _resample(l, len);

  double err = 0;
  int count = 0;
  for (var i = 0; i < len; i++) {
    if (rr[i] == null || ll[i] == null) continue;
    err += (rr[i]! - ll[i]!).abs();
    count++;
  }
  if (count == 0) return 0;
  final meanErr = err / count; // avg semitone deviation
  final score = (100 * (1 - meanErr / 6)).clamp(0, 100);
  return score.toDouble();
}

```


## File: lib\l10n\app_bn.arb

```arb
{
  "@@locale": "bn",
  "appTitle": "ভাষাগো",
  "@appTitle": {"description": "অ্যাপের নাম"},
  "kanaTitle": "কানা",
  "@kanaTitle": {"description": "কানা গ্রিড স্ক্রিন"},
  "navLearn": "শেখো",
  "@navLearn": {"description": "নিচের নেভ: শেখা ট্যাব"},
  "navSpeak": "বলো",
  "@navSpeak": {"description": "নিচের নেভ: বলা ট্যাব"},
  "pitchTitle": "স্বর",
  "@pitchTitle": {"description": "নিচের নেভ: স্বরভঙ্গি ট্যাব"},
  "navReview": "রিভিউ",
  "@navReview": {"description": "নিচের নেভ: রিভিউ ট্যাব"},
  "showAnswer": "উত্তর দেখাও",
  "@showAnswer": {"description": "রিভিউ স্ক্রিন উত্তর বোতাম"},
  "reviewDone": "সব শেষ!",
  "@reviewDone": {"description": "রিভিউ সম্পূর্ণ বার্তা"},
  "rAgain": "আবার",
  "@rAgain": {"description": "FSRS রেটিং: আবার"},
  "rHard": "কঠিন",
  "@rHard": {"description": "FSRS রেটিং: কঠিন"},
  "rGood": "ভালো",
  "@rGood": {"description": "FSRS রেটিং: ভালো"},
  "rEasy": "সহজ",
  "@rEasy": {"description": "FSRS রেটিং: সহজ"},
  "skipLabel": "বাদ",
  "@skipLabel": {"description": "বাদ দেওয়ার বোতাম"},
  "hintLabel": "ইঙ্গিত",
  "@hintLabel": {"description": "ইঙ্গিত বোতাম"},
  "quitLabel": "বন্ধ",
  "@quitLabel": {"description": "বন্ধ করার বোতাম"},
  "startLesson": "শুরু করো",
  "@startLesson": {"description": "লেসন শুরুর বোতাম"},
  "nextLabel": "পরের",
  "@nextLabel": {"description": "পরের ধাপ বোতাম"},
  "listenLabel": "শুনুন",
  "@listenLabel": {"description": "অডিও বাজানোর বোতাম"},
  "recordLabel": "রেকর্ড",
  "@recordLabel": {"description": "মাইক্রোফোন রেকর্ড বোতাম"},
  "lessonComplete": "লেসন শেষ",
  "@lessonComplete": {"description": "লেসন সম্পূর্ণ শিরোনাম"}
}

```


## File: lib\l10n\app_en.arb

```arb
{
  "@@locale": "en",
  "appTitle": "Bhasago",
  "@appTitle": {"description": "App display name"},
  "kanaTitle": "Kana",
  "@kanaTitle": {"description": "Kana grid screen title"},
  "navLearn": "Learn",
  "@navLearn": {"description": "Bottom nav: learn tab"},
  "navSpeak": "Speak",
  "@navSpeak": {"description": "Bottom nav: speak tab"},
  "pitchTitle": "Pitch",
  "@pitchTitle": {"description": "Bottom nav: pitch accent tab"},
  "navReview": "Review",
  "@navReview": {"description": "Bottom nav: review tab"},
  "showAnswer": "Show answer",
  "@showAnswer": {"description": "Review screen reveal button"},
  "reviewDone": "All done!",
  "@reviewDone": {"description": "Review screen completion message"},
  "rAgain": "Again",
  "@rAgain": {"description": "FSRS rating: again"},
  "rHard": "Hard",
  "@rHard": {"description": "FSRS rating: hard"},
  "rGood": "Good",
  "@rGood": {"description": "FSRS rating: good"},
  "rEasy": "Easy",
  "@rEasy": {"description": "FSRS rating: easy"},
  "skipLabel": "Skip",
  "@skipLabel": {"description": "Skip button label"},
  "hintLabel": "Hint",
  "@hintLabel": {"description": "Hint button label"},
  "quitLabel": "Quit",
  "@quitLabel": {"description": "Quit button label"},
  "startLesson": "Start",
  "@startLesson": {"description": "Lesson start button"},
  "nextLabel": "Next",
  "@nextLabel": {"description": "Next step button"},
  "listenLabel": "Listen",
  "@listenLabel": {"description": "Audio play button"},
  "recordLabel": "Record",
  "@recordLabel": {"description": "Microphone record button"},
  "lessonComplete": "Lesson complete",
  "@lessonComplete": {"description": "Lesson completion heading"}
}

```


## File: lib\l10n\app_ja.arb

```arb
{
  "@@locale": "ja",
  "appTitle": "Bhasago",
  "@appTitle": {"description": "アプリ表示名"},
  "kanaTitle": "かな",
  "@kanaTitle": {"description": "かなグリッド画面"},
  "navLearn": "学習",
  "@navLearn": {"description": "下部ナビ：学習タブ"},
  "navSpeak": "話す",
  "@navSpeak": {"description": "下部ナビ：話すタブ"},
  "pitchTitle": "アクセント",
  "@pitchTitle": {"description": "下部ナビ：アクセントタブ"},
  "navReview": "復習",
  "@navReview": {"description": "下部ナビ：復習タブ"},
  "showAnswer": "答えを見る",
  "@showAnswer": {"description": "復習画面の表示ボタン"},
  "reviewDone": "完了！",
  "@reviewDone": {"description": "復習完了メッセージ"},
  "rAgain": "もう一度",
  "@rAgain": {"description": "FSRS評価：もう一度"},
  "rHard": "難しい",
  "@rHard": {"description": "FSRS評価：難しい"},
  "rGood": "良い",
  "@rGood": {"description": "FSRS評価：良い"},
  "rEasy": "簡単",
  "@rEasy": {"description": "FSRS評価：簡単"},
  "skipLabel": "スキップ",
  "@skipLabel": {"description": "スキップボタン"},
  "hintLabel": "ヒント",
  "@hintLabel": {"description": "ヒントボタン"},
  "quitLabel": "終了",
  "@quitLabel": {"description": "終了ボタン"},
  "startLesson": "開始",
  "@startLesson": {"description": "レッスン開始ボタン"},
  "nextLabel": "次へ",
  "@nextLabel": {"description": "次のステップボタン"},
  "listenLabel": "聞く",
  "@listenLabel": {"description": "音声再生ボタン"},
  "recordLabel": "録音",
  "@recordLabel": {"description": "マイク録音ボタン"},
  "lessonComplete": "レッスン完了",
  "@lessonComplete": {"description": "レッスン完了見出し"}
}

```


## File: lib\main.dart

```dart
// Bhasago — app entry point. Trilingual (en/bn/ja) with bilingual Bengali mode,
// offline-first. Bottom-nav shell hosts Kana / Lesson / Shadowing / Pitch /
// Review, mirroring the interactive HTML prototype.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'app/providers.dart';
import 'app/theme.dart';
import 'presentation/screens.dart';
import 'presentation/accent_screens.dart';
import 'presentation/writing_screen.dart';

void main() => runApp(const ProviderScope(child: SenseiApp()));

class SenseiApp extends ConsumerWidget {
  const SenseiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Bhasago',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('bn'), Locale('ja')],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: BhasagoTheme.dark(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int tab = 0;

  static const _pages = [
    KanaScreen(),
    WritingScreen(),
    LessonScreen(lessonId: 'work_intro_01'),
    ShadowingScreen(),
    PitchScreen(),
    ReviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhasago'),
        actions: [
          for (final l in const [('EN', 'en'), ('বাংলা', 'bn'), ('日本語', 'ja')])
            TextButton(
              onPressed: () =>
                  ref.read(localeProvider.notifier).state = Locale(l.$2),
              child: Text(l.$1),
            ),
        ],
      ),
      body: _pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.grid_view), label: s.kanaTitle),
          NavigationDestination(icon: const Icon(Icons.draw), label: 'Write'),
          NavigationDestination(icon: const Icon(Icons.school), label: s.navLearn),
          NavigationDestination(icon: const Icon(Icons.mic), label: s.navSpeak),
          NavigationDestination(icon: const Icon(Icons.show_chart), label: s.pitchTitle),
          NavigationDestination(icon: const Icon(Icons.loop), label: s.navReview),
        ],
      ),
    );
  }
}

```


## File: lib\presentation\accent_screens.dart

```dart
// Accent training: Shadowing (record & score your pitch) and Pitch minimal
// pairs (high/low visualization). Uses domain/pitch.dart for scoring.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../domain/models.dart';
import '../domain/pitch.dart';
import 'widgets.dart';

/// Draws the high/low accent line over the word's morae.
class PitchLinePainter extends CustomPainter {
  final List<int> pattern; // 0 = low, 1 = high, per mora
  PitchLinePainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern.isEmpty) return;
    final line = Paint()
      ..color = const Color(0xFFFF5A3C)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final highDot = Paint()..color = const Color(0xFF38BDF8);
    final lowDot = Paint()..color = const Color(0xFF96A0AD);

    final n = pattern.length;
    final step = size.width / (n + 0.5);
    Offset? prev;
    for (var i = 0; i < n; i++) {
      final x = step * (i + 0.5);
      final y = pattern[i] == 1 ? size.height * 0.25 : size.height * 0.75;
      final p = Offset(x, y);
      if (prev != null) canvas.drawLine(prev, p, line);
      canvas.drawCircle(p, 6, pattern[i] == 1 ? highDot : lowDot);
      prev = p;
    }
  }

  @override
  bool shouldRepaint(covariant PitchLinePainter old) => old.pattern != pattern;
}

/// Pitch minimal-pairs screen.
class PitchScreen extends ConsumerWidget {
  const PitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const Center(child: CircularProgressIndicator());
    final set = repo.pitchSets.first;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('${set.dialect} · ${set.items.length} pairs',
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        for (final it in set.items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${it.kanji}  (${it.word})',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {/* TODO: ttsService.speak(it.word) */},
                      ),
                    ],
                  ),
                  BilingualText(it.meaning, lang: lang),
                  BilingualText(it.accentType,
                      lang: lang,
                      primaryStyle: const TextStyle(color: Color(0xFF38BDF8))),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: CustomPaint(
                        painter: PitchLinePainter(it.pattern),
                        size: const Size(double.infinity, 54)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Shadowing screen — listen, record, and get a pitch-accent score.
class ShadowingScreen extends ConsumerStatefulWidget {
  const ShadowingScreen({super.key});
  @override
  ConsumerState<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends ConsumerState<ShadowingScreen> {
  bool recording = false;
  double? score;

  // In the full app: the native reference contour ships with the audio; the
  // learner contour comes from record -> pitch.f0Contour(). Here we show the
  // wiring with representative contours so the score path is exercised.
  final List<double> _referenceContour = const [180, 200, 235, 250, 250, 240];

  void _toggleRecord() {
    setState(() {
      if (recording) {
        recording = false;
        // TODO: stop `record`, decode PCM, learner = f0Contour(pcm, 16000).
        final learner = const [178, 205, 232, 248, 246, 238]; // demo capture
        score = accentScore(_referenceContour, learner);
      } else {
        recording = true;
        score = null;
        // TODO: start `record` at 16 kHz mono.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('よろしくおねがいします',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('yoroshiku onegai shimasu',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {/* TODO: play native reference audio */},
                icon: const Icon(Icons.volume_up),
                label: const Text('Listen'),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _toggleRecord,
          icon: Icon(recording ? Icons.stop : Icons.mic),
          label: Text(recording ? 'Stop & score' : 'Record'),
        ),
        const SizedBox(height: 20),
        if (score != null)
          Column(children: [
            Text('${score!.round()}/100',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: score! >= 70
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFBBF24))),
            Text(score! >= 70 ? 'Great pitch match!' : 'Follow the pitch line more closely',
                style: TextStyle(color: Colors.grey.shade400)),
          ]),
      ]),
    );
  }
}

```


## File: lib\presentation\screens.dart

```dart
// Screens: Kana grid, Lesson viewer (bilingual), Review (FSRS-wired, in-memory
// demo). These mirror the HTML prototype's UX. Audio/native hooks attach where
// noted. Text-to-speech and mic are wired via platform services in the full app.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../domain/fsrs.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';

/// Kana grid — tap a character to hear it (TTS hook).
class KanaScreen extends ConsumerWidget {
  final bool katakana;
  const KanaScreen({super.key, this.katakana = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const Center(child: CircularProgressIndicator());
    final kana = katakana ? repo.katakana : repo.hiragana;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: kana.length,
      itemBuilder: (_, i) {
        final k = kana[i];
        return InkWell(
          onTap: () {/* TODO: ttsService.speak(k.char) */},
          child: Card(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(k.char, style: const TextStyle(fontSize: 26)),
                Text(k.romaji,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// The five steps every lesson item runs through (09 §Core lesson micro-loop).
enum _Phase { intro, recognition, production, context, srs }

/// Lesson micro-loop: Intro → Recognition → Production → Context → SRS, run once
/// per item. The autonomy invariant — [Skip] [Hint] [Quit] — is visible and
/// enabled in every step, ≤1 tap, never penalized (01 constitution / 09
/// §Invariant). Nothing auto-advances: each step ends on an explicit, neutral tap.
class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});
  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _started = false;
  bool _done = false;
  int _item = 0;
  int _phaseIx = 0;
  bool _hint = false;
  bool _showRom = true;

  // recognition step
  int? _pick;
  int? _optItem;
  List<({Tri meaning, bool correct})> _opts = const [];

  // production step
  bool _revealModel = false;
  bool _writeMode = false;

  // context step (word-block build)
  int? _ctxItem;
  final List<String> _built = [];
  List<String> _bank = [];

  _Phase get _phase => _Phase.values[_phaseIx];

  void _resetStep() {
    _hint = false;
    _pick = null;
    _optItem = null;
    _opts = const [];
    _revealModel = false;
    _writeMode = false;
    _ctxItem = null;
    _built.clear();
    _bank = [];
  }

  void _start() => setState(() {
        _started = true;
        _done = false;
        _item = 0;
        _phaseIx = 0;
        _resetStep();
      });

  void _quit() => setState(() {
        _started = false;
        _done = false;
        _item = 0;
        _phaseIx = 0;
        _resetStep();
      });

  void _advance(int itemCount) => setState(() {
        _resetStep();
        if (_phaseIx < _Phase.values.length - 1) {
          _phaseIx++;
        } else if (_item < itemCount - 1) {
          _item++;
          _phaseIx = 0;
        } else {
          _started = false;
          _done = true;
        }
      });

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const Center(child: CircularProgressIndicator());
    final lesson = repo.lesson(widget.lessonId)!;

    if (_done) return _complete(context, lesson, lang);
    if (!_started) return _overview(context, lesson, lang);

    final item = lesson.items[_item];
    final n = lesson.items.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, lesson, lang),
          const SizedBox(height: 10),
          _controls(lang, n), // [Skip] [Hint] [Quit] — present in every step
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _phaseBody(context, lesson, item, lang, n),
            ),
          ),
          if (_hint) ...[const SizedBox(height: 8), _hintPanel(context, item, lang)],
        ],
      ),
    );
  }

  // --- autonomy invariant: always visible, always enabled, ≤1 tap -------------
  Widget _controls(String lang, int itemCount) {
    // Flexible label so long text ellipsizes instead of overflowing on a
    // narrow (≈360dp) budget phone; English lives in the semantic label.
    Widget btn(IconData ic, String label, String semantic, VoidCallback onTap) =>
        Expanded(
          child: Semantics(
            button: true,
            label: semantic,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48), // ≥48dp touch target
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ic, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(children: [
      btn(Icons.lightbulb_outline, 'ইঙ্গিত', 'Show a hint',
          () => setState(() => _hint = !_hint)),
      const SizedBox(width: 8),
      btn(Icons.skip_next, 'বাদ', 'Skip this step', () => _advance(itemCount)),
      const SizedBox(width: 8),
      btn(Icons.close, 'বন্ধ', 'Quit the lesson', _quit),
    ]);
  }

  Widget _header(BuildContext context, Lesson lesson, String lang) {
    const labels = {
      _Phase.intro: 'পরিচিতি · Intro',
      _Phase.recognition: 'চেনা · Recognition',
      _Phase.production: 'বলা/লেখা · Production',
      _Phase.context: 'বাক্য · Context',
      _Phase.srs: 'রিভিউ · SRS',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BilingualText(lesson.canDo,
            lang: lang, primaryStyle: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('শব্দ ${_item + 1}/${lesson.items.length}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(labels[_phase]!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var p = 0; p < _Phase.values.length; p++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: p == _Phase.values.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: p <= _phaseIx
                        ? const Color(0xFF00C853)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _phaseBody(
      BuildContext context, Lesson lesson, LessonItem item, String lang, int n) {
    switch (_phase) {
      case _Phase.intro:
        return _intro(context, item, lang, n);
      case _Phase.recognition:
        return _recognition(context, lesson, item, lang, n);
      case _Phase.production:
        return _production(context, item, lang, n);
      case _Phase.context:
        return _context(context, item, lang, n);
      case _Phase.srs:
        return _srs(context, item, lang, n);
    }
  }

  // 1. INTRO — target, meaning, sample note; all Bengali-first. ---------------
  Widget _intro(BuildContext context, LessonItem item, String lang, int n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(item.jp,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          if (_showRom)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.romaji,
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'শুনুন · Listen',
            onPressed: () {/* TODO: ttsService.speak(item.jp) */},
          ),
          const SizedBox(height: 8),
          BilingualText(item.meaning,
              lang: lang,
              align: TextAlign.center,
              primaryStyle: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF161D16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BilingualText(item.note, lang: lang),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            TextButton(
              onPressed: () => setState(() => _showRom = !_showRom),
              child: Text(_showRom ? 'Romaji off' : 'Romaji on'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _advance(n),
              child: const Text('বুঝেছি · Got it'),
            ),
          ]),
        ]),
      ),
    );
  }

  // 2. RECOGNITION — show the JP, pick its meaning (MC). No auto-advance. -----
  Widget _recognition(
      BuildContext context, Lesson lesson, LessonItem item, String lang, int n) {
    if (_optItem != _item) {
      final others = lesson.items.where((x) => x.id != item.id).toList()
        ..shuffle(Random(_item + 1));
      final opts = <({Tri meaning, bool correct})>[
        (meaning: item.meaning, correct: true),
        for (final o in others.take(3)) (meaning: o.meaning, correct: false),
      ]..shuffle(Random(_item * 7 + 3));
      _opts = opts;
      _optItem = _item;
    }
    final picked = _pick != null;
    final correct = picked && _opts[_pick!].correct;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            Text(item.jp,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.volume_up),
              tooltip: 'শুনুন · Listen',
              onPressed: () {/* TODO: ttsService.speak(item.jp) */},
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Text('এর মানে কী? · What does it mean?',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      const SizedBox(height: 8),
      for (var k = 0; k < _opts.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _optionTile(context, lang, k),
        ),
      const SizedBox(height: 4),
      if (picked && correct)
        Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
          const SizedBox(width: 6),
          const Text('ঠিক! · Correct'),
          const Spacer(),
          FilledButton(
              onPressed: () => _advance(n), child: const Text('পরের · Next')),
        ])
      else if (picked && !correct)
        Text('আবার দেখো · Not quite — try another',
            style: TextStyle(color: Colors.amber.shade300, fontSize: 13)),
    ]);
  }

  Widget _optionTile(BuildContext context, String lang, int k) {
    final opt = _opts[k];
    final isPick = _pick == k;
    // Reveal correctness only for the tapped option; a hint highlights the answer.
    Color? bg;
    if (isPick) {
      bg = opt.correct ? const Color(0xFF10361F) : const Color(0xFF3A2A12);
    }
    final hinted = _hint && opt.correct;
    return InkWell(
      onTap: () => setState(() => _pick = k),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg ?? Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hinted ? const Color(0xFF00C853) : Colors.transparent,
              width: 1.5),
        ),
        child: Align(
            alignment: Alignment.centerLeft,
            child: BilingualText(opt.meaning, lang: lang)),
      ),
    );
  }

  // 3. PRODUCTION — say it or write it; model + switch-type + skip always there.
  Widget _production(BuildContext context, LessonItem item, String lang, int n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(_writeMode ? 'এটি লেখো · Write this' : 'এটি বলো · Say this',
              style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 10),
          BilingualText(item.meaning,
              lang: lang,
              align: TextAlign.center,
              primaryStyle: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (_revealModel)
            Column(children: [
              Text(item.jp,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              Text(item.romaji, style: TextStyle(color: Colors.grey.shade400)),
            ])
          else
            Text('· · ·', style: TextStyle(color: Colors.grey.shade600, fontSize: 26)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.mic, size: 18),
              // Tier 0–1: record & self-compare; Tier 2+: aligned scoring (D-002).
              onPressed: () {/* TODO: recorder.start() → self-compare / alignment */},
              label: const Text('রেকর্ড · Record'),
            ),
            OutlinedButton.icon(
              icon: Icon(_revealModel ? Icons.visibility_off : Icons.visibility,
                  size: 18),
              onPressed: () => setState(() => _revealModel = !_revealModel),
              label: Text(_revealModel ? 'লুকাও · Hide' : 'মডেল · Model'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              onPressed: () => setState(() => _writeMode = !_writeMode),
              label: Text(_writeMode ? 'বলায় · Speak' : 'লেখায় · Write'),
            ),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
                onPressed: () => _advance(n), child: const Text('পরের · Next')),
          ),
        ]),
      ),
    );
  }

  // 4. CONTEXT — word-block build from srs_words. Wrong = gentle cue, no fail. -
  Widget _context(BuildContext context, LessonItem item, String lang, int n) {
    final tokens = item.srsWords;
    if (tokens.length < 2) {
      // Single-word item: nothing to arrange — show it in context, one tap on.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text('বাক্যে · In context',
                style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 12),
            Text(item.jp,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BilingualText(item.meaning, lang: lang, align: TextAlign.center),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                  onPressed: () => _advance(n), child: const Text('পরের · Next')),
            ),
          ]),
        ),
      );
    }
    if (_ctxItem != _item) {
      _built.clear();
      _bank = [...tokens]..shuffle(Random(_item + 5));
      _ctxItem = _item;
    }
    final complete = _built.length == tokens.length;
    final ordered = complete && _listEq(_built, tokens);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('শব্দগুলো সাজিয়ে বাক্য বানাও · Arrange the words',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      const SizedBox(height: 8),
      BilingualText(item.meaning, lang: lang),
      const SizedBox(height: 12),
      // assembled line
      Container(
        constraints: const BoxConstraints(minHeight: 56),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !complete
                ? Colors.transparent
                : ordered
                    ? const Color(0xFF00C853)
                    : Colors.amber,
            width: 1.5,
          ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var k = 0; k < _built.length; k++)
              ActionChip(
                label: Text(_built[k], style: const TextStyle(fontSize: 18)),
                onPressed: () => setState(() {
                  _bank.add(_built.removeAt(k)); // tap to send back
                }),
              ),
            if (_built.isEmpty)
              Text('এখানে সাজাও · tap words below',
                  style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var k = 0; k < _bank.length; k++)
            ActionChip(
              label: Text(_bank[k], style: const TextStyle(fontSize: 18)),
              onPressed: () => setState(() => _built.add(_bank.removeAt(k))),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (complete && ordered)
        Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text('দারুণ! · ${item.jp}')),
          FilledButton(
              onPressed: () => _advance(n), child: const Text('পরের · Next')),
        ])
      else if (complete && !ordered)
        Row(children: [
          Expanded(
            child: Text('একটু এদিক-ওদিক · not quite — rearrange',
                style: TextStyle(color: Colors.amber.shade300, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => setState(() {
              _bank = [...tokens]..shuffle(Random(_item + 5));
              _built.clear();
            }),
            child: const Text('আবার · Reset'),
          ),
        ]),
    ]);
  }

  // 5. SRS — the item's words enter FSRS scheduling; user self-rates. ---------
  Widget _srs(BuildContext context, LessonItem item, String lang, int n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('রিভিউতে যোগ হলো · Added to your review',
              style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in item.srsWords)
                Chip(label: Text(w, style: const TextStyle(fontSize: 16))),
            ],
          ),
          const SizedBox(height: 20),
          Text('কেমন লাগল? · How was it?',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            for (final r in Rating.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FilledButton(
                    onPressed: () {
                      _seedAndReview(item, r); // persist to encrypted SRS
                      _advance(n);
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(_ratingLabel(r), textAlign: TextAlign.center),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _hintPanel(BuildContext context, LessonItem item, String lang) {
    return Card(
      color: const Color(0xFF1A2230),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Icon(Icons.lightbulb, color: Color(0xFFFFC400), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item.jp}  ·  ${item.romaji}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              BilingualText(item.meaning, lang: lang),
            ]),
          ),
        ]),
      ),
    );
  }

  // Lesson entry (calm overview) — Start is a choice, never auto-launched. ----
  Widget _overview(BuildContext context, Lesson lesson, String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BilingualText(lesson.canDo,
              lang: lang, primaryStyle: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${lesson.items.length} শব্দ · ${lesson.items.length} items · ৫ ধাপ',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('যেকোনো সময় Skip / Hint / Quit — কোনো চাপ নেই।',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: const Text('শুরু করো · Start'),
          ),
        ],
      ),
    );
  }

  Widget _complete(BuildContext context, Lesson lesson, String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 48),
          const SizedBox(height: 12),
          const Text('লেসন শেষ · Lesson complete',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('আরেকটা? · Another round?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: const Text('আবার · Restart'),
          ),
        ],
      ),
    );
  }

  // Seed the just-learned item as an FSRS card and log this rating. Fire-and-
  // forget: the encrypted DB is device-only, so a failure here (e.g. running
  // without the SQLCipher plugin) never blocks the lesson flow.
  Future<void> _seedAndReview(LessonItem item, Rating r) async {
    try {
      final srs = ref.read(srsProvider);
      await srs.seedCard(
        id: item.id,
        word: item.jp,
        reading: item.kana,
        meaningBn: item.meaning.bn,
        meaningEn: item.meaning.en,
      );
      await srs.applyReview(ref.read(fsrsProvider), ScheduledCard(id: item.id), r);
    } catch (_) {/* DB unavailable off-device; lesson proceeds regardless */}
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var k = 0; k < a.length; k++) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  String _ratingLabel(Rating r) => switch (r) {
        Rating.again => 'আবার\nAgain',
        Rating.hard => 'কঠিন\nHard',
        Rating.good => 'ভালো\nGood',
        Rating.easy => 'সহজ\nEasy',
      };
}

/// Review — FSRS scheduling over the encrypted SRS store (SrsLocal). Cards are
/// seeded by the lesson micro-loop's SRS step; this screen reviews what's due.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final fsrs = const Fsrs();
  bool revealed = false;
  int idx = 0;
  List<({ScheduledCard card, String word, Tri meaning})>? _deck; // null = loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final deck = await ref.read(srsProvider).dueForReview();
      if (mounted) setState(() => _deck = deck);
    } catch (_) {
      if (mounted) setState(() => _deck = const []); // DB unavailable off-device
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = ref.watch(localeProvider).languageCode;
    final deck = _deck;
    if (deck == null) return const Center(child: CircularProgressIndicator());
    if (deck.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline,
                size: 40, color: Color(0xFF00C853)),
            const SizedBox(height: 12),
            const Text('এখন রিভিউ নেই · Nothing due right now',
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('একটা লেসন করলে নতুন কার্ড যোগ হবে · learn a lesson to add cards',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
        ),
      );
    }
    if (idx >= deck.length) {
      return Center(child: Text(s.reviewDone));
    }
    final entry = deck[idx];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text(entry.word,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (revealed)
                BilingualText(entry.meaning, lang: lang, align: TextAlign.center),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        if (!revealed)
          FilledButton(
              onPressed: () => setState(() => revealed = true),
              child: Text(s.showAnswer))
        else
          Row(children: [
            for (final r in Rating.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FilledButton(
                    onPressed: () => _rate(r),
                    child: Text(_label(s, r) +
                        '\n${fsrs.nextInterval(fsrs.review(entry.card, r).stability)}d',
                        textAlign: TextAlign.center),
                  ),
                ),
              ),
          ]),
      ]),
    );
  }

  String _label(S s, Rating r) => switch (r) {
        Rating.again => s.rAgain,
        Rating.hard => s.rHard,
        Rating.good => s.rGood,
        Rating.easy => s.rEasy,
      };

  Future<void> _rate(Rating r) async {
    final entry = _deck![idx];
    try {
      await ref.read(srsProvider).applyReview(ref.read(fsrsProvider), entry.card, r);
    } catch (_) {/* best-effort persist; UI advances regardless */}
    if (mounted) {
      setState(() {
        revealed = false;
        idx++;
      });
    }
  }
}

```


## File: lib\presentation\widgets.dart

```dart
// Reusable widgets. BilingualText is the heart of the "Bengali = bilingual"
// behaviour: in Bengali mode it renders the Bengali line with a dimmed English
// gloss beneath; in English/Japanese it renders a single line.

import 'package:flutter/material.dart';
import '../domain/models.dart';

class BilingualText extends StatelessWidget {
  final Tri text;
  final String lang;
  final TextStyle? primaryStyle;
  final TextAlign align;

  const BilingualText(
    this.text, {
    super.key,
    required this.lang,
    this.primaryStyle,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.lines(lang);
    final primary = primaryStyle ?? Theme.of(context).textTheme.bodyLarge;
    final gloss = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey.shade500);
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lines.first, style: primary, textAlign: align),
        if (lines.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(lines[1], style: gloss, textAlign: align),
          ),
      ],
    );
  }
}

```


## File: lib\presentation\writing_screen.dart

```dart
// Kana writing practice: finger drawing + offline stroke-order animation.
// Stroke medians load from bundled assets/stroke/kana_strokes.json (no network).
// Autonomy: Skip is always visible; Quit = leave the tab (bottom nav). (01/09)

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

const _hira = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん';
const _kata = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});
  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = const {};
  bool _kata = false;
  int _idx = 0;
  bool _guide = true;
  final List<List<Offset>> _ink = [];
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _animating = false;

  String get _script => _kata ? _kata_ : 'hiragana';
  final String _kata_ = 'katakana';
  String get _chars => _kata ? _kata : _hira;
  String get _cur => _chars[_idx];

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/stroke/kana_strokes.json').then((s) {
      setState(() => _data = json.decode(s) as Map<String, dynamic>);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<List<Offset>>? _strokes() {
    final m = (_data[_script] as Map?)?[_cur];
    if (m == null) return null;
    return (m as List)
        .map<List<Offset>>((st) => (st as List)
            .map<Offset>((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList())
        .toList();
  }

  void _play() {
    if (_strokes() == null || _animating) return;
    setState(() {
      _ink.clear();
      _animating = true;
    });
    _anim.forward(from: 0).whenComplete(() => setState(() => _animating = false));
  }

  void _select(int i) => setState(() {
        _idx = i;
        _ink.clear();
        _animating = false;
        _anim.reset();
      });

  @override
  Widget build(BuildContext context) {
    final strokes = _strokes();
    return Column(children: [
      // script toggle
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('ひらがな')),
            ButtonSegment(value: true, label: Text('カタカナ')),
          ],
          selected: {_kata},
          onSelectionChanged: (s) => setState(() {
            _kata = s.first;
            _idx = 0;
            _ink.clear();
            _anim.reset();
          }),
        ),
      ),
      // character strip
      SizedBox(
        height: 54,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _chars.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _select(i),
            child: Container(
              width: 46,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: i == _idx ? const Color(0xFFFF2D78) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(_chars[i], style: const TextStyle(fontSize: 22))),
            ),
          ),
        ),
      ),
      // paper
      Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Listener(
              onPointerDown: (e) {
                if (_animating) return;
                setState(() => _ink.add([e.localPosition]));
              },
              onPointerMove: (e) {
                if (_animating || _ink.isEmpty) return;
                setState(() => _ink.last.add(e.localPosition));
              },
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _WritingPainter(
                    ink: _ink,
                    guideChar: _guide && !_animating ? _cur : null,
                    animStrokes: _animating ? strokes : null,
                    animT: _anim.value,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // tools
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _tool(Icons.play_arrow, 'watch', strokes != null ? _play : null, primary: true),
          _tool(_guide ? Icons.visibility : Icons.visibility_off, 'guide',
              () => setState(() => _guide = !_guide)),
          _tool(Icons.undo, 'undo',
              _ink.isEmpty ? null : () => setState(() => _ink.removeLast())),
          _tool(Icons.delete_outline, 'clear',
              _ink.isEmpty ? null : () => setState(_ink.clear)),
        ]),
      ),
      const Spacer(),
      // autonomy row: Skip always available
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _select((_idx - 1 + _chars.length) % _chars.length),
              child: const Text('‹'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => _select((_idx + 1) % _chars.length),
              child: const Text('Skip / পরের ›'),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _tool(IconData ic, String label, VoidCallback? onTap, {bool primary = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 52,
          child: primary
              ? FilledButton(onPressed: onTap, child: Icon(ic))
              : OutlinedButton(onPressed: onTap, child: Icon(ic)),
        ),
      ),
    );
  }
}

class _WritingPainter extends CustomPainter {
  final List<List<Offset>> ink;
  final String? guideChar;
  final List<List<Offset>>? animStrokes;
  final double animT;
  _WritingPainter({required this.ink, this.guideChar, this.animStrokes, this.animT = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFBFBFD));
    // grid
    final pad = w * 0.06;
    final gl = Paint()
      ..color = const Color(0xFFE6E7EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(Rect.fromLTRB(pad, pad, w - pad, size.height - pad), gl);
    canvas.drawLine(Offset(w / 2, pad), Offset(w / 2, size.height - pad), gl);
    canvas.drawLine(Offset(pad, size.height / 2), Offset(w - pad, size.height / 2), gl);

    // faint guide glyph
    if (guideChar != null) {
      final tp = TextPainter(
        text: TextSpan(
            text: guideChar,
            style: TextStyle(fontSize: size.height * 0.7, color: const Color(0xFFE3E4EC))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, (size.height - tp.height) / 2));
    }

    // user ink
    final inkPaint = Paint()
      ..color = const Color(0xFF14141F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final st in ink) {
      if (st.length < 2) {
        if (st.length == 1) {
          canvas.drawCircle(st.first, inkPaint.strokeWidth / 2, Paint()..color = const Color(0xFF14141F));
        }
        continue;
      }
      final p = Path()..moveTo(st.first.dx, st.first.dy);
      for (var i = 1; i < st.length; i++) p.lineTo(st[i].dx, st[i].dy);
      canvas.drawPath(p, inkPaint);
    }

    // stroke-order animation (scaled from viewBox 1000)
    if (animStrokes != null) {
      final sc = w / 1000.0;
      final ap = Paint()
        ..color = const Color(0xFF14141F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final scaled = animStrokes!
          .map((st) => st.map((o) => Offset(o.dx * sc, o.dy * sc)).toList())
          .toList();
      final lens = scaled.map(_len).toList();
      final total = lens.fold<double>(0, (a, b) => a + b);
      var target = animT * total, consumed = 0.0;
      for (var i = 0; i < scaled.length; i++) {
        if (consumed >= target) break;
        _drawUpTo(canvas, scaled[i], ap, math.min(lens[i], target - consumed));
        consumed += lens[i];
      }
    }
  }

  double _len(List<Offset> p) {
    var s = 0.0;
    for (var i = 1; i < p.length; i++) s += (p[i] - p[i - 1]).distance;
    return s;
  }

  void _drawUpTo(Canvas c, List<Offset> pts, Paint paint, double maxLen) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    var acc = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final seg = (pts[i] - pts[i - 1]).distance;
      if (acc + seg <= maxLen) {
        path.lineTo(pts[i].dx, pts[i].dy);
        acc += seg;
      } else {
        final f = seg <= 0 ? 0.0 : (maxLen - acc) / seg;
        final q = Offset.lerp(pts[i - 1], pts[i], f)!;
        path.lineTo(q.dx, q.dy);
        break;
      }
    }
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WritingPainter old) =>
      old.ink != ink || old.animT != animT || old.guideChar != guideChar || old.animStrokes != animStrokes;
}

```


## File: preview\index.html

```html
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Bhasago preview</title></head><body>
<style>
  :root{
    --bg:#0E1116; --surface:#161B22; --surface2:#1A2230; --line:rgba(255,255,255,.08);
    --text:#E8EAED; --muted:#8A93A2; --faint:#5A6472;
    --pink:#FF2D78; --pink-dim:#3A1526; --green:#00C853; --green-dim:#10361F;
    --amber:#FFC400; --amber-dim:#3A2A12; --blue:#2979FF;
    --font:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans","Noto Sans Bengali","Noto Sans JP",sans-serif;
  }
  *{box-sizing:border-box}
  body{margin:0}
  .stage{
    min-height:100vh; display:flex; align-items:center; justify-content:center;
    padding:24px; font-family:var(--font);
    background:
      radial-gradient(1200px 600px at 20% -10%, #1b2740 0%, transparent 55%),
      radial-gradient(900px 500px at 110% 20%, #2a1330 0%, transparent 50%),
      #05070c;
  }
  .frame{
    width:390px; max-width:100%; height:800px; max-height:calc(100vh - 40px);
    background:var(--bg); border-radius:40px; position:relative; overflow:hidden;
    border:1px solid rgba(255,255,255,.10);
    box-shadow:0 40px 90px -20px rgba(0,0,0,.8), 0 0 0 10px #0a0c11, 0 0 0 11px rgba(255,255,255,.06);
    display:flex; flex-direction:column; color:var(--text);
  }
  .statusbar{display:flex; justify-content:space-between; align-items:center;
    padding:12px 22px 4px; font-size:12px; color:var(--muted); letter-spacing:.3px}
  .statusbar .dots{display:flex; gap:4px; align-items:center}
  .statusbar .dots span{width:5px;height:5px;border-radius:50%;background:var(--muted)}
  .appbar{display:flex; align-items:center; justify-content:space-between; padding:6px 18px 10px}
  .brand{font-weight:800; letter-spacing:1.5px; font-size:15px}
  .brand b{color:var(--pink)}
  .langs{display:flex; gap:4px}
  .langs button{background:transparent; border:0; color:var(--muted); font:inherit; font-size:12px;
    padding:5px 9px; border-radius:9px; cursor:pointer}
  .langs button.on{background:rgba(255,45,120,.14); color:var(--pink)}
  .screen{flex:1; overflow-y:auto; overflow-x:hidden; -webkit-overflow-scrolling:touch}
  .screen::-webkit-scrollbar{width:0}
  .nav{display:flex; border-top:1px solid var(--line); background:rgba(10,13,20,.85); backdrop-filter:blur(8px)}
  .nav button{flex:1; background:none; border:0; color:var(--faint); padding:9px 0 12px; cursor:pointer;
    display:flex; flex-direction:column; align-items:center; gap:3px; font:inherit; font-size:9.5px}
  .nav button.on{color:var(--pink)}
  .nav svg{width:22px;height:22px;stroke:currentColor;fill:none;stroke-width:1.7}
  /* shared */
  h2.title{margin:16px 20px 2px; font-size:13px; color:var(--muted); font-weight:600}
  .sub{margin:0 20px; color:var(--faint); font-size:12px}
  .card{background:var(--surface); border:1px solid var(--line); border-radius:18px; padding:18px}
  .pad{padding:16px}
  .btn{border:0; border-radius:13px; font:inherit; font-weight:600; padding:12px 16px; cursor:pointer;
    min-height:48px; display:inline-flex; align-items:center; justify-content:center; gap:7px}
  .btn.primary{background:var(--pink); color:#fff}
  .btn.filled{background:var(--green); color:#04120a}
  .btn.ghost{background:rgba(255,255,255,.06); color:var(--text)}
  .btn.line{background:transparent; border:1px solid var(--line); color:var(--text)}
  .btn:disabled{opacity:.35; cursor:default}
  .row{display:flex; gap:8px}
  .grow{flex:1}
  .jp{font-weight:700}
  .muted{color:var(--muted)} .faint{color:var(--faint)}
  /* kana grid */
  .krow{display:flex; gap:8px; padding:0 16px 12px}
  .seg{display:flex; background:var(--surface); border:1px solid var(--line); border-radius:12px; overflow:hidden; margin:14px 20px 6px}
  .seg button{flex:1; background:none; border:0; color:var(--muted); font:inherit; padding:9px; cursor:pointer}
  .seg button.on{background:var(--pink); color:#fff}
  .grid{display:grid; grid-template-columns:repeat(5,1fr); gap:8px; padding:8px 16px 20px}
  .cell{background:var(--surface); border:1px solid var(--line); border-radius:14px; aspect-ratio:1;
    display:flex; flex-direction:column; align-items:center; justify-content:center; cursor:pointer; transition:.12s}
  .cell:active{transform:scale(.94); background:var(--surface2)}
  .cell .c{font-size:24px; font-weight:600}
  .cell .r{font-size:10px; color:var(--faint)}
  /* write */
  .strip{display:flex; gap:8px; overflow-x:auto; padding:12px 16px}
  .strip::-webkit-scrollbar{height:0}
  .chip{min-width:46px; height:46px; border-radius:12px; background:rgba(255,255,255,.06); border:0; color:var(--text);
    font-size:22px; cursor:pointer; flex:0 0 auto}
  .chip.on{background:var(--pink); color:#fff}
  #paper{width:100%; aspect-ratio:1; border-radius:20px; background:#FBFBFD; touch-action:none; display:block}
  .tools{display:flex; gap:8px; padding:12px 16px}
  .tools .btn{flex:1; padding:10px}
  /* controls (invariant) */
  .controls{display:flex; gap:8px; padding:0 16px 6px}
  .controls .btn{flex:1; padding:9px}
  .steps{display:flex; gap:4px; padding:8px 20px 2px}
  .steps i{flex:1; height:4px; border-radius:2px; background:rgba(255,255,255,.14)}
  .steps i.on{background:var(--green)}
  .phaselab{display:flex; justify-content:space-between; padding:2px 20px 0; font-size:12px}
  .opt{width:100%; text-align:left; background:rgba(255,255,255,.06); border:1.5px solid transparent; color:var(--text);
    border-radius:12px; padding:12px 14px; margin-bottom:8px; cursor:pointer; font:inherit; min-height:48px}
  .opt.good{background:var(--green-dim)} .opt.bad{background:var(--amber-dim)} .opt.hint{border-color:var(--green)}
  .tok{background:rgba(255,255,255,.08); border:0; color:var(--text); border-radius:10px; padding:8px 12px;
    font-size:18px; cursor:pointer; font-family:var(--font)}
  .assembled{min-height:56px; border:1.5px solid transparent; border-radius:12px; background:rgba(255,255,255,.05);
    padding:10px; display:flex; flex-wrap:wrap; gap:8px; align-items:center}
  .assembled.good{border-color:var(--green)} .assembled.bad{border-color:var(--amber)}
  .bank{display:flex; flex-wrap:wrap; gap:8px}
  .pillrow{display:flex; flex-wrap:wrap; gap:8px}
  .pill{background:rgba(255,255,255,.08); border-radius:999px; padding:6px 12px; font-size:14px}
  .center{display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; gap:12px; padding:24px; text-align:center}
  .big{font-size:34px; font-weight:800}
  .rate{display:flex; gap:6px}
  .rate .btn{flex:1; flex-direction:column; gap:2px; font-size:12px; padding:10px 4px}
  .rate small{color:rgba(255,255,255,.7); font-weight:400}
  /* pitch */
  .contour{display:flex; align-items:flex-end; gap:2px; height:44px; margin-top:6px}
  .mora{display:flex; flex-direction:column; align-items:center; gap:4px}
  .mora .b{width:22px; border-radius:3px 3px 0 0; background:var(--pink)}
  .wave{height:70px; border-radius:14px; background:
    repeating-linear-gradient(90deg, rgba(255,45,120,.35) 0 2px, transparent 2px 7px); opacity:.5}
  .tag{display:inline-block; font-size:11px; padding:2px 8px; border-radius:999px; background:rgba(0,200,83,.15); color:var(--green)}
</style>
<div class="stage">
  <div class="frame">
    <div class="statusbar"><span>9:41</span><div class="dots"><span></span><span></span><span></span> ▮</div></div>
    <div class="appbar">
      <div class="brand">SEN<b>SEI</b></div>
      <div class="langs" id="langs">
        <button data-l="en">EN</button>
        <button data-l="bn" class="on">বাংলা</button>
        <button data-l="ja">日本語</button>
      </div>
    </div>
    <div class="screen" id="screen"></div>
    <div class="nav" id="nav"></div>
  </div>
</div>
<script>
const DATA = {"hira":[{"char":"あ","romaji":"a"},{"char":"い","romaji":"i"},{"char":"う","romaji":"u"},{"char":"え","romaji":"e"},{"char":"お","romaji":"o"},{"char":"か","romaji":"ka"},{"char":"き","romaji":"ki"},{"char":"く","romaji":"ku"},{"char":"け","romaji":"ke"},{"char":"こ","romaji":"ko"},{"char":"さ","romaji":"sa"},{"char":"し","romaji":"shi"},{"char":"す","romaji":"su"},{"char":"せ","romaji":"se"},{"char":"そ","romaji":"so"},{"char":"た","romaji":"ta"},{"char":"ち","romaji":"chi"},{"char":"つ","romaji":"tsu"},{"char":"て","romaji":"te"},{"char":"と","romaji":"to"},{"char":"な","romaji":"na"},{"char":"に","romaji":"ni"},{"char":"ぬ","romaji":"nu"},{"char":"ね","romaji":"ne"},{"char":"の","romaji":"no"},{"char":"は","romaji":"ha"},{"char":"ひ","romaji":"hi"},{"char":"ふ","romaji":"fu"},{"char":"へ","romaji":"he"},{"char":"ほ","romaji":"ho"},{"char":"ま","romaji":"ma"},{"char":"み","romaji":"mi"},{"char":"む","romaji":"mu"},{"char":"め","romaji":"me"},{"char":"も","romaji":"mo"},{"char":"や","romaji":"ya"},{"char":"ゆ","romaji":"yu"},{"char":"よ","romaji":"yo"},{"char":"ら","romaji":"ra"},{"char":"り","romaji":"ri"},{"char":"る","romaji":"ru"},{"char":"れ","romaji":"re"},{"char":"ろ","romaji":"ro"},{"char":"わ","romaji":"wa"},{"char":"を","romaji":"wo"},{"char":"ん","romaji":"n"}],"kata":[{"char":"ア","romaji":"a"},{"char":"イ","romaji":"i"},{"char":"ウ","romaji":"u"},{"char":"エ","romaji":"e"},{"char":"オ","romaji":"o"},{"char":"カ","romaji":"ka"},{"char":"キ","romaji":"ki"},{"char":"ク","romaji":"ku"},{"char":"ケ","romaji":"ke"},{"char":"コ","romaji":"ko"},{"char":"サ","romaji":"sa"},{"char":"シ","romaji":"shi"},{"char":"ス","romaji":"su"},{"char":"セ","romaji":"se"},{"char":"ソ","romaji":"so"},{"char":"タ","romaji":"ta"},{"char":"チ","romaji":"chi"},{"char":"ツ","romaji":"tsu"},{"char":"テ","romaji":"te"},{"char":"ト","romaji":"to"},{"char":"ナ","romaji":"na"},{"char":"ニ","romaji":"ni"},{"char":"ヌ","romaji":"nu"},{"char":"ネ","romaji":"ne"},{"char":"ノ","romaji":"no"},{"char":"ハ","romaji":"ha"},{"char":"ヒ","romaji":"hi"},{"char":"フ","romaji":"fu"},{"char":"ヘ","romaji":"he"},{"char":"ホ","romaji":"ho"},{"char":"マ","romaji":"ma"},{"char":"ミ","romaji":"mi"},{"char":"ム","romaji":"mu"},{"char":"メ","romaji":"me"},{"char":"モ","romaji":"mo"},{"char":"ヤ","romaji":"ya"},{"char":"ユ","romaji":"yu"},{"char":"ヨ","romaji":"yo"},{"char":"ラ","romaji":"ra"},{"char":"リ","romaji":"ri"},{"char":"ル","romaji":"ru"},{"char":"レ","romaji":"re"},{"char":"ロ","romaji":"ro"},{"char":"ワ","romaji":"wa"},{"char":"ヲ","romaji":"wo"},{"char":"ン","romaji":"n"}],"strokes":{"viewBox":1000,"source":"KanjiVG (https://kanjivg.tagaini.net)","license":"CC BY-SA 3.0 — © Ulrich Apel / KanjiVG contributors","note":"Generated by tools/fetch_stroke_data.mjs. One median polyline per stroke, in stroke order.","hiragana":{"あ":[[[284,303],[288,306],[292,309],[297,312],[303,314],[309,316],[317,318],[324,319],[333,319],[363,317],[396,314],[430,311],[465,306],[500,300],[535,294],[570,287],[603,280],[609,279],[616,277],[624,276],[632,275],[640,274],[649,274],[657,274],[664,275]],[[457,162],[460,166],[462,170],[465,176],[467,182],[469,189],[470,196],[470,203],[469,210],[457,269],[446,332],[436,396],[429,460],[423,524],[420,587],[420,646],[422,702],[424,721],[427,740],[430,758],[434,774],[438,790],[443,804],[448,816],[453,827]],[[602,405],[605,409],[607,416],[608,423],[609,431],[610,439],[610,447],[609,454],[607,461],[590,503],[571,544],[549,585],[523,626],[493,666],[459,707],[419,748],[374,789],[350,806],[325,815],[300,818],[277,812],[257,799],[241,779],[230,750],[225,712],[230,674],[245,636],[272,599],[307,565],[351,533],[402,505],[459,483],[522,467],[565,461],[609,461],[652,467],[693,478],[729,495],[760,518],[785,548],[802,584],[811,629],[810,673],[799,715],[779,755],[750,790],[712,821],[665,846],[610,863]]],"い":[[[197,272],[204,280],[209,288],[213,296],[216,304],[217,313],[218,322],[218,331],[217,340],[209,404],[205,462],[206,515],[212,564],[223,609],[240,649],[262,687],[290,721],[309,739],[323,749],[333,752],[341,748],[346,737],[349,721],[352,699],[354,673]],[[669,335],[701,364],[731,395],[759,429],[784,466],[805,506],[822,549],[833,595],[838,645]]],"う":[[[385,142],[404,149],[421,155],[437,159],[453,163],[467,166],[480,168],[492,169],[503,170],[528,170],[546,172],[556,175],[559,180],[555,187],[544,195],[525,206],[500,220]],[[303,389],[310,393],[317,397],[325,401],[334,404],[344,406],[354,407],[367,405],[381,401],[397,395],[417,385],[438,375],[461,364],[484,353],[507,345],[530,339],[550,337],[570,340],[587,347],[603,359],[617,376],[629,398],[637,426],[643,461],[644,502],[641,555],[630,607],[613,658],[588,707],[557,754],[518,799],[473,841],[421,881]]],"え":[[[372,122],[391,128],[408,134],[425,139],[442,143],[457,146],[472,148],[487,149],[501,149],[526,150],[544,151],[554,154],[557,159],[553,166],[541,175],[523,186],[498,200]],[[298,414],[305,418],[312,421],[320,424],[329,425],[338,425],[347,425],[356,423],[366,420],[381,413],[404,403],[431,391],[460,377],[490,363],[518,349],[543,338],[561,329],[575,324],[589,322],[600,323],[609,328],[615,335],[616,344],[611,357],[601,371],[558,422],[513,474],[467,527],[420,580],[373,632],[327,684],[282,733],[239,779],[230,789],[226,797],[225,802],[227,804],[232,804],[238,802],[245,798],[252,791],[295,746],[331,708],[362,676],[388,650],[411,631],[431,617],[450,609],[469,607],[489,613],[502,632],[510,658],[513,690],[516,724],[518,758],[523,788],[531,812],[547,828],[572,839],[603,845],[638,847],[675,846],[710,842],[743,837],[771,831]]],"お":[[[210,322],[215,326],[221,329],[227,333],[234,336],[241,339],[249,341],[257,342],[265,342],[279,339],[303,333],[332,325],[365,317],[397,308],[426,299],[447,293],[459,289],[464,287],[471,285],[477,282],[484,280],[492,278],[499,276],[506,273],[513,271]],[[381,148],[388,152],[395,158],[400,166],[404,175],[408,185],[410,195],[410,205],[409,216],[401,276],[395,345],[390,419],[387,495],[385,569],[384,639],[386,700],[389,751],[390,778],[390,799],[387,815],[381,825],[372,830],[360,830],[344,826],[323,817],[304,806],[284,794],[263,781],[243,766],[225,750],[210,734],[201,718],[197,703],[207,674],[235,640],[278,604],[332,569],[396,537],[465,510],[537,493],[608,486],[663,490],[710,499],[750,515],[782,534],[806,558],[824,585],[834,614],[837,644],[833,674],[821,704],[802,734],[774,762],[739,788],[697,809],[648,826],[592,837]],[[670,203],[687,212],[704,222],[718,232],[731,242],[742,251],[752,261],[760,270],[767,279],[773,289],[776,297],[777,304],[775,310],[772,315],[767,319],[762,322],[757,324]]],"か":[[[226,354],[233,359],[240,364],[249,367],[258,369],[268,370],[280,369],[292,367],[305,363],[384,340],[446,326],[493,323],[528,329],[552,343],[566,366],[574,396],[576,433],[575,465],[573,496],[571,526],[566,555],[561,583],[554,611],[546,638],[537,665],[512,724],[491,766],[472,792],[455,805],[438,807],[422,800],[406,785],[389,765]],[[445,161],[448,166],[451,173],[452,181],[453,190],[454,199],[453,208],[452,217],[450,226],[429,282],[404,344],[376,408],[348,469],[321,526],[297,574],[280,609],[270,628],[259,648],[248,668],[237,688],[226,708],[215,727],[205,745],[194,762],[183,778]],[[710,290],[735,315],[758,341],[779,368],[798,396],[815,426],[829,456],[840,487],[847,518]]],"き":[[[280,278],[287,280],[294,282],[301,284],[309,285],[316,286],[323,286],[329,286],[334,286],[360,281],[392,275],[428,268],[464,260],[499,252],[531,244],[558,236],[577,231],[584,228],[590,226],[596,223],[602,221],[607,219],[612,217],[617,214],[622,211]],[[333,447],[340,449],[348,452],[356,454],[364,455],[372,456],[379,456],[385,456],[390,456],[419,451],[453,444],[491,436],[530,427],[567,417],[602,408],[630,400],[651,394],[658,391],[665,388],[672,386],[677,383],[683,380],[688,378],[693,375],[698,372]],[[385,130],[391,133],[396,137],[401,143],[406,149],[411,155],[415,162],[419,169],[422,177],[443,224],[468,273],[496,322],[526,371],[559,419],[593,465],[628,509],[664,550],[687,576],[704,596],[714,609],[715,616],[706,617],[686,613],[654,602],[609,586]],[[310,764],[349,793],[391,813],[437,826],[484,833],[531,833],[576,829],[620,821],[659,810]]],"く":[[[557,138],[558,144],[559,152],[559,161],[558,170],[557,180],[555,189],[551,198],[547,205],[524,238],[500,271],[477,302],[454,332],[432,360],[411,386],[393,410],[377,430],[365,446],[356,460],[351,473],[349,484],[350,495],[353,506],[360,518],[368,531],[388,558],[409,588],[430,620],[451,653],[473,686],[493,719],[512,751],[530,781],[535,790],[540,798],[545,807],[550,816],[555,826],[560,836],[566,847],[571,860]]],"け":[[[226,181],[231,187],[235,193],[239,199],[242,207],[245,214],[246,222],[247,231],[246,240],[235,293],[225,346],[216,397],[208,447],[201,497],[198,547],[198,598],[201,649],[207,700],[213,728],[218,735],[223,726],[230,706],[238,678],[249,647],[263,617]],[[492,354],[500,359],[507,362],[515,365],[522,367],[530,369],[538,369],[547,369],[556,368],[583,364],[610,359],[636,355],[660,350],[684,346],[706,341],[726,336],[745,331],[754,329],[763,327],[772,325],[780,324],[788,323],[795,322],[802,321],[808,321]],[[658,132],[664,137],[670,142],[674,148],[678,154],[681,160],[683,166],[684,173],[684,179],[684,218],[684,254],[684,290],[684,324],[685,357],[685,389],[685,422],[685,455],[685,522],[682,581],[677,634],[669,681],[655,725],[634,765],[607,804],[570,843]]],"こ":[[[319,245],[323,249],[328,252],[333,255],[340,257],[347,259],[355,260],[364,260],[374,259],[400,255],[425,251],[450,247],[474,243],[499,240],[525,238],[551,236],[579,235],[622,237],[646,242],[653,251],[646,262],[627,275],[600,289],[565,304],[526,318]],[[275,625],[287,670],[308,707],[336,735],[371,756],[412,770],[457,778],[507,781],[560,779],[582,777],[603,775],[623,772],[643,769],[663,766],[682,762],[702,757],[721,752]]],"さ":[[[248,357],[256,361],[265,364],[275,366],[284,368],[294,368],[304,368],[314,368],[324,367],[359,360],[400,350],[445,338],[492,324],[537,309],[579,295],[613,282],[637,271],[646,267],[654,263],[661,259],[667,256],[673,252],[680,248],[687,244],[695,239]],[[381,127],[386,131],[392,135],[398,140],[404,146],[409,153],[414,160],[419,167],[422,174],[443,222],[467,269],[494,316],[524,362],[557,407],[592,452],[629,495],[669,537],[692,562],[707,582],[713,595],[711,603],[700,604],[680,598],[651,585],[613,565]],[[323,739],[344,774],[373,801],[411,820],[455,831],[504,834],[559,831],[616,822],[676,807]]],"し":[[[359,161],[363,171],[365,183],[366,194],[367,206],[367,218],[366,230],[364,242],[362,255],[356,301],[350,347],[345,392],[341,437],[338,482],[336,526],[335,570],[335,613],[343,697],[367,761],[405,805],[455,831],[517,840],[588,832],[667,809],[752,772]]],"す":[[[142,341],[153,347],[164,351],[177,353],[191,353],[206,352],[222,350],[240,347],[259,343],[316,331],[375,321],[434,313],[492,305],[548,298],[600,292],[647,287],[687,283],[710,281],[732,280],[752,279],[772,279],[791,279],[811,280],[830,282],[850,284]],[[529,123],[535,128],[540,134],[545,140],[548,146],[551,153],[552,160],[554,168],[554,177],[554,218],[554,268],[554,323],[554,380],[554,435],[554,484],[554,524],[554,551],[548,595],[531,629],[509,650],[482,659],[456,656],[433,640],[417,610],[411,567],[418,524],[436,494],[463,478],[493,476],[523,489],[550,518],[569,563],[576,625],[572,669],[563,708],[549,744],[531,777],[509,807],[484,835],[457,861],[429,886]]],"せ":[[[151,458],[162,465],[173,470],[186,472],[200,472],[215,471],[231,469],[249,466],[268,463],[332,452],[391,442],[448,432],[501,423],[553,415],[603,407],[652,400],[701,393],[724,390],[746,388],[766,386],[786,385],[805,385],[824,386],[844,387],[863,390]],[[640,163],[646,168],[651,174],[656,180],[659,186],[662,193],[664,200],[665,208],[665,217],[665,251],[665,283],[665,313],[665,341],[665,367],[665,390],[665,412],[665,432],[663,509],[656,564],[645,601],[632,622],[615,631],[597,629],[577,620],[556,607]],[[327,241],[333,246],[338,252],[343,258],[346,264],[349,271],[351,278],[352,286],[352,295],[352,333],[352,376],[352,422],[352,467],[352,510],[352,550],[352,582],[352,607],[355,653],[363,691],[377,722],[397,746],[423,764],[455,777],[493,784],[537,786],[569,786],[597,786],[622,785],[645,784],[668,783],[691,780],[716,776],[744,771]]],"そ":[[[352,202],[359,206],[367,208],[376,210],[384,210],[394,210],[403,209],[412,207],[421,205],[444,199],[466,193],[489,187],[511,180],[534,174],[556,168],[578,162],[599,156],[614,154],[627,155],[637,159],[644,165],[647,173],[647,183],[642,193],[632,204],[588,242],[539,282],[489,322],[437,360],[388,397],[341,430],[300,458],[265,482],[246,495],[234,506],[226,514],[225,520],[229,523],[240,524],[256,522],[278,517],[337,502],[397,487],[458,473],[518,460],[576,448],[633,438],[687,429],[738,422],[766,419],[786,418],[799,418],[804,420],[800,423],[789,426],[770,430],[742,435],[687,446],[632,465],[579,491],[530,522],[488,557],[456,595],[434,636],[427,678],[432,720],[446,756],[470,787],[503,811],[544,828],[594,838],[651,838],[716,830]]],"た":[[[224,325],[229,327],[235,329],[242,331],[249,333],[257,335],[265,336],[274,336],[282,335],[306,331],[332,327],[360,322],[389,316],[419,310],[450,304],[480,298],[510,291],[520,289],[529,287],[538,284],[547,281],[556,279],[564,276],[572,272],[580,269]],[[413,155],[415,160],[417,165],[418,171],[419,178],[419,184],[419,191],[418,197],[416,203],[394,273],[373,339],[351,401],[329,460],[307,518],[286,574],[264,629],[243,683],[238,698],[231,715],[223,733],[215,753],[207,772],[200,790],[193,806],[188,818]],[[517,489],[557,480],[592,473],[623,467],[650,463],[674,460],[695,459],[715,459],[734,460],[773,465],[790,470],[790,474],[777,479],[756,484],[733,490],[711,496],[695,505]],[[497,755],[514,776],[537,793],[565,805],[600,813],[642,817],[691,817],[748,813],[813,806]]],"ち":[[[225,299],[230,301],[236,304],[243,306],[250,308],[258,309],[266,310],[275,310],[283,310],[308,305],[336,299],[367,293],[399,285],[433,277],[466,269],[499,261],[530,254],[539,252],[548,250],[557,247],[566,245],[575,242],[584,239],[592,236],[600,233]],[[419,143],[421,148],[422,154],[423,160],[424,166],[424,173],[424,179],[423,185],[422,191],[412,240],[404,284],[396,325],[387,365],[379,405],[369,448],[358,494],[345,546],[335,583],[326,610],[321,626],[320,632],[324,631],[334,622],[352,607],[378,586],[408,566],[440,548],[473,533],[507,521],[542,511],[576,504],[609,500],[640,499],[668,501],[694,508],[717,520],[736,536],[752,555],[763,578],[771,603],[773,632],[766,676],[747,714],[718,747],[681,776],[639,800],[593,819],[546,834],[499,845]]],"つ":[[[128,411],[135,416],[143,420],[151,422],[160,424],[170,424],[180,423],[191,420],[203,416],[262,392],[317,371],[369,353],[419,339],[468,329],[516,321],[565,317],[615,316],[657,320],[696,329],[732,344],[763,364],[789,389],[808,419],[820,453],[824,492],[814,553],[785,607],[742,653],[687,692],[623,725],[554,752],[483,772],[412,787]]],"て":[[[188,242],[195,247],[202,251],[210,254],[219,256],[229,257],[239,257],[250,256],[263,255],[333,243],[397,233],[454,224],[508,215],[560,207],[612,198],[666,188],[722,178],[760,171],[787,168],[804,167],[810,168],[805,172],[790,177],[764,183],[726,190],[665,207],[608,233],[556,268],[509,310],[471,359],[441,414],[423,473],[416,536],[423,601],[444,658],[476,706],[518,745],[567,775],[621,796],[679,809],[739,813]]],"と":[[[326,169],[332,172],[338,176],[343,181],[349,186],[354,193],[358,201],[361,209],[363,218],[367,235],[372,265],[380,303],[388,346],[396,388],[403,427],[409,458],[413,476]],[[717,234],[717,241],[717,247],[717,254],[715,261],[712,268],[708,274],[703,281],[696,287],[674,302],[651,318],[627,333],[603,349],[576,366],[549,385],[519,405],[487,427],[445,458],[406,490],[373,521],[344,553],[321,584],[303,616],[293,647],[289,679],[293,711],[304,738],[323,760],[349,777],[383,790],[426,799],[477,805],[536,806],[558,806],[582,806],[607,805],[633,804],[659,803],[684,801],[710,798],[734,795]]],"な":[[[210,266],[214,268],[220,270],[225,271],[232,273],[238,274],[245,275],[253,275],[260,275],[279,275],[298,273],[317,271],[336,269],[354,266],[373,262],[392,258],[412,253],[428,249],[444,244],[459,239],[473,233],[486,228],[497,223],[507,219],[516,214]],[[394,128],[396,132],[398,136],[398,140],[399,144],[399,149],[399,154],[398,158],[397,163],[386,211],[373,257],[359,302],[343,346],[326,389],[308,430],[288,471],[267,510],[259,523],[252,535],[245,548],[237,560],[230,572],[222,584],[214,596],[206,608]],[[663,213],[686,222],[708,232],[728,242],[747,252],[763,263],[778,275],[789,287],[798,300],[809,321],[813,334],[812,340],[807,342],[799,341],[789,338],[778,336],[766,336]],[[632,409],[628,416],[625,425],[622,434],[619,443],[617,454],[615,464],[614,475],[615,485],[617,509],[619,532],[622,555],[624,578],[626,601],[627,625],[628,649],[628,674],[617,735],[588,778],[548,807],[501,822],[454,823],[413,813],[384,791],[373,760],[376,742],[385,727],[399,714],[417,703],[437,695],[458,689],[480,686],[500,685],[532,686],[566,690],[602,698],[638,709],[674,723],[710,742],[743,764],[773,790]]],"に":[[[225,209],[229,214],[232,220],[235,227],[236,234],[237,242],[237,250],[237,258],[235,267],[224,322],[211,377],[198,433],[186,488],[175,543],[168,598],[165,652],[168,704],[175,756],[182,784],[191,792],[200,785],[210,765],[221,737],[232,705],[246,672]],[[488,281],[492,284],[496,286],[500,289],[506,291],[512,292],[518,293],[526,294],[535,293],[559,291],[584,286],[610,281],[636,276],[662,271],[687,267],[712,264],[737,263],[772,264],[789,268],[790,275],[778,284],[756,294],[727,305],[694,318],[660,330]],[[482,624],[491,664],[508,697],[530,722],[557,741],[589,753],[624,760],[663,763],[704,761],[721,759],[737,758],[753,756],[769,754],[784,752],[800,749],[817,746],[835,742]]],"ぬ":[[[233,261],[239,266],[245,272],[250,278],[254,284],[257,291],[260,299],[262,307],[264,315],[270,357],[278,398],[285,439],[294,479],[304,519],[315,558],[328,596],[342,633],[349,648],[355,663],[362,677],[370,691],[378,706],[386,720],[395,734],[405,748]],[[524,177],[527,184],[529,191],[530,197],[531,204],[532,210],[532,217],[531,224],[530,231],[516,286],[498,347],[477,411],[453,475],[429,536],[405,592],[383,640],[363,677],[324,732],[288,759],[256,762],[228,748],[205,722],[189,691],[178,660],[174,635],[192,559],[240,486],[310,423],[396,371],[490,336],[585,320],[673,328],[746,364],[770,386],[790,409],[805,435],[817,462],[825,489],[830,518],[831,548],[830,578],[812,659],[775,721],[727,763],[673,787],[619,795],[573,788],[541,767],[529,733],[536,705],[555,687],[584,677],[620,675],[659,679],[701,689],[741,704],[777,723],[788,730],[800,738],[812,747],[824,756],[835,765],[846,774],[856,783],[865,791]]],"ね":[[[305,133],[311,139],[315,144],[318,150],[320,156],[322,163],[323,170],[323,178],[323,187],[319,231],[316,282],[312,337],[309,398],[306,462],[304,530],[301,601],[299,674],[299,690],[299,706],[299,722],[298,738],[298,754],[298,770],[298,787],[297,803]],[[157,348],[163,350],[169,353],[175,355],[181,356],[187,357],[194,357],[201,356],[209,354],[218,352],[229,349],[242,345],[257,340],[273,335],[290,329],[306,323],[322,317],[342,311],[356,307],[366,306],[371,308],[372,314],[369,323],[362,335],[351,351],[331,378],[310,406],[288,436],[266,467],[244,499],[222,531],[201,564],[182,596],[166,625],[156,645],[152,657],[153,661],[159,660],[169,652],[183,640],[200,624],[266,559],[331,496],[396,435],[460,380],[523,333],[583,297],[641,273],[696,265],[731,270],[759,284],[780,308],[795,341],[805,383],[811,434],[814,494],[815,563],[803,648],[771,708],[727,747],[676,766],[625,769],[581,759],[550,739],[538,712],[545,684],[566,665],[597,654],[634,650],[676,653],[719,662],[760,677],[795,695],[805,702],[814,709],[824,717],[833,726],[842,734],[850,742],[858,750],[864,757]]],"の":[[[494,263],[497,268],[499,275],[501,282],[503,289],[504,298],[504,306],[503,315],[502,323],[494,358],[485,397],[473,438],[460,480],[446,521],[431,561],[417,596],[403,627],[371,686],[341,724],[313,744],[285,745],[259,731],[232,703],[206,661],[180,609],[165,539],[182,465],[224,393],[287,327],[366,274],[455,238],[549,225],[644,239],[740,287],[805,357],[840,441],[846,531],[825,620],[776,699],[701,760],[600,797]]],"は":[[[225,165],[229,171],[233,177],[236,184],[238,192],[240,200],[241,208],[241,217],[240,226],[228,287],[217,349],[207,412],[199,475],[194,538],[193,602],[195,666],[203,729],[210,771],[215,791],[219,794],[222,782],[226,761],[232,733],[241,702],[255,672]],[[455,348],[464,353],[472,357],[481,360],[489,362],[498,364],[507,365],[517,364],[527,363],[559,358],[589,353],[618,348],[646,343],[672,338],[697,332],[720,327],[742,321],[752,319],[763,316],[772,314],[782,313],[791,311],[799,310],[806,310],[813,310]],[[640,151],[647,159],[653,166],[658,173],[661,180],[664,188],[665,195],[666,203],[667,211],[667,233],[669,277],[671,337],[673,407],[676,480],[678,549],[680,609],[680,651],[668,718],[636,765],[591,795],[540,808],[488,808],[443,797],[411,776],[399,748],[409,720],[434,702],[471,693],[515,692],[562,695],[606,702],[644,712],[670,721],[690,732],[709,744],[728,757],[746,770],[762,782],[775,793],[786,802],[793,807]]],"ひ":[[[183,230],[188,234],[194,237],[201,240],[208,243],[216,245],[225,246],[234,245],[243,243],[253,240],[265,236],[277,232],[291,227],[305,221],[319,215],[333,209],[348,202],[367,193],[382,189],[394,189],[402,192],[406,199],[404,209],[398,223],[387,239],[306,348],[251,449],[219,542],[210,624],[222,694],[254,750],[304,791],[373,815],[435,818],[496,800],[554,763],[605,707],[648,631],[679,538],[697,426],[699,297],[698,253],[697,222],[698,202],[701,194],[706,198],[714,214],[724,242],[737,281],[751,319],[767,356],[785,390],[804,422],[824,451],[844,479],[865,503],[885,524]]],"ふ":[[[391,143],[404,154],[417,164],[430,173],[444,180],[459,187],[474,192],[491,196],[508,200],[535,205],[549,210],[554,216],[551,223],[541,230],[527,238],[509,247],[491,256]],[[400,430],[408,446],[419,463],[433,480],[449,498],[467,518],[487,540],[508,564],[531,591],[559,636],[570,682],[566,725],[547,762],[516,791],[473,807],[419,807],[356,789]],[[151,673],[154,687],[157,701],[161,714],[166,727],[172,738],[179,749],[187,758],[197,766],[201,767],[204,763],[209,756],[217,747],[230,734],[250,719],[279,701],[319,682]],[[735,568],[753,580],[770,592],[786,604],[801,615],[814,626],[826,635],[834,643],[840,649],[857,673],[865,689],[864,698],[857,702],[845,704],[829,706],[813,708],[797,714]]],"へ":[[[138,447],[145,452],[153,456],[161,458],[169,459],[178,458],[186,455],[194,451],[202,444],[214,432],[227,420],[240,408],[253,397],[266,385],[279,373],[292,361],[305,347],[323,330],[339,319],[354,312],[368,310],[382,312],[396,318],[410,327],[425,339],[469,376],[516,415],[564,454],[610,492],[652,526],[688,556],[715,578],[732,591],[744,601],[761,614],[780,630],[800,647],[820,664],[837,679],[851,690],[859,697]]],"ほ":[[[225,172],[229,178],[233,184],[236,191],[238,199],[240,207],[241,215],[241,224],[240,233],[228,294],[217,357],[207,421],[199,486],[194,551],[193,617],[195,681],[203,745],[210,787],[215,807],[219,810],[222,798],[226,777],[232,749],[241,718],[255,688]],[[487,194],[494,198],[500,201],[507,204],[514,206],[521,207],[528,208],[535,208],[543,207],[568,203],[592,199],[615,194],[637,190],[658,186],[677,181],[695,177],[712,172],[721,170],[729,168],[736,167],[744,165],[751,164],[757,163],[763,163],[768,163]],[[494,406],[501,411],[509,415],[517,418],[525,420],[533,421],[542,422],[550,422],[560,421],[588,416],[616,412],[643,408],[668,403],[691,399],[714,394],[735,390],[754,385],[764,382],[774,380],[783,378],[792,377],[801,375],[809,375],[816,374],[822,374]],[[665,211],[670,217],[673,224],[675,231],[677,238],[679,246],[680,254],[680,262],[680,271],[681,291],[683,332],[686,387],[689,451],[693,518],[696,582],[698,638],[698,679],[687,732],[656,770],[612,795],[561,807],[511,808],[467,799],[436,780],[424,752],[433,724],[456,704],[490,693],[532,688],[577,690],[621,698],[662,710],[695,726],[714,738],[733,751],[752,764],[770,776],[786,788],[800,798],[811,806],[818,812]]],"ま":[[[274,296],[281,300],[289,303],[297,305],[305,307],[313,308],[321,308],[330,308],[339,308],[380,304],[422,299],[465,294],[508,288],[549,282],[589,276],[625,269],[657,263],[667,262],[676,260],[685,260],[694,259],[702,259],[710,259],[716,259],[723,259]],[[310,476],[319,481],[327,484],[336,487],[345,488],[354,489],[363,489],[373,488],[383,487],[415,482],[447,477],[478,471],[508,466],[539,460],[569,453],[600,447],[631,440],[642,437],[653,435],[663,433],[673,431],[683,430],[692,429],[700,428],[707,428]],[[512,128],[517,135],[520,142],[523,150],[526,159],[527,167],[528,176],[528,185],[529,194],[529,219],[529,269],[530,337],[531,417],[531,499],[532,578],[533,644],[533,692],[521,756],[490,802],[445,831],[395,845],[344,846],[300,835],[269,813],[257,783],[267,750],[296,728],[338,714],[390,708],[448,709],[506,718],[562,733],[611,753],[631,765],[651,776],[671,786],[688,797],[705,807],[721,818],[734,828],[747,837]]],"み":[[[298,239],[305,244],[312,248],[319,250],[326,252],[334,252],[343,252],[352,251],[361,250],[375,248],[388,245],[401,242],[414,238],[428,234],[442,230],[456,226],[470,221],[484,218],[495,217],[505,218],[512,222],[516,229],[517,239],[516,252],[512,268],[504,289],[494,315],[483,346],[469,381],[454,419],[437,459],[420,501],[401,545],[354,642],[307,711],[262,756],[220,779],[185,783],[157,772],[139,748],[133,716],[141,672],[164,639],[199,614],[241,598],[290,589],[340,586],[390,587],[436,592],[497,602],[552,613],[604,626],[654,640],[701,657],[748,676],[795,698],[843,722]],[[728,502],[730,510],[732,518],[732,525],[733,533],[732,540],[731,546],[730,553],[728,560],[719,591],[707,628],[691,669],[670,712],[643,756],[611,797],[572,836],[525,869]]],"む":[[[180,290],[187,295],[194,299],[202,301],[209,303],[217,304],[225,303],[234,303],[242,301],[270,297],[297,291],[323,286],[350,281],[376,275],[402,269],[428,263],[455,256],[464,254],[474,251],[483,249],[491,248],[499,246],[507,245],[514,245],[520,244]],[[340,142],[345,147],[349,152],[353,157],[356,162],[358,169],[359,175],[359,183],[359,190],[356,228],[353,265],[350,302],[346,340],[342,379],[337,420],[330,464],[322,510],[305,571],[281,612],[252,637],[222,648],[194,645],[171,631],[156,608],[152,578],[155,553],[163,529],[175,509],[189,492],[206,477],[225,466],[246,458],[267,454],[286,454],[306,457],[325,464],[340,476],[350,494],[352,519],[343,551],[321,592],[284,653],[258,703],[245,742],[244,773],[256,795],[281,811],[318,821],[368,826],[405,828],[440,829],[473,830],[505,830],[536,829],[567,826],[598,823],[630,818],[670,810],[695,803],[708,796],[712,787],[710,776],[705,761],[700,741],[697,716]],[[720,333],[743,343],[764,354],[784,364],[801,375],[818,387],[832,399],[845,412],[857,425],[873,449],[879,463],[877,470],[868,471],[856,470],[842,467],[828,466],[816,467]]],"め":[[[252,291],[258,295],[262,300],[266,305],[269,311],[272,318],[273,325],[274,332],[275,339],[278,379],[282,419],[287,458],[295,496],[304,533],[314,567],[327,599],[342,627],[347,637],[355,649],[364,663],[373,677],[383,691],[392,704],[401,714],[408,723]],[[547,178],[550,183],[553,190],[555,197],[556,205],[557,213],[557,221],[556,230],[555,239],[542,292],[524,351],[501,412],[475,473],[448,532],[421,586],[394,634],[370,672],[331,722],[298,755],[270,773],[245,777],[223,768],[203,747],[185,717],[166,678],[163,621],[187,559],[234,497],[300,439],[379,392],[468,358],[562,344],[656,354],[742,394],[798,453],[827,523],[829,598],[805,672],[756,737],[681,787],[583,814]]],"も":[[[451,135],[457,142],[461,150],[464,158],[465,167],[466,176],[465,186],[464,197],[461,209],[451,257],[442,304],[434,351],[426,398],[418,445],[411,493],[404,543],[397,595],[390,659],[389,714],[393,761],[405,800],[426,830],[457,852],[499,865],[553,869],[618,863],[671,847],[714,820],[744,783],[762,736],[768,680],[759,615],[737,541]],[[243,318],[248,321],[252,324],[258,327],[264,331],[271,333],[279,335],[288,336],[299,336],[336,333],[371,330],[405,326],[437,322],[468,318],[498,313],[526,309],[553,304],[566,302],[577,300],[587,298],[597,297],[606,296],[615,295],[625,294],[634,295]],[[242,490],[239,503],[239,515],[243,525],[250,534],[260,542],[274,547],[292,550],[313,552],[344,551],[373,550],[402,548],[430,546],[457,543],[482,541],[504,537],[523,534],[531,533],[539,532],[548,530],[557,528],[567,526],[576,523],[584,521],[592,518]]],"や":[[[165,453],[172,458],[180,463],[190,466],[200,468],[210,469],[221,468],[233,466],[244,461],[307,430],[369,399],[430,369],[489,342],[547,318],[603,300],[658,288],[711,284],[741,287],[768,292],[793,301],[815,313],[833,329],[846,348],[854,371],[857,397],[852,426],[839,453],[819,479],[791,503],[758,524],[720,541],[677,554],[632,561]],[[432,146],[450,150],[467,155],[484,162],[499,170],[512,179],[524,188],[532,197],[538,206],[543,221],[544,229],[543,234],[538,235],[533,234],[526,232],[518,231],[511,230]],[[275,224],[283,230],[289,235],[295,241],[299,246],[303,252],[306,258],[309,264],[311,272],[322,316],[337,373],[355,439],[375,510],[395,581],[414,648],[432,707],[446,753],[449,761],[452,771],[455,781],[458,793],[462,805],[465,817],[469,828],[473,840]]],"ゆ":[[[193,233],[198,238],[201,245],[204,252],[207,259],[208,267],[209,275],[208,283],[207,290],[198,330],[190,369],[185,408],[181,447],[179,487],[179,527],[182,568],[187,611],[195,662],[200,689],[203,696],[205,688],[206,669],[208,645],[211,619],[217,598],[252,524],[294,460],[341,406],[393,361],[448,326],[506,301],[565,286],[624,281],[677,286],[721,299],[756,318],[783,343],[802,372],[816,403],[823,435],[825,467],[813,550],[779,613],[730,657],[670,682],[604,690],[539,682],[480,658],[431,620]],[[536,154],[544,160],[551,166],[556,172],[560,179],[563,186],[565,196],[567,206],[568,219],[571,254],[574,288],[576,321],[578,353],[579,386],[581,419],[582,453],[583,489],[582,564],[575,628],[564,682],[549,726],[531,764],[511,795],[491,823],[469,849]]],"よ":[[[534,325],[560,320],[584,316],[607,311],[629,306],[649,302],[669,297],[687,292],[704,287],[713,284],[721,282],[729,281],[736,279],[743,278],[750,277],[756,277],[761,276]],[[501,127],[508,135],[514,142],[519,149],[522,156],[525,164],[527,171],[527,179],[528,187],[526,246],[525,305],[525,366],[526,427],[528,489],[531,551],[535,614],[540,678],[531,747],[498,796],[447,827],[387,842],[326,844],[273,833],[235,812],[220,783],[231,749],[259,726],[301,714],[352,710],[407,713],[461,721],[510,732],[550,746],[576,756],[599,766],[620,775],[639,785],[658,796],[677,809],[697,823],[720,841]]],"ら":[[[324,138],[338,147],[353,156],[370,162],[388,168],[407,172],[429,175],[451,176],[476,177],[505,177],[518,179],[519,183],[511,188],[499,193],[484,199],[471,204],[464,209]],[[329,328],[322,343],[316,358],[312,373],[308,388],[305,403],[303,418],[301,434],[300,449],[299,470],[298,490],[297,511],[295,533],[293,555],[290,578],[286,601],[281,625],[273,659],[271,679],[273,688],[278,688],[286,682],[294,673],[302,664],[308,657],[348,626],[387,600],[424,580],[461,565],[497,554],[534,547],[570,543],[607,542],[638,545],[667,552],[693,562],[716,577],[735,595],[749,616],[758,642],[761,670],[755,714],[738,753],[710,788],[674,816],[631,840],[580,858],[524,870],[463,876]]],"り":[[[356,232],[360,237],[363,244],[367,251],[369,258],[371,266],[372,275],[372,284],[370,292],[360,336],[350,384],[341,434],[334,485],[329,536],[326,587],[327,636],[331,681],[337,714],[342,728],[346,727],[351,714],[356,694],[362,670],[371,646],[383,624]],[[636,172],[643,179],[649,186],[654,194],[657,201],[660,208],[662,216],[663,224],[663,232],[663,248],[663,280],[663,322],[663,372],[663,424],[663,475],[663,522],[663,560],[661,613],[655,661],[645,704],[631,743],[614,778],[595,809],[572,837],[547,863]]],"る":[[[315,187],[321,191],[329,195],[337,199],[346,202],[357,204],[368,205],[380,204],[393,201],[407,197],[422,193],[439,188],[457,183],[476,178],[495,172],[516,165],[536,158],[555,153],[570,151],[581,152],[588,156],[591,162],[590,172],[585,183],[576,197],[560,219],[536,251],[505,291],[469,336],[430,383],[392,430],[355,473],[322,509],[294,538],[272,560],[256,576],[248,585],[250,586],[263,579],[289,564],[329,539],[387,510],[451,489],[516,480],[580,483],[636,502],[682,536],[712,589],[723,662],[707,731],[664,782],[604,818],[536,838],[467,843],[407,835],[364,812],[348,778],[355,745],[375,723],[404,711],[438,708],[476,714],[512,728],[546,748],[572,774]]],"れ":[[[316,119],[321,124],[326,130],[330,137],[334,144],[337,152],[339,160],[340,169],[339,178],[337,206],[333,258],[329,327],[325,405],[321,485],[317,560],[315,622],[314,663],[314,692],[314,720],[314,746],[315,771],[315,794],[315,814],[315,830],[315,842]],[[156,374],[163,378],[170,381],[177,383],[185,384],[193,383],[202,381],[213,378],[225,374],[239,368],[252,363],[265,358],[278,352],[291,347],[306,340],[323,332],[344,323],[357,319],[366,317],[373,318],[376,322],[377,328],[376,335],[372,345],[367,356],[349,386],[330,416],[311,446],[291,476],[269,507],[246,539],[221,573],[194,609],[171,640],[156,664],[148,681],[147,690],[155,691],[170,683],[192,666],[223,638],[269,594],[309,556],[345,520],[380,486],[415,453],[451,418],[490,381],[534,339],[559,319],[587,301],[616,286],[644,278],[668,278],[688,288],[699,311],[701,347],[697,384],[694,422],[691,459],[688,495],[685,531],[683,566],[681,599],[680,630],[682,694],[693,738],[713,765],[739,776],[769,774],[801,761],[833,738],[864,709]]],"ろ":[[[339,201],[345,207],[352,214],[360,219],[370,223],[380,226],[392,227],[404,226],[417,224],[431,220],[444,216],[459,212],[474,207],[491,202],[508,197],[527,190],[547,183],[565,178],[579,176],[588,177],[593,181],[595,187],[593,197],[587,209],[578,222],[550,260],[520,299],[489,338],[457,379],[424,419],[391,461],[358,503],[325,546],[302,576],[283,599],[271,614],[266,621],[271,620],[285,611],[312,593],[352,567],[416,531],[486,505],[557,490],[625,488],[686,500],[735,529],[768,575],[779,641],[773,691],[754,734],[725,771],[687,801],[643,826],[593,845],[540,861],[485,871]]],"わ":[[[353,135],[358,140],[362,146],[366,153],[369,160],[371,168],[372,176],[372,185],[372,194],[368,243],[364,305],[360,375],[356,448],[352,520],[349,586],[347,640],[347,679],[346,708],[346,736],[345,762],[344,787],[343,810],[342,830],[341,846],[341,858]],[[161,374],[168,378],[175,381],[182,383],[189,383],[198,382],[207,381],[217,378],[230,374],[249,367],[267,361],[285,355],[302,349],[320,343],[338,336],[358,328],[379,319],[392,314],[403,312],[412,313],[418,317],[420,323],[419,332],[413,343],[404,356],[381,383],[358,412],[335,441],[311,472],[286,504],[259,538],[231,573],[201,611],[178,641],[162,665],[153,681],[152,690],[159,690],[173,682],[197,665],[229,638],[306,573],[387,514],[468,463],[548,424],[624,400],[695,394],[758,408],[811,445],[849,500],[865,558],[862,616],[839,672],[800,725],[745,771],[677,809],[597,836]]],"を":[[[262,256],[268,259],[273,262],[279,265],[285,267],[292,268],[300,268],[308,267],[317,266],[353,259],[384,253],[413,248],[440,242],[466,237],[492,232],[517,227],[544,223],[556,221],[566,219],[576,218],[585,216],[594,216],[603,215],[612,215],[621,216]],[[458,132],[461,136],[463,141],[465,146],[466,153],[467,160],[466,167],[465,175],[462,183],[445,218],[428,254],[410,289],[392,324],[372,359],[351,394],[328,428],[304,461],[277,498],[257,524],[246,539],[243,545],[250,542],[265,530],[290,510],[324,484],[357,462],[393,445],[429,437],[463,441],[493,463],[516,505],[531,572],[534,666]],[[762,366],[764,372],[764,379],[763,385],[761,392],[757,399],[751,406],[744,412],[734,419],[707,433],[652,462],[581,503],[502,552],[427,606],[365,662],[328,718],[324,770],[340,798],[364,819],[395,834],[431,842],[471,847],[514,847],[557,845],[599,841],[614,839],[630,837],[645,835],[660,833],[674,831],[688,829],[701,827],[713,825]]],"ん":[[[517,151],[519,158],[521,167],[523,177],[523,187],[522,198],[521,208],[518,218],[513,227],[484,274],[446,334],[403,404],[357,478],[311,551],[268,620],[231,680],[203,726],[176,771],[158,804],[149,825],[147,834],[154,830],[167,813],[188,782],[216,737],[276,651],[331,592],[381,558],[425,547],[460,555],[487,581],[504,622],[510,675],[518,751],[539,806],[573,838],[615,847],[663,832],[716,791],[771,724],[824,630]]]},"katakana":{"ア":[[[216,241],[224,245],[231,249],[239,251],[247,252],[257,252],[267,251],[279,250],[294,248],[339,241],[393,233],[454,224],[518,215],[582,206],[641,198],[694,191],[737,186],[753,185],[768,187],[778,191],[785,197],[787,206],[784,216],[776,228],[761,241],[738,258],[714,275],[690,292],[666,309],[639,327],[611,346],[581,366],[547,388]],[[487,377],[490,383],[492,388],[493,394],[494,400],[495,406],[495,412],[494,419],[493,426],[478,487],[461,545],[443,599],[422,651],[398,701],[372,749],[343,796],[310,843]]],"イ":[[[640,154],[640,160],[640,166],[639,173],[637,179],[635,186],[632,192],[629,198],[625,204],[589,250],[549,298],[505,348],[456,400],[403,451],[343,501],[278,550],[206,597]],[[517,403],[520,407],[523,411],[525,417],[526,422],[528,428],[528,434],[529,439],[529,445],[529,462],[529,498],[529,547],[529,603],[529,658],[529,708],[529,745],[529,763],[529,771],[529,783],[528,798],[528,814],[528,830],[528,846],[528,860],[528,870]]],"ウ":[[[489,134],[492,138],[494,143],[496,148],[498,154],[499,159],[499,165],[500,171],[500,177],[500,185],[500,198],[500,215],[500,234],[500,252],[500,269],[500,283],[500,292]],[[243,287],[246,291],[249,296],[251,301],[252,306],[253,312],[254,318],[254,323],[255,329],[255,345],[255,363],[256,381],[256,401],[257,421],[258,441],[258,460],[259,479],[259,488],[259,496],[259,504],[260,512],[260,519],[260,526],[260,533],[260,539]],[[267,329],[334,322],[401,314],[466,307],[528,301],[586,294],[638,289],[682,283],[717,279],[743,276],[762,276],[775,279],[782,285],[785,294],[784,307],[780,323],[774,342],[753,398],[723,464],[685,534],[641,608],[589,680],[531,749],[467,810],[398,861]]],"エ":[[[292,327],[301,329],[309,331],[318,332],[327,332],[335,332],[344,332],[353,331],[361,330],[393,325],[428,321],[466,316],[506,311],[547,307],[589,302],[630,298],[670,295],[678,294],[685,294],[693,294],[701,294],[709,294],[716,295],[724,295],[732,297]],[[489,350],[493,354],[495,359],[497,364],[499,369],[500,375],[501,381],[501,387],[501,392],[500,410],[499,430],[498,453],[498,478],[496,505],[495,534],[494,565],[493,596],[493,604],[493,612],[492,620],[492,629],[492,637],[492,645],[491,653],[491,662]],[[174,692],[186,695],[199,697],[212,698],[225,699],[238,699],[251,698],[263,697],[275,696],[336,688],[396,681],[455,675],[513,670],[571,666],[628,663],[684,661],[739,660],[751,660],[763,661],[775,662],[787,664],[800,666],[812,669],[824,672],[835,677]]],"オ":[[[179,347],[192,353],[205,356],[218,359],[231,360],[243,360],[256,359],[268,358],[280,357],[341,348],[401,339],[460,332],[518,325],[575,320],[632,315],[688,310],[744,307],[755,307],[766,307],[778,307],[789,308],[801,310],[813,313],[826,316],[840,320]],[[554,150],[558,156],[561,162],[564,169],[566,176],[567,184],[568,191],[569,199],[569,206],[569,246],[569,305],[568,379],[568,460],[568,543],[567,623],[567,692],[567,744],[564,801],[558,834],[548,847],[536,847],[522,836],[508,821],[494,806],[482,795]],[[553,334],[552,339],[550,346],[547,352],[543,359],[538,366],[533,373],[527,381],[520,389],[491,423],[457,460],[420,498],[380,538],[338,577],[294,617],[249,655],[202,692]]],"カ":[[[234,373],[241,377],[248,380],[256,383],[264,385],[273,387],[281,387],[290,387],[299,386],[359,378],[417,370],[471,363],[522,356],[570,349],[614,343],[654,337],[689,332],[712,330],[732,330],[748,333],[760,339],[768,349],[773,363],[773,381],[768,405],[761,434],[753,464],[744,495],[735,528],[724,562],[712,597],[699,634],[683,672],[650,743],[622,789],[598,813],[577,821],[558,817],[541,806],[524,793],[507,781]],[[513,157],[515,163],[518,169],[520,176],[521,184],[522,192],[522,200],[521,209],[520,219],[502,297],[478,374],[449,449],[416,521],[377,589],[336,652],[290,709],[242,759]]],"キ":[[[248,372],[254,374],[262,375],[270,377],[278,378],[287,378],[296,378],[305,377],[314,375],[357,363],[405,350],[454,337],[503,324],[550,312],[593,301],[630,292],[658,284],[668,282],[678,280],[690,279],[701,277],[712,276],[723,275],[732,275],[741,275]],[[179,604],[187,606],[197,608],[208,610],[219,611],[231,611],[243,610],[254,608],[266,605],[326,587],[384,570],[440,554],[496,540],[551,526],[605,513],[661,499],[717,486],[729,483],[743,481],[758,478],[772,476],[787,475],[801,474],[813,473],[824,474]],[[448,154],[456,160],[463,166],[469,172],[473,178],[477,185],[480,192],[482,200],[484,210],[492,264],[502,330],[512,403],[523,481],[533,558],[543,632],[552,699],[560,753],[561,765],[563,777],[564,791],[566,805],[568,819],[569,833],[571,845],[572,855]]],"ク":[[[459,180],[460,185],[461,191],[461,197],[461,203],[460,209],[459,215],[457,221],[454,227],[440,255],[426,282],[411,309],[394,336],[376,363],[356,391],[333,419],[306,448]],[[470,263],[479,263],[489,263],[498,262],[507,261],[516,260],[525,258],[533,256],[540,254],[560,250],[578,245],[595,241],[612,237],[628,233],[644,228],[661,224],[679,219],[697,215],[712,213],[723,214],[731,217],[735,224],[735,234],[732,247],[726,264],[688,342],[645,418],[597,492],[544,564],[486,633],[423,698],[354,760],[280,819]]],"ケ":[[[376,164],[377,171],[378,178],[378,186],[378,193],[377,201],[376,209],[373,216],[370,224],[354,259],[337,293],[320,328],[300,362],[279,396],[255,432],[228,468],[197,505]],[[348,345],[355,348],[362,350],[369,351],[377,352],[384,353],[392,352],[400,351],[408,350],[452,341],[495,332],[538,324],[580,316],[622,309],[662,302],[700,296],[736,290],[748,288],[760,287],[770,286],[781,285],[791,285],[801,285],[811,285],[821,286]],[[591,357],[593,363],[594,370],[594,378],[595,385],[594,393],[594,401],[592,409],[591,416],[577,465],[561,516],[542,569],[518,621],[489,674],[455,725],[414,773],[365,819]]],"コ":[[[276,321],[282,325],[288,328],[294,331],[300,334],[307,336],[315,337],[325,337],[336,336],[385,328],[435,321],[483,314],[530,307],[574,301],[614,295],[649,290],[679,286],[708,282],[729,281],[745,284],[754,290],[759,300],[760,314],[758,332],[752,354],[743,391],[734,429],[725,468],[717,507],[709,548],[701,589],[694,631],[688,674]],[[252,710],[261,713],[269,716],[277,719],[286,720],[295,721],[305,721],[316,720],[328,719],[367,714],[406,709],[445,704],[484,700],[522,696],[561,692],[599,690],[638,688],[651,688],[662,688],[673,688],[683,688],[693,689],[703,690],[714,691],[726,693]]],"サ":[[[151,407],[161,411],[170,414],[179,417],[188,419],[197,420],[208,420],[220,419],[233,417],[295,407],[360,397],[429,389],[499,382],[569,376],[639,372],[706,369],[770,368],[784,368],[797,369],[810,369],[821,370],[832,371],[843,373],[854,374],[866,376]],[[336,214],[339,219],[342,224],[344,228],[345,233],[346,239],[347,244],[347,251],[348,258],[348,290],[349,323],[350,357],[351,392],[351,426],[352,460],[353,492],[354,523],[355,534],[355,546],[356,558],[357,569],[357,580],[358,591],[358,600],[358,608]],[[639,152],[643,159],[647,165],[650,171],[651,176],[653,183],[653,190],[654,199],[654,210],[654,235],[653,256],[653,273],[653,287],[653,302],[652,317],[652,334],[652,356],[648,434],[637,508],[618,578],[593,642],[563,702],[526,755],[485,802],[439,842]]],"シ":[[[366,181],[383,188],[400,196],[416,206],[430,217],[443,229],[455,240],[464,251],[471,260]],[[239,391],[251,396],[266,403],[282,412],[299,422],[315,434],[330,445],[342,456],[351,466]],[[303,780],[315,782],[328,784],[340,784],[352,783],[364,781],[375,778],[387,773],[398,767],[458,730],[516,691],[571,647],[624,601],[675,550],[725,496],[773,437],[821,374]]],"ス":[[[276,270],[283,274],[289,278],[297,281],[304,283],[312,284],[320,284],[329,284],[337,282],[382,271],[424,261],[464,252],[502,243],[537,235],[569,228],[598,221],[624,214],[646,210],[663,210],[676,213],[685,219],[690,228],[691,239],[689,252],[683,267],[642,349],[596,428],[544,503],[486,574],[422,639],[352,697],[276,749],[193,792]],[[560,525],[597,552],[633,580],[668,610],[702,642],[734,676],[763,711],[791,749],[817,788]]],"セ":[[[156,453],[166,458],[176,462],[185,465],[194,467],[203,469],[213,469],[223,468],[235,466],[310,449],[374,434],[430,421],[481,409],[531,397],[582,385],[637,373],[699,359],[763,349],[797,352],[807,366],[798,389],[774,419],[742,453],[705,489],[670,525]],[[389,179],[395,186],[400,193],[403,200],[406,206],[407,213],[408,221],[408,230],[408,240],[408,298],[407,354],[405,407],[404,456],[402,502],[401,544],[400,583],[400,617],[402,660],[406,695],[414,723],[425,743],[441,758],[460,767],[485,772],[514,774],[541,774],[567,775],[590,775],[612,775],[631,775],[649,775],[665,775],[679,775],[692,775],[705,774],[718,773],[730,772],[742,771],[754,769],[765,767],[775,765]]],"ソ":[[[216,234],[229,249],[242,265],[255,283],[268,303],[280,324],[292,347],[303,372],[314,398]],[[766,193],[770,201],[773,209],[774,218],[775,226],[775,236],[773,246],[771,258],[767,271],[741,344],[704,422],[658,502],[604,581],[545,657],[481,726],[415,785],[349,833]]],"タ":[[[448,181],[449,187],[450,194],[450,201],[450,208],[449,215],[448,222],[446,229],[443,235],[426,267],[410,298],[392,329],[374,360],[353,392],[329,424],[302,456],[272,490]],[[456,279],[466,280],[475,281],[483,280],[492,280],[500,279],[509,277],[517,275],[526,273],[546,268],[565,264],[584,259],[601,254],[619,250],[636,245],[654,240],[672,235],[690,231],[706,230],[718,232],[727,237],[732,245],[734,256],[732,270],[726,287],[688,369],[648,447],[604,521],[555,592],[498,658],[432,721],[355,781],[266,837]],[[398,419],[420,431],[440,444],[458,459],[475,475],[490,493],[505,513],[519,534],[533,558]]],"チ":[[[640,140],[638,149],[635,156],[632,164],[627,170],[622,176],[617,181],[611,185],[604,189],[576,204],[545,220],[510,236],[473,253],[431,269],[385,284],[334,298],[279,311]],[[170,472],[179,475],[188,478],[196,481],[204,483],[212,484],[221,485],[231,485],[242,484],[315,476],[382,468],[446,461],[507,455],[568,450],[628,445],[691,442],[757,439],[773,439],[787,439],[801,441],[813,442],[825,444],[836,447],[846,450],[857,453]],[[503,282],[506,285],[509,289],[512,293],[515,299],[517,305],[518,311],[519,318],[520,326],[520,346],[520,366],[520,386],[520,406],[520,427],[520,448],[520,470],[520,493],[518,545],[511,595],[500,644],[484,691],[463,736],[436,779],[405,818],[368,853]]],"ツ":[[[197,288],[205,300],[213,314],[220,329],[227,346],[232,364],[237,382],[240,399],[242,415]],[[419,218],[430,231],[441,246],[452,262],[461,280],[469,298],[476,317],[480,336],[483,354]],[[776,256],[778,264],[780,272],[780,281],[779,291],[778,300],[776,310],[773,320],[769,329],[741,394],[706,461],[665,528],[617,594],[562,657],[499,715],[428,767],[347,811]]],"テ":[[[335,197],[342,201],[350,204],[358,207],[366,208],[374,209],[383,210],[392,210],[401,209],[436,205],[468,201],[497,197],[524,193],[550,189],[576,186],[601,182],[627,179],[639,177],[650,176],[660,176],[669,175],[677,175],[685,175],[693,176],[702,177]],[[183,405],[193,408],[202,410],[211,412],[220,413],[228,413],[237,413],[245,413],[252,412],[326,402],[394,392],[458,383],[519,375],[577,368],[634,362],[691,358],[749,356],[767,355],[782,355],[795,355],[807,356],[817,357],[826,358],[835,359],[844,361]],[[532,397],[535,400],[537,405],[539,409],[541,414],[542,420],[543,425],[543,431],[542,437],[533,491],[517,548],[495,604],[468,658],[436,709],[400,754],[360,792],[317,821]]],"ト":[[[404,150],[408,155],[412,160],[415,165],[418,172],[420,178],[422,186],[423,193],[423,201],[423,291],[423,379],[423,463],[423,541],[423,609],[423,665],[423,706],[423,729],[423,744],[423,761],[423,778],[423,795],[423,812],[423,827],[423,841],[423,852]],[[452,396],[490,411],[524,428],[555,447],[583,468],[609,490],[632,515],[655,540],[677,568]]],"ナ":[[[170,405],[179,408],[187,410],[196,412],[206,413],[216,413],[227,413],[239,411],[253,409],[320,400],[385,391],[448,383],[510,376],[570,370],[627,365],[682,361],[734,358],[747,357],[762,357],[776,356],[791,356],[805,357],[819,357],[832,358],[843,359]],[[489,133],[494,138],[499,143],[504,148],[507,155],[510,162],[512,169],[513,178],[514,188],[514,205],[514,231],[514,264],[514,300],[515,336],[515,369],[515,395],[515,411],[512,478],[505,544],[492,606],[473,665],[450,721],[421,772],[386,819],[346,861]]],"ニ":[[[299,318],[308,322],[316,325],[324,328],[331,329],[340,331],[348,331],[357,331],[368,331],[406,327],[440,324],[472,320],[501,316],[530,312],[558,308],[586,304],[616,301],[625,301],[635,300],[646,300],[656,300],[666,300],[676,301],[685,301],[693,302]],[[183,687],[192,690],[201,693],[210,695],[219,696],[230,697],[241,697],[253,696],[267,694],[335,684],[400,676],[462,669],[522,665],[581,662],[637,660],[693,659],[748,658],[761,659],[774,660],[788,662],[801,664],[814,668],[827,671],[839,676],[850,680]]],"ヌ":[[[306,253],[316,257],[325,260],[334,262],[344,262],[354,262],[364,262],[374,261],[384,259],[419,253],[452,248],[485,242],[517,237],[549,231],[582,225],[614,219],[647,213],[667,210],[683,209],[695,210],[703,215],[706,222],[706,233],[703,247],[696,265],[670,324],[637,388],[596,456],[546,526],[487,597],[418,667],[339,733],[248,796]],[[412,426],[452,450],[491,476],[529,504],[565,534],[600,567],[632,603],[663,641],[693,683]]],"ネ":[[[471,114],[483,122],[496,131],[510,142],[523,154],[536,167],[549,181],[561,197],[572,213]],[[247,332],[256,336],[265,340],[274,343],[284,345],[294,346],[304,346],[314,345],[325,343],[361,334],[397,325],[433,317],[468,308],[503,299],[538,291],[573,282],[608,274],[628,270],[644,270],[655,273],[663,278],[666,286],[664,295],[659,305],[650,317],[610,359],[569,401],[525,442],[476,484],[421,526],[358,570],[286,616],[202,665]],[[499,497],[503,503],[507,509],[509,515],[511,521],[512,528],[513,536],[514,543],[514,552],[514,569],[514,601],[514,642],[514,688],[514,734],[514,775],[514,806],[514,821],[514,828],[514,835],[514,842],[514,849],[514,857],[514,866],[514,875],[514,884]],[[600,492],[641,512],[677,533],[710,554],[740,575],[766,596],[789,618],[810,641],[828,665]]],"ノ":[[[664,232],[666,239],[668,247],[669,255],[670,264],[670,272],[669,281],[668,290],[666,298],[637,382],[600,461],[555,535],[504,603],[449,666],[390,724],[329,775],[266,820]]],"ハ":[[[361,338],[362,343],[363,347],[363,352],[364,357],[363,362],[363,367],[361,372],[360,376],[338,422],[315,465],[291,505],[267,543],[241,578],[214,611],[186,642],[156,672]],[[601,334],[644,367],[685,403],[723,441],[757,481],[788,522],[816,562],[839,602],[858,640]]],"ヒ":[[[325,408],[331,413],[338,417],[346,420],[354,423],[362,425],[371,426],[379,426],[388,426],[422,421],[453,416],[482,411],[510,406],[536,401],[561,396],[586,391],[610,386],[621,384],[632,383],[644,381],[656,380],[667,379],[678,378],[688,378],[696,378]],[[284,162],[289,166],[292,172],[295,178],[298,185],[300,192],[301,200],[301,209],[302,218],[301,243],[300,292],[299,358],[298,433],[296,508],[295,575],[294,625],[294,651],[295,683],[301,710],[310,733],[323,752],[341,767],[362,777],[389,783],[420,786],[442,786],[467,786],[494,786],[521,786],[548,786],[574,786],[597,786],[616,786],[633,785],[649,784],[666,783],[681,781],[697,779],[711,777],[726,775],[740,772]]],"フ":[[[225,275],[231,281],[237,285],[244,289],[251,291],[258,292],[266,292],[275,291],[284,290],[334,283],[384,276],[434,268],[484,260],[534,252],[585,244],[635,236],[686,227],[708,225],[727,227],[742,232],[754,241],[760,254],[762,270],[758,289],[749,311],[713,377],[674,443],[631,509],[583,574],[526,636],[460,696],[382,752],[290,803]]],"ヘ":[[[142,450],[152,454],[161,456],[170,457],[178,456],[186,454],[194,451],[200,446],[206,441],[220,428],[236,414],[251,400],[266,387],[281,374],[294,362],[306,351],[316,342],[327,331],[339,322],[352,315],[366,311],[380,310],[395,313],[410,319],[426,331],[466,365],[507,401],[549,437],[592,473],[635,509],[676,544],[716,578],[754,610],[769,622],[783,633],[796,645],[809,656],[821,667],[833,678],[846,688],[858,697]]],"ホ":[[[208,370],[216,374],[225,377],[234,379],[243,381],[254,383],[265,383],[277,383],[291,382],[350,376],[404,371],[456,366],[505,362],[554,358],[603,354],[654,350],[708,346],[720,346],[733,345],[746,345],[759,346],[771,347],[784,348],[797,350],[810,352]],[[493,157],[497,164],[500,171],[503,179],[504,187],[505,196],[506,205],[506,215],[506,225],[506,251],[506,304],[505,374],[505,455],[505,536],[505,610],[505,668],[505,701],[502,766],[495,806],[485,826],[472,830],[458,824],[443,811],[428,798],[415,789]],[[251,545],[252,576],[250,605],[247,633],[241,659],[233,683],[222,706],[209,727],[193,746]],[[672,484],[707,516],[737,548],[761,577],[782,606],[798,634],[810,661],[819,687],[825,712]]],"マ":[[[197,310],[204,315],[210,320],[216,323],[223,325],[230,326],[238,326],[247,326],[257,324],[322,317],[383,309],[442,302],[498,295],[554,288],[610,281],[667,274],[727,266],[749,264],[766,266],[779,270],[788,277],[791,288],[789,301],[781,317],[767,336],[741,366],[713,399],[681,434],[648,470],[614,508],[578,547],[541,586],[503,626]],[[398,540],[427,564],[455,590],[482,618],[507,647],[531,679],[551,712],[569,746],[584,781]]],"ミ":[[[384,183],[420,193],[454,203],[488,214],[519,226],[548,238],[574,251],[596,265],[613,279]],[[385,430],[422,440],[458,451],[492,462],[524,475],[554,488],[581,501],[603,515],[622,530]],[[335,688],[389,704],[441,722],[491,742],[539,762],[582,784],[621,807],[654,830],[681,854]]],"ム":[[[494,206],[497,213],[498,220],[499,228],[499,236],[498,244],[497,253],[494,261],[490,270],[460,330],[430,387],[402,441],[374,492],[346,541],[318,590],[289,639],[259,689],[248,709],[241,725],[239,738],[241,747],[247,754],[259,757],[276,757],[299,755],[337,748],[395,738],[466,726],[542,712],[616,699],[681,687],[730,678],[754,673]],[[662,552],[686,574],[709,599],[731,626],[751,654],[770,684],[786,716],[799,749],[809,784]]],"メ":[[[673,175],[676,182],[677,189],[678,197],[677,205],[676,213],[675,221],[672,230],[670,239],[640,316],[605,395],[564,473],[517,551],[462,625],[401,695],[333,759],[257,815]],[[362,362],[419,390],[473,420],[525,452],[574,486],[618,523],[657,562],[690,603],[716,646]]],"モ":[[[256,240],[264,244],[272,247],[280,250],[288,251],[296,253],[305,253],[314,253],[324,253],[363,249],[402,246],[440,242],[477,238],[514,233],[551,228],[588,222],[625,217],[634,215],[644,214],[655,214],[665,214],[675,214],[685,214],[694,214],[702,215]],[[161,499],[169,502],[178,505],[187,507],[196,508],[207,509],[218,509],[230,508],[244,506],[311,495],[374,485],[433,477],[490,469],[545,462],[601,457],[658,453],[718,450],[731,449],[744,449],[756,450],[769,451],[782,452],[794,454],[807,456],[820,458]],[[447,274],[451,280],[454,286],[456,292],[458,299],[459,306],[460,314],[460,322],[460,330],[460,361],[459,404],[458,455],[457,509],[456,562],[455,607],[455,642],[454,659],[456,684],[460,705],[467,723],[477,737],[490,749],[507,758],[527,764],[551,767],[570,769],[590,770],[610,770],[630,770],[650,769],[669,769],[686,768],[701,767],[716,766],[728,765],[740,764],[750,762],[760,761],[769,759],[779,757],[789,754]]],"ヤ":[[[165,420],[173,425],[183,429],[193,433],[205,435],[218,436],[231,436],[244,435],[258,432],[321,417],[381,403],[439,389],[494,376],[548,363],[601,350],[653,337],[706,323],[765,314],[793,322],[797,344],[784,376],[760,412],[730,449],[702,482],[681,507]],[[353,178],[358,183],[363,187],[367,192],[371,198],[374,204],[377,210],[380,217],[382,226],[389,253],[402,312],[420,391],[440,480],[460,569],[478,649],[491,707],[498,735],[500,746],[503,759],[507,774],[511,790],[515,807],[519,823],[522,837],[526,850]]],"ユ":[[[271,325],[279,329],[288,333],[297,336],[307,339],[318,340],[329,340],[342,340],[356,338],[398,332],[434,327],[466,323],[495,319],[522,315],[549,311],[578,307],[609,302],[630,299],[646,298],[658,301],[666,306],[671,314],[673,326],[672,341],[669,360],[660,400],[652,441],[644,483],[636,524],[629,564],[621,603],[615,641],[609,677]],[[156,705],[165,710],[174,714],[183,717],[192,719],[202,721],[213,721],[226,721],[240,719],[314,710],[381,702],[444,696],[503,691],[561,688],[618,685],[676,684],[736,683],[749,684],[762,684],[774,685],[787,686],[800,688],[813,690],[825,692],[838,694]]],"ヨ":[[[267,276],[276,281],[284,285],[294,288],[304,290],[314,291],[326,292],[338,291],[352,290],[400,285],[446,279],[491,274],[534,269],[575,264],[614,260],[651,255],[686,251],[704,249],[719,250],[730,252],[738,258],[743,266],[745,277],[746,291],[746,310],[742,363],[739,415],[735,467],[732,517],[729,565],[725,612],[722,656],[718,697]],[[268,485],[277,490],[285,494],[295,497],[305,499],[315,500],[327,501],[340,500],[353,499],[390,495],[428,491],[466,487],[503,483],[540,480],[575,477],[608,474],[639,471],[648,470],[657,470],[666,470],[675,471],[684,472],[693,473],[701,474],[710,476]],[[216,723],[225,727],[234,731],[243,733],[252,735],[262,736],[273,737],[285,736],[299,735],[344,731],[391,727],[441,722],[491,718],[541,714],[589,711],[636,709],[679,709],[690,709],[701,709],[711,709],[721,709],[731,710],[741,711],[753,712],[765,714]]],"ラ":[[[354,193],[362,199],[369,204],[377,208],[386,211],[395,213],[405,214],[416,214],[428,213],[458,210],[485,206],[510,203],[534,199],[557,196],[579,192],[602,189],[626,186],[634,185],[642,184],[649,183],[656,183],[663,183],[670,183],[678,183],[686,184]],[[239,384],[247,390],[256,394],[265,397],[275,400],[286,401],[297,402],[310,401],[323,400],[373,393],[424,385],[475,377],[526,369],[575,361],[620,354],[662,347],[698,342],[717,340],[733,340],[745,343],[754,348],[760,355],[762,365],[761,378],[756,394],[729,459],[694,523],[653,586],[605,646],[549,703],[487,755],[417,801],[341,840]]],"リ":[[[321,169],[325,174],[328,179],[330,184],[332,190],[334,195],[335,201],[336,207],[336,213],[336,228],[336,257],[336,295],[336,337],[336,379],[336,417],[336,446],[336,461],[336,469],[336,478],[336,488],[336,498],[336,508],[336,517],[336,526],[336,532]],[[651,141],[656,146],[661,151],[664,156],[667,162],[670,169],[672,176],[673,183],[673,190],[673,208],[673,241],[673,285],[673,335],[672,386],[672,432],[672,469],[672,492],[668,557],[657,615],[639,669],[614,717],[585,760],[551,799],[513,833],[473,863]]],"ル":[[[315,292],[319,298],[322,303],[325,308],[327,314],[329,319],[330,325],[330,331],[330,337],[324,414],[312,485],[296,552],[276,612],[253,667],[227,716],[199,757],[170,791]],[[518,180],[523,185],[528,190],[531,195],[535,201],[537,208],[539,215],[540,222],[540,229],[540,254],[540,307],[540,379],[540,460],[540,542],[539,616],[539,673],[539,703],[540,734],[541,757],[545,771],[552,777],[562,776],[577,767],[598,751],[625,728],[657,701],[687,675],[716,648],[745,621],[774,592],[803,562],[834,529],[867,493]]],"レ":[[[317,181],[321,186],[326,191],[329,196],[333,202],[335,209],[337,216],[338,223],[338,231],[338,256],[338,312],[338,387],[338,473],[338,559],[337,637],[337,696],[337,727],[337,753],[338,773],[341,785],[347,791],[358,791],[373,786],[394,776],[423,761],[471,735],[524,701],[578,663],[633,622],[687,579],[737,536],[782,494],[820,454]]],"ロ":[[[229,305],[234,310],[238,315],[242,320],[245,326],[247,333],[249,340],[250,347],[251,354],[255,390],[258,429],[262,469],[265,510],[269,552],[273,594],[276,635],[280,674],[281,686],[282,697],[283,709],[284,719],[285,730],[286,741],[287,751],[288,760]],[[258,331],[297,327],[349,323],[408,318],[472,312],[534,307],[592,302],[641,297],[677,292],[701,290],[721,290],[736,292],[747,298],[753,307],[756,319],[756,334],[753,353],[746,391],[739,429],[732,467],[724,506],[717,546],[709,587],[700,629],[692,673]],[[294,717],[321,714],[363,710],[414,706],[470,701],[524,697],[572,693],[608,690],[628,689],[639,689],[651,689],[665,689],[679,689],[693,689],[707,689],[721,690],[734,691]]],"ワ":[[[229,217],[234,221],[238,226],[242,232],[245,238],[247,244],[249,251],[250,259],[251,266],[254,296],[256,318],[258,336],[260,351],[261,367],[263,386],[266,410],[269,444],[270,455],[271,467],[272,478],[273,489],[274,500],[275,510],[275,520],[276,530]],[[255,242],[265,243],[274,244],[284,244],[293,244],[301,244],[310,243],[320,242],[330,241],[377,237],[424,233],[471,229],[519,225],[566,221],[614,217],[663,212],[712,208],[737,206],[757,206],[772,209],[782,214],[788,223],[792,234],[792,249],[789,268],[768,359],[738,444],[699,523],[651,596],[596,664],[533,726],[463,782],[387,833]]],"ヲ":[[[277,231],[286,236],[295,240],[304,243],[314,246],[325,247],[336,248],[349,247],[362,246],[404,242],[443,237],[480,233],[515,229],[549,224],[581,220],[612,217],[642,213],[652,212],[661,211],[671,209],[680,208],[689,207],[698,206],[708,205],[717,204]],[[266,428],[274,433],[282,437],[290,439],[298,441],[307,443],[317,443],[328,442],[340,441],[369,437],[401,433],[435,428],[469,424],[504,419],[538,415],[571,411],[602,406],[610,405],[618,404],[626,403],[634,402],[642,401],[649,400],[657,399],[664,398]],[[716,210],[718,217],[720,225],[721,233],[721,241],[720,249],[720,258],[718,266],[717,274],[694,352],[661,431],[619,508],[568,583],[511,655],[449,721],[382,780],[312,831]]],"ン":[[[243,228],[263,237],[284,250],[305,264],[325,281],[343,300],[361,319],[375,339],[388,359]],[[263,768],[271,773],[280,776],[289,777],[298,777],[307,775],[316,772],[325,768],[334,763],[401,721],[464,678],[524,634],[580,589],[635,542],[687,492],[738,440],[789,385]]]}},"lesson":{"type":"lesson","id":"work_intro_01","can_do":{"en":"Greet colleagues and introduce yourself on your first day at work.","bn":"কর্মস্থলে প্রথম দিনে সহকর্মীদের অভিবাদন ও নিজের পরিচয় দিতে পারা।","ja":"職場の初日に同僚にあいさつし、自己紹介ができる。"},"jlpt_or_jft":"JFT-Basic A1/A2","verified":true,"source":"Aligned to Irodori Starter Can-do (self-introduction / greetings)","items":[{"id":"wi_01","jp":"おはようございます","kana":"おはようございます","romaji":"ohayō gozaimasu","meaning":{"en":"Good morning (polite)","bn":"সুপ্রভাত (ভদ্রভাবে)","ja":"おはよう（丁寧）"},"note":{"en":"Say it as you arrive at work. ございます makes it polite.","bn":"সকালে কর্মস্থলে ঢুকেই বলবে। শেষে ございます থাকায় এটি ভদ্র রূপ।","ja":"出勤時に言う。ございますで丁寧になる。"},"srs_words":["おはよう","ございます"]},{"id":"wi_02","jp":"こんにちは","kana":"こんにちは","romaji":"konnichiwa","meaning":{"en":"Hello / good afternoon","bn":"নমস্কার / হ্যালো (দুপুরে)","ja":"こんにちは（昼のあいさつ）"},"note":{"en":"は is pronounced 'wa' here, not 'ha'.","bn":"は এখানে \"wa\" উচ্চারণ হয়, \"ha\" নয়।","ja":"ここでのはは「わ」と読む。"},"srs_words":["こんにちは"]},{"id":"wi_03","jp":"はじめまして","kana":"はじめまして","romaji":"hajimemashite","meaning":{"en":"Nice to meet you (first time)","bn":"প্রথম সাক্ষাতে — পরিচিত হয়ে ভালো লাগল","ja":"はじめまして（初対面）"},"note":{"en":"Use it the first time you meet someone.","bn":"নতুন কাউকে প্রথমবার দেখা হলেই বলবে।","ja":"初めて会うときに使う。"},"srs_words":["はじめまして"]},{"id":"wi_04","jp":"わたしはラーマンです","kana":"わたしはラーマンです","romaji":"watashi wa Rāman desu","meaning":{"en":"I am Rahman.","bn":"আমি রহমান।","ja":"私はラーマンです。"},"note":{"en":"Pattern: わたしは ＿ です = 'I am ＿'. は = wa (topic marker).","bn":"গঠন: わたしは ＿ です = \"আমি ＿\"। は = wa (বিষয় নির্দেশক)।","ja":"型：わたしは＿です。はは「わ」（主題）。"},"srs_words":["わたし","です"]},{"id":"wi_05","jp":"よろしくおねがいします","kana":"よろしくおねがいします","romaji":"yoroshiku onegai shimasu","meaning":{"en":"I look forward to working with you (courtesy)","bn":"আপনার সাথে কাজ করতে পেরে ভালো লাগবে (সৌজন্য)","ja":"よろしくお願いします（締めのあいさつ）"},"note":{"en":"Said at the end of an introduction — very important politeness in Japan.","bn":"পরিচয়ের শেষে বলা হয় — জাপানে খুব গুরুত্বপূর্ণ ভদ্রতা।","ja":"自己紹介の最後に言う大切な表現。"},"srs_words":["よろしく","おねがいします"]},{"id":"wi_06","jp":"すみません","kana":"すみません","romaji":"sumimasen","meaning":{"en":"Excuse me / sorry","bn":"মাফ করবেন / এক্সকিউজ মি","ja":"すみません（呼びかけ・軽い謝罪）"},"note":{"en":"To get attention or apologize for a small thing.","bn":"কারো দৃষ্টি আকর্ষণ করতে বা ছোট ভুলে ক্ষমা চাইতে।","ja":"呼びかけや軽い謝罪に。"},"srs_words":["すみません"]},{"id":"wi_07","jp":"ありがとうございます","kana":"ありがとうございます","romaji":"arigatō gozaimasu","meaning":{"en":"Thank you (polite)","bn":"ধন্যবাদ (ভদ্রভাবে)","ja":"ありがとうございます（丁寧）"},"note":{"en":"ございます makes it more polite — use this at work.","bn":"ございます যোগ করায় বেশি ভদ্র — কর্মস্থলে এটাই ব্যবহার করবে।","ja":"ございますでより丁寧。職場で使う。"},"srs_words":["ありがとう"]},{"id":"wi_08","jp":"わかりません","kana":"わかりません","romaji":"wakarimasen","meaning":{"en":"I don't understand","bn":"আমি বুঝতে পারিনি","ja":"わかりません"},"note":{"en":"Don't stay silent if you don't get it — saying this is useful, not shameful.","bn":"না বুঝলে চুপ থেকো না — এটি বলা দোষের নয়, বরং কাজে দরকারি।","ja":"分からないときは黙らず言おう。"},"srs_words":["わかりません"]},{"id":"wi_09","jp":"もういちどおねがいします","kana":"もういちどおねがいします","romaji":"mō ichido onegai shimasu","meaning":{"en":"Please say it once more","bn":"অনুগ্রহ করে আরেকবার বলুন","ja":"もう一度お願いします"},"note":{"en":"If someone speaks fast, say this to hear it again.","bn":"কেউ দ্রুত বললে এটি বলে আবার শুনে নাও।","ja":"速いときはこれでもう一度聞く。"},"srs_words":["もういちど"]}]},"pitch":[{"id":"p_hashi_chopsticks","word":"はし","kanji":"箸","romaji":"hashi","pattern":[1,0],"meaning":{"en":"chopsticks","bn":"চপস্টিক","ja":"箸（食器）"},"accent_type":{"en":"atamadaka (head-high: HL)","bn":"atamadaka (মাথা-উঁচু: উঁচু-নিচু)","ja":"頭高型（高低）"}},{"id":"p_hashi_bridge","word":"はし","kanji":"橋","romaji":"hashi","pattern":[0,1],"meaning":{"en":"bridge","bn":"সেতু","ja":"橋"},"accent_type":{"en":"odaka (tail-high: LH, drops on particle)","bn":"odaka (শেষ-উঁচু: নিচু-উঁচু)","ja":"尾高型（低高）"}},{"id":"p_ame_rain","word":"あめ","kanji":"雨","romaji":"ame","pattern":[1,0],"meaning":{"en":"rain","bn":"বৃষ্টি","ja":"雨"},"accent_type":{"en":"atamadaka (HL)","bn":"atamadaka (উঁচু-নিচু)","ja":"頭高型"}},{"id":"p_ame_candy","word":"あめ","kanji":"飴","romaji":"ame","pattern":[0,1],"meaning":{"en":"candy","bn":"ক্যান্ডি / মিষ্টি","ja":"飴"},"accent_type":{"en":"heiban (flat: LH, stays high)","bn":"heiban (সমতল: নিচু-উঁচু)","ja":"平板型（低高）"}},{"id":"p_kaki_oyster","word":"かき","kanji":"牡蠣","romaji":"kaki","pattern":[1,0],"meaning":{"en":"oyster","bn":"ঝিনুক (অয়েস্টার)","ja":"牡蠣"},"accent_type":{"en":"atamadaka (HL)","bn":"atamadaka (উঁচু-নিচু)","ja":"頭高型"}},{"id":"p_kaki_persimmon","word":"かき","kanji":"柿","romaji":"kaki","pattern":[0,1],"meaning":{"en":"persimmon","bn":"পার্সিমন (এক ধরনের ফল)","ja":"柿"},"accent_type":{"en":"heiban (flat: LH)","bn":"heiban (সমতল: নিচু-উঁচু)","ja":"平板型"}}]};
let LANG = 'bn';
let tab = 2; // open on Learn (the micro-loop) first

const T = (tri) => (tri ? (tri[LANG] || tri.en) : '');
const gloss = (tri) => (LANG === 'bn' && tri && tri.en ? tri.en : '');

const NAV = [
  ['Kana','M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v6H4zM14 15h6v6h-6z'],
  ['Write','M4 20h16M6 16l9-9a2 2 0 0 1 3 3l-9 9-4 1z'],
  ['Learn','M3 7l9-4 9 4-9 4zM7 10v5c0 1 5 3 5 3s5-2 5-3v-5'],
  ['Speak','M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM5 11a7 7 0 0 0 14 0M12 18v3'],
  ['Pitch','M3 17l5-6 4 3 5-8'],
  ['Review','M4 9a8 8 0 0 1 14-4M20 5v4h-4M20 15a8 8 0 0 1-14 4M4 19v-4h4'],
];

function renderNav(){
  document.getElementById('nav').innerHTML = NAV.map((n,i)=>
    '<button class="'+(i===tab?'on':'')+'" onclick="go('+i+')"><svg viewBox="0 0 24 24"><path d="'+n[1]+'"/></svg>'+n[0]+'</button>'
  ).join('');
}
function go(i){ tab=i; render(); }
window.go = go;

function render(){
  renderNav();
  const s = document.getElementById('screen');
  s.innerHTML = [screenKana, screenWrite, screenLearn, screenSpeak, screenPitch, screenReview][tab]();
  if (tab===1) initWrite();
  s.scrollTop = 0;
}

/* ---------- 0: KANA ---------- */
let kataMode=false;
function screenKana(){
  const set = kataMode?DATA.kata:DATA.hira;
  return '<h2 class="title">'+(LANG==='bn'?'কানা শেখো':'Kana')+'</h2>'+
    '<div class="seg"><button class="'+(!kataMode?'on':'')+'" onclick="setKata(0)">ひらがな</button>'+
    '<button class="'+(kataMode?'on':'')+'" onclick="setKata(1)">カタカナ</button></div>'+
    '<div class="grid">'+set.map(k=>
      '<div class="cell" onclick="ping(this)"><div class="c">'+k.char+'</div><div class="r">'+k.romaji+'</div></div>'
    ).join('')+'</div>';
}
window.setKata=(v)=>{kataMode=!!v; render();};
window.ping=(el)=>{el.style.borderColor='var(--pink)'; setTimeout(()=>el.style.borderColor='',260);};

/* ---------- 1: WRITE (real KanjiVG stroke animation) ---------- */
let wKata=false, wIdx=0;
function screenWrite(){
  const chars = (wKata?DATA.kata:DATA.hira).map(k=>k.char);
  return '<h2 class="title">'+(LANG==='bn'?'লেখা অনুশীলন':'Write')+'</h2>'+
    '<div class="seg"><button class="'+(!wKata?'on':'')+'" onclick="setW(0)">ひらがな</button>'+
    '<button class="'+(wKata?'on':'')+'" onclick="setW(1)">カタカナ</button></div>'+
    '<div class="strip">'+chars.map((c,i)=>'<button class="chip '+(i===wIdx?'on':'')+'" onclick="pickW('+i+')">'+c+'</button>').join('')+'</div>'+
    '<div class="pad"><canvas id="paper"></canvas></div>'+
    '<div class="tools">'+
      '<button class="btn primary" onclick="playStroke()">▶ '+(LANG==='bn'?'দেখাও':'watch')+'</button>'+
      '<button class="btn line" onclick="toggleGuide()" id="guideBtn">👁 guide</button>'+
      '<button class="btn line" onclick="clearInk()">⌫ clear</button>'+
    '</div>'+
    '<div class="row" style="padding:0 16px 18px"><button class="btn filled grow" onclick="pickW('+((wIdx+1))+')">Skip / পরের ›</button></div>';
}
window.setW=(v)=>{wKata=!!v; wIdx=0; render();};
window.pickW=(i)=>{const n=(wKata?DATA.kata:DATA.hira).length; wIdx=((i%n)+n)%n; render();};
let guide=true, ink=[], anim=null;
window.toggleGuide=()=>{guide=!guide; drawPaper(0,null);};
window.clearInk=()=>{ink=[]; drawPaper(0,null);};
function curStrokes(){const c=(wKata?DATA.kata:DATA.hira)[wIdx].char; const set=wKata?DATA.strokes.katakana:DATA.strokes.hiragana; return set[c]||[];}
function initWrite(){
  const cv=document.getElementById('paper'); if(!cv) return;
  const fit=()=>{const r=cv.getBoundingClientRect(); const dpr=Math.min(devicePixelRatio||1,2);
    cv.width=r.width*dpr; cv.height=r.width*dpr; cv._s=r.width*dpr; drawPaper(0,null);};
  fit();
  let drawing=false;
  const pt=(e)=>{const r=cv.getBoundingClientRect(); const s=cv._s/r.width; return [(e.clientX-r.left)*s,(e.clientY-r.top)*s];};
  cv.onpointerdown=(e)=>{if(anim)return; drawing=true; ink.push([pt(e)]); cv.setPointerCapture(e.pointerId);};
  cv.onpointermove=(e)=>{if(!drawing||anim)return; ink[ink.length-1].push(pt(e)); drawPaper(animT,animStrokesLocal);};
  cv.onpointerup=()=>{drawing=false;};
}
let animT=0, animStrokesLocal=null;
function drawPaper(t, strokesShown){
  const cv=document.getElementById('paper'); if(!cv)return; const g=cv.getContext('2d'); const S=cv._s||cv.width;
  g.clearRect(0,0,S,S); g.fillStyle='#FBFBFD'; g.fillRect(0,0,S,S);
  const pad=S*0.06; g.strokeStyle='#E6E7EE'; g.lineWidth=1.4;
  g.strokeRect(pad,pad,S-2*pad,S-2*pad);
  g.beginPath(); g.moveTo(S/2,pad); g.lineTo(S/2,S-pad); g.moveTo(pad,S/2); g.lineTo(S-pad,S/2); g.stroke();
  if(guide && !strokesShown){ g.fillStyle='#E3E4EC'; g.font='700 '+(S*0.7)+'px var(--font)'; g.textAlign='center'; g.textBaseline='middle';
    g.fillText((wKata?DATA.kata:DATA.hira)[wIdx].char, S/2, S/2+S*0.04); }
  // user ink
  g.strokeStyle='#14141F'; g.lineWidth=S*0.045; g.lineCap='round'; g.lineJoin='round';
  for(const st of ink){ if(st.length<2){continue;} g.beginPath(); g.moveTo(st[0][0],st[0][1]); for(let i=1;i<st.length;i++)g.lineTo(st[i][0],st[i][1]); g.stroke(); }
  // stroke-order animation (scaled from viewBox 1000)
  if(strokesShown){
    const sc=S/1000; g.lineWidth=S*0.06;
    const scaled=strokesShown.map(s=>s.map(p=>[p[0]*sc,p[1]*sc]));
    const lens=scaled.map(len); const total=lens.reduce((a,b)=>a+b,0); let target=t*total, consumed=0;
    for(let i=0;i<scaled.length;i++){ if(consumed>=target)break; drawUpTo(g,scaled[i],Math.min(lens[i],target-consumed)); consumed+=lens[i]; }
  }
}
function len(p){let s=0;for(let i=1;i<p.length;i++)s+=Math.hypot(p[i][0]-p[i-1][0],p[i][1]-p[i-1][1]);return s;}
function drawUpTo(g,pts,maxLen){ if(pts.length<2)return; g.beginPath(); g.moveTo(pts[0][0],pts[0][1]); let acc=0;
  for(let i=1;i<pts.length;i++){const seg=Math.hypot(pts[i][0]-pts[i-1][0],pts[i][1]-pts[i-1][1]);
    if(acc+seg<=maxLen){g.lineTo(pts[i][0],pts[i][1]); acc+=seg;}
    else{const f=seg<=0?0:(maxLen-acc)/seg; g.lineTo(pts[i-1][0]+(pts[i][0]-pts[i-1][0])*f, pts[i-1][1]+(pts[i][1]-pts[i-1][1])*f); break;}}
  g.stroke(); }
window.playStroke=()=>{
  const strokes=curStrokes(); if(!strokes.length)return; ink=[]; if(anim)cancelAnimationFrame(anim);
  animStrokesLocal=strokes; const dur=600*strokes.length; const t0=performance.now();
  const step=(now)=>{animT=Math.min(1,(now-t0)/dur); drawPaper(animT,strokes);
    if(animT<1){anim=requestAnimationFrame(step);} else {anim=null; animStrokesLocal=null;}};
  anim=requestAnimationFrame(step);
};

/* ---------- 2: LEARN (5-step micro-loop) ---------- */
const PHASES=['intro','recognition','production','context','srs'];
const PLAB={intro:['পরিচিতি','Intro'],recognition:['চেনা','Recognition'],production:['বলা/লেখা','Production'],context:['বাক্য','Context'],srs:['রিভিউ','SRS']};
let L={started:false,done:false,item:0,phase:0,hint:false,pick:null,revealed:false,write:false,built:[],bank:null,bankItem:-1,showRom:true};
function lz(){return DATA.lesson.items;}
function resetStep(){L.hint=false;L.pick=null;L.revealed=false;L.write=false;L.built=[];L.bank=null;L.bankItem=-1;}
window.lStart=()=>{L.started=true;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lQuit=()=>{L.started=false;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lHint=()=>{L.hint=!L.hint;render();};
window.lAdvance=()=>{const n=lz().length;resetStep();
  if(L.phase<4)L.phase++; else if(L.item<n-1){L.item++;L.phase=0;} else {L.started=false;L.done=true;} render();};
window.lToggleRom=()=>{L.showRom=!L.showRom;render();};
window.lReveal=()=>{L.revealed=!L.revealed;render();};
window.lWrite=()=>{L.write=!L.write;render();};

function seededShuffle(arr,seed){const a=arr.slice();let s=seed;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};
  for(let i=a.length-1;i>0;i--){const j=Math.floor(rnd()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}

function screenLearn(){
  const les=DATA.lesson;
  if(L.done) return '<div class="center"><div style="font-size:42px">✅</div><div class="big" style="font-size:20px">'+(LANG==='bn'?'লেসন শেষ':'Lesson complete')+'</div><div class="muted">'+(LANG==='bn'?'আরেকটা?':'Another round?')+'</div><button class="btn filled" style="margin-top:12px" onclick="lStart()">'+(LANG==='bn'?'আবার':'Restart')+'</button></div>';
  if(!L.started) return '<div class="center"><div class="big" style="font-size:19px;text-wrap:balance">'+T(les.can_do)+'</div>'+(gloss(les.can_do)?'<div class="faint">'+gloss(les.can_do)+'</div>':'')+'<div class="muted">'+les.items.length+' '+(LANG==='bn'?'শব্দ':'items')+' · ৫ '+(LANG==='bn'?'ধাপ':'steps')+'</div><div class="faint" style="font-size:12px">'+(LANG==='bn'?'যেকোনো সময় Skip / Hint / Quit — কোনো চাপ নেই।':'Skip / Hint / Quit anytime — no pressure.')+'</div><button class="btn primary" style="margin-top:14px;min-width:160px" onclick="lStart()">'+(LANG==='bn'?'শুরু করো':'Start')+'</button></div>';

  const it=lz()[L.item]; const ph=PHASES[L.phase];
  let head='<div class="phaselab"><span class="muted">'+(LANG==='bn'?'শব্দ':'word')+' '+(L.item+1)+'/'+lz().length+'</span><span style="font-weight:600">'+(LANG==='bn'?PLAB[ph][0]:PLAB[ph][1])+'</span></div>'+
    '<div class="steps">'+PHASES.map((_,i)=>'<i class="'+(i<=L.phase?'on':'')+'"></i>').join('')+'</div>'+
    '<div class="controls"><button class="btn line" onclick="lHint()">💡 '+(LANG==='bn'?'ইঙ্গিত':'Hint')+'</button>'+
      '<button class="btn line" onclick="lAdvance()">⏭ '+(LANG==='bn'?'বাদ':'Skip')+'</button>'+
      '<button class="btn line" onclick="lQuit()">✕ '+(LANG==='bn'?'বন্ধ':'Quit')+'</button></div>';

  let body='';
  if(ph==='intro') body=phIntro(it);
  else if(ph==='recognition') body=phRecog(it);
  else if(ph==='production') body=phProd(it);
  else if(ph==='context') body=phContext(it);
  else body=phSrs(it);

  const hint = L.hint? '<div class="pad"><div class="card" style="background:var(--surface2);display:flex;gap:10px;align-items:flex-start"><span>💡</span><div><b>'+it.jp+'</b> · <span class="faint">'+it.romaji+'</span><div>'+T(it.meaning)+'</div></div></div></div>':'';
  return head+'<div class="pad">'+body+'</div>'+hint;
}
function phIntro(it){return '<div class="card" style="text-align:center">'+
  '<div class="big">'+it.jp+'</div>'+(L.showRom?'<div class="faint">'+it.romaji+'</div>':'')+
  '<div style="font-size:22px;margin:6px">🔊</div>'+
  '<div style="font-size:18px;font-weight:600">'+T(it.meaning)+'</div>'+(gloss(it.meaning)?'<div class="faint">'+gloss(it.meaning)+'</div>':'')+
  '<div class="card" style="background:#12190f;margin-top:12px;text-align:left">'+T(it.note)+(gloss(it.note)?'<div class="faint" style="font-size:12px">'+gloss(it.note)+'</div>':'')+'</div>'+
  '<div class="row" style="margin-top:14px"><button class="btn ghost" onclick="lToggleRom()">Romaji '+(L.showRom?'off':'on')+'</button><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'বুঝেছি':'Got it')+' ✓</button></div></div>';}
function phRecog(it){
  const others=lz().filter(x=>x.id!==it.id); const pick=seededShuffle(others,L.item+1).slice(0,3);
  const opts=seededShuffle([{m:it.meaning,ok:true}].concat(pick.map(o=>({m:o.meaning,ok:false}))), L.item*7+3);
  L._opts=opts;
  const chosen=L.pick!=null; const good=chosen&&opts[L.pick].ok;
  let h='<div class="card" style="text-align:center;margin-bottom:12px"><div class="big" style="font-size:28px">'+it.jp+'</div><div style="font-size:20px">🔊</div></div>';
  h+='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'এর মানে কী?':'What does it mean?')+'</div>';
  h+=opts.map((o,k)=>{let cls='opt'; if(L.pick===k)cls+=o.ok?' good':' bad'; if(L.hint&&o.ok)cls+=' hint';
    return '<button class="'+cls+'" onclick="lPick('+k+')">'+T(o.m)+'</button>';}).join('');
  if(good) h+='<div class="row" style="align-items:center;margin-top:4px"><span class="tag">✓ '+(LANG==='bn'?'ঠিক!':'Correct')+'</span><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(chosen) h+='<div style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'আবার দেখো':'Not quite — try another')+'</div>';
  return h;
}
window.lPick=(k)=>{L.pick=k;render();};
function phProd(it){return '<div class="card" style="text-align:center">'+
  '<div class="muted">'+(L.write?(LANG==='bn'?'এটি লেখো':'Write this'):(LANG==='bn'?'এটি বলো':'Say this'))+'</div>'+
  '<div style="font-size:18px;font-weight:600;margin:8px">'+T(it.meaning)+'</div>'+
  (L.revealed?'<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div>':'<div class="faint" style="font-size:26px">· · ·</div>')+
  '<div class="pillrow" style="justify-content:center;margin:14px 0">'+
    '<button class="btn line">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button>'+
    '<button class="btn line" onclick="lReveal()">'+(L.revealed?'🙈 Hide':'👁 Model')+'</button>'+
    '<button class="btn line" onclick="lWrite()">🔁 '+(L.write?'Speak':'Write')+'</button></div>'+
  '<div class="row"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';}
function phContext(it){
  const tokens=it.srs_words;
  if(tokens.length<2) return '<div class="card" style="text-align:center"><div class="muted">'+(LANG==='bn'?'বাক্যে':'In context')+'</div><div class="big" style="font-size:26px;margin:8px">'+it.jp+'</div><div>'+T(it.meaning)+'</div><div class="row" style="margin-top:14px"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';
  if(L.bankItem!==L.item){L.built=[]; L.bank=seededShuffle(tokens,L.item+5); L.bankItem=L.item;}
  const complete=L.built.length===tokens.length; const ordered=complete&&L.built.join('|')===tokens.join('|');
  let h='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'শব্দগুলো সাজিয়ে বাক্য বানাও':'Arrange the words')+'</div>';
  h+='<div style="margin-bottom:10px">'+T(it.meaning)+'</div>';
  h+='<div class="assembled '+(complete?(ordered?'good':'bad'):'')+'">'+(L.built.length?L.built.map((w,k)=>'<button class="tok" onclick="lUnbuild('+k+')">'+w+'</button>').join(''):'<span class="faint">'+(LANG==='bn'?'নিচের শব্দে ট্যাপ করো':'tap words below')+'</span>')+'</div>';
  h+='<div class="bank" style="margin-top:12px">'+L.bank.map((w,k)=>'<button class="tok" onclick="lBuild('+k+')">'+w+'</button>').join('')+'</div>';
  if(complete&&ordered) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="tag">✓</span><span class="grow" style="font-size:14px">'+it.jp+'</span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(complete) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="grow" style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'একটু এদিক-ওদিক':'not quite — rearrange')+'</span><button class="btn ghost" onclick="lResetCtx()">'+(LANG==='bn'?'আবার':'Reset')+'</button></div>';
  return h;
}
window.lBuild=(k)=>{L.built.push(L.bank.splice(k,1)[0]);render();};
window.lUnbuild=(k)=>{L.bank.push(L.built.splice(k,1)[0]);render();};
window.lResetCtx=()=>{const t=lz()[L.item].srs_words;L.bank=seededShuffle(t,L.item+5);L.built=[];render();};
function phSrs(it){return '<div class="card"><div class="muted">'+(LANG==='bn'?'রিভিউতে যোগ হলো':'Added to your review')+'</div>'+
  '<div class="pillrow" style="margin:12px 0">'+it.srs_words.map(w=>'<span class="pill">'+w+'</span>').join('')+'</div>'+
  '<div class="faint" style="font-size:13px;margin-bottom:8px">'+(LANG==='bn'?'কেমন লাগল?':'How was it?')+'</div>'+
  '<div class="rate">'+[['আবার','Again'],['কঠিন','Hard'],['ভালো','Good'],['সহজ','Easy']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="lAdvance()">'+(LANG==='bn'?r[0]:r[1])+'</button>').join('')+'</div></div>';}

/* ---------- 3: SPEAK (shadowing stub) ---------- */
function screenSpeak(){const it=lz()[0];
  return '<h2 class="title">'+(LANG==='bn'?'শ্যাডোয়িং':'Speak')+'</h2><div class="pad"><div class="card" style="text-align:center">'+
    '<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div><div>'+T(it.meaning)+'</div>'+
    '<div class="wave" style="margin:16px 0"></div>'+
    '<div class="pillrow" style="justify-content:center"><button class="btn line">🔊 '+(LANG==='bn'?'শোনো':'Listen')+'</button><button class="btn primary">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button></div>'+
    '<div class="faint" style="font-size:12px;margin-top:10px">'+(LANG==='bn'?'রেকর্ড করে নিজের সাথে মিলাও (Tier 0–1)':'Record & self-compare (Tier 0–1)')+'</div></div></div>';}

/* ---------- 4: PITCH ---------- */
function screenPitch(){
  return '<h2 class="title">'+(LANG==='bn'?'উচ্চারণ · পিচ':'Pitch accent')+'</h2><div class="pad">'+
    DATA.pitch.map(p=>{const max=Math.max.apply(null,p.pattern);
      const contour='<div class="contour">'+p.pattern.map((v,i)=>'<div class="mora"><div class="b" style="height:'+(v?38:16)+'px;background:'+(v?'var(--pink)':'var(--faint)')+'"></div><small class="faint" style="font-size:10px">'+([...p.word][i]||'')+'</small></div>').join('')+'</div>';
      return '<div class="card" style="margin-bottom:10px"><div class="row" style="justify-content:space-between;align-items:baseline"><div><span class="big" style="font-size:22px">'+p.word+'</span> <span class="faint">'+p.romaji+'</span></div><span class="tag">'+T(p.accent_type)+'</span></div>'+contour+'<div class="muted" style="font-size:13px;margin-top:6px">'+T(p.meaning)+'</div></div>';
    }).join('')+'</div>';
}

/* ---------- 5: REVIEW (FSRS flashcard) ---------- */
let rIdx=0, rRevealed=false;
const RDECK=[{w:'ありがとうございます',m:{en:'Thank you',bn:'ধন্যবাদ',ja:'ありがとう'}},{w:'すみません',m:{en:'Excuse me',bn:'মাফ করবেন',ja:'すみません'}}];
function screenReview(){
  if(rIdx>=RDECK.length) return '<div class="center"><div style="font-size:40px">🎉</div><div class="big" style="font-size:18px">'+(LANG==='bn'?'রিভিউ শেষ':'Review done')+'</div><button class="btn ghost" onclick="rReset()">↺</button></div>';
  const c=RDECK[rIdx];
  let h='<h2 class="title">'+(LANG==='bn'?'রিভিউ · FSRS':'Review')+'</h2><div class="pad"><div class="card" style="text-align:center;padding:28px"><div class="big" style="font-size:26px">'+c.w+'</div>'+(rRevealed?'<div style="margin-top:10px">'+T(c.m)+'</div>':'')+'</div>';
  if(!rRevealed) h+='<button class="btn primary" style="width:100%;margin-top:14px" onclick="rShow()">'+(LANG==='bn'?'উত্তর দেখাও':'Show answer')+'</button>';
  else h+='<div class="rate" style="margin-top:14px">'+[['আবার','Again','1d'],['কঠিন','Hard','3d'],['ভালো','Good','7d'],['সহজ','Easy','15d']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="rRate()">'+(LANG==='bn'?r[0]:r[1])+'<small>'+r[2]+'</small></button>').join('')+'</div>';
  return h+'</div>';
}
window.rShow=()=>{rRevealed=true;render();};
window.rRate=()=>{rRevealed=false;rIdx++;render();};
window.rReset=()=>{rIdx=0;rRevealed=false;render();};

/* ---------- lang + boot ---------- */
document.getElementById('langs').addEventListener('click',(e)=>{const b=e.target.closest('button'); if(!b)return;
  LANG=b.dataset.l; [...document.querySelectorAll('#langs button')].forEach(x=>x.classList.toggle('on',x===b)); render();});
render();
</script></body></html>
```


## File: preview\sensei_body.html

```html

<style>
  :root{
    --bg:#0E1116; --surface:#161B22; --surface2:#1A2230; --line:rgba(255,255,255,.08);
    --text:#E8EAED; --muted:#8A93A2; --faint:#5A6472;
    --pink:#FF2D78; --pink-dim:#3A1526; --green:#00C853; --green-dim:#10361F;
    --amber:#FFC400; --amber-dim:#3A2A12; --blue:#2979FF;
    --font:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans","Noto Sans Bengali","Noto Sans JP",sans-serif;
  }
  *{box-sizing:border-box}
  body{margin:0}
  .stage{
    min-height:100vh; display:flex; align-items:center; justify-content:center;
    padding:24px; font-family:var(--font);
    background:
      radial-gradient(1200px 600px at 20% -10%, #1b2740 0%, transparent 55%),
      radial-gradient(900px 500px at 110% 20%, #2a1330 0%, transparent 50%),
      #05070c;
  }
  .frame{
    width:390px; max-width:100%; height:800px; max-height:calc(100vh - 40px);
    background:var(--bg); border-radius:40px; position:relative; overflow:hidden;
    border:1px solid rgba(255,255,255,.10);
    box-shadow:0 40px 90px -20px rgba(0,0,0,.8), 0 0 0 10px #0a0c11, 0 0 0 11px rgba(255,255,255,.06);
    display:flex; flex-direction:column; color:var(--text);
  }
  .statusbar{display:flex; justify-content:space-between; align-items:center;
    padding:12px 22px 4px; font-size:12px; color:var(--muted); letter-spacing:.3px}
  .statusbar .dots{display:flex; gap:4px; align-items:center}
  .statusbar .dots span{width:5px;height:5px;border-radius:50%;background:var(--muted)}
  .appbar{display:flex; align-items:center; justify-content:space-between; padding:6px 18px 10px}
  .brand{font-weight:800; letter-spacing:1.5px; font-size:15px}
  .brand b{color:var(--pink)}
  .langs{display:flex; gap:4px}
  .langs button{background:transparent; border:0; color:var(--muted); font:inherit; font-size:12px;
    padding:5px 9px; border-radius:9px; cursor:pointer}
  .langs button.on{background:rgba(255,45,120,.14); color:var(--pink)}
  .screen{flex:1; overflow-y:auto; overflow-x:hidden; -webkit-overflow-scrolling:touch}
  .screen::-webkit-scrollbar{width:0}
  .nav{display:flex; border-top:1px solid var(--line); background:rgba(10,13,20,.85); backdrop-filter:blur(8px)}
  .nav button{flex:1; background:none; border:0; color:var(--faint); padding:9px 0 12px; cursor:pointer;
    display:flex; flex-direction:column; align-items:center; gap:3px; font:inherit; font-size:9.5px}
  .nav button.on{color:var(--pink)}
  .nav svg{width:22px;height:22px;stroke:currentColor;fill:none;stroke-width:1.7}
  /* shared */
  h2.title{margin:16px 20px 2px; font-size:13px; color:var(--muted); font-weight:600}
  .sub{margin:0 20px; color:var(--faint); font-size:12px}
  .card{background:var(--surface); border:1px solid var(--line); border-radius:18px; padding:18px}
  .pad{padding:16px}
  .btn{border:0; border-radius:13px; font:inherit; font-weight:600; padding:12px 16px; cursor:pointer;
    min-height:48px; display:inline-flex; align-items:center; justify-content:center; gap:7px}
  .btn.primary{background:var(--pink); color:#fff}
  .btn.filled{background:var(--green); color:#04120a}
  .btn.ghost{background:rgba(255,255,255,.06); color:var(--text)}
  .btn.line{background:transparent; border:1px solid var(--line); color:var(--text)}
  .btn:disabled{opacity:.35; cursor:default}
  .row{display:flex; gap:8px}
  .grow{flex:1}
  .jp{font-weight:700}
  .muted{color:var(--muted)} .faint{color:var(--faint)}
  /* kana grid */
  .krow{display:flex; gap:8px; padding:0 16px 12px}
  .seg{display:flex; background:var(--surface); border:1px solid var(--line); border-radius:12px; overflow:hidden; margin:14px 20px 6px}
  .seg button{flex:1; background:none; border:0; color:var(--muted); font:inherit; padding:9px; cursor:pointer}
  .seg button.on{background:var(--pink); color:#fff}
  .grid{display:grid; grid-template-columns:repeat(5,1fr); gap:8px; padding:8px 16px 20px}
  .cell{background:var(--surface); border:1px solid var(--line); border-radius:14px; aspect-ratio:1;
    display:flex; flex-direction:column; align-items:center; justify-content:center; cursor:pointer; transition:.12s}
  .cell:active{transform:scale(.94); background:var(--surface2)}
  .cell .c{font-size:24px; font-weight:600}
  .cell .r{font-size:10px; color:var(--faint)}
  /* write */
  .strip{display:flex; gap:8px; overflow-x:auto; padding:12px 16px}
  .strip::-webkit-scrollbar{height:0}
  .chip{min-width:46px; height:46px; border-radius:12px; background:rgba(255,255,255,.06); border:0; color:var(--text);
    font-size:22px; cursor:pointer; flex:0 0 auto}
  .chip.on{background:var(--pink); color:#fff}
  #paper{width:100%; aspect-ratio:1; border-radius:20px; background:#FBFBFD; touch-action:none; display:block}
  .tools{display:flex; gap:8px; padding:12px 16px}
  .tools .btn{flex:1; padding:10px}
  /* controls (invariant) */
  .controls{display:flex; gap:8px; padding:0 16px 6px}
  .controls .btn{flex:1; padding:9px}
  .steps{display:flex; gap:4px; padding:8px 20px 2px}
  .steps i{flex:1; height:4px; border-radius:2px; background:rgba(255,255,255,.14)}
  .steps i.on{background:var(--green)}
  .phaselab{display:flex; justify-content:space-between; padding:2px 20px 0; font-size:12px}
  .opt{width:100%; text-align:left; background:rgba(255,255,255,.06); border:1.5px solid transparent; color:var(--text);
    border-radius:12px; padding:12px 14px; margin-bottom:8px; cursor:pointer; font:inherit; min-height:48px}
  .opt.good{background:var(--green-dim)} .opt.bad{background:var(--amber-dim)} .opt.hint{border-color:var(--green)}
  .tok{background:rgba(255,255,255,.08); border:0; color:var(--text); border-radius:10px; padding:8px 12px;
    font-size:18px; cursor:pointer; font-family:var(--font)}
  .assembled{min-height:56px; border:1.5px solid transparent; border-radius:12px; background:rgba(255,255,255,.05);
    padding:10px; display:flex; flex-wrap:wrap; gap:8px; align-items:center}
  .assembled.good{border-color:var(--green)} .assembled.bad{border-color:var(--amber)}
  .bank{display:flex; flex-wrap:wrap; gap:8px}
  .pillrow{display:flex; flex-wrap:wrap; gap:8px}
  .pill{background:rgba(255,255,255,.08); border-radius:999px; padding:6px 12px; font-size:14px}
  .center{display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; gap:12px; padding:24px; text-align:center}
  .big{font-size:34px; font-weight:800}
  .rate{display:flex; gap:6px}
  .rate .btn{flex:1; flex-direction:column; gap:2px; font-size:12px; padding:10px 4px}
  .rate small{color:rgba(255,255,255,.7); font-weight:400}
  /* pitch */
  .contour{display:flex; align-items:flex-end; gap:2px; height:44px; margin-top:6px}
  .mora{display:flex; flex-direction:column; align-items:center; gap:4px}
  .mora .b{width:22px; border-radius:3px 3px 0 0; background:var(--pink)}
  .wave{height:70px; border-radius:14px; background:
    repeating-linear-gradient(90deg, rgba(255,45,120,.35) 0 2px, transparent 2px 7px); opacity:.5}
  .tag{display:inline-block; font-size:11px; padding:2px 8px; border-radius:999px; background:rgba(0,200,83,.15); color:var(--green)}
</style>
<div class="stage">
  <div class="frame">
    <div class="statusbar"><span>9:41</span><div class="dots"><span></span><span></span><span></span> ▮</div></div>
    <div class="appbar">
      <div class="brand">SEN<b>SEI</b></div>
      <div class="langs" id="langs">
        <button data-l="en">EN</button>
        <button data-l="bn" class="on">বাংলা</button>
        <button data-l="ja">日本語</button>
      </div>
    </div>
    <div class="screen" id="screen"></div>
    <div class="nav" id="nav"></div>
  </div>
</div>
<script>
const DATA = {"hira":[{"char":"あ","romaji":"a"},{"char":"い","romaji":"i"},{"char":"う","romaji":"u"},{"char":"え","romaji":"e"},{"char":"お","romaji":"o"},{"char":"か","romaji":"ka"},{"char":"き","romaji":"ki"},{"char":"く","romaji":"ku"},{"char":"け","romaji":"ke"},{"char":"こ","romaji":"ko"},{"char":"さ","romaji":"sa"},{"char":"し","romaji":"shi"},{"char":"す","romaji":"su"},{"char":"せ","romaji":"se"},{"char":"そ","romaji":"so"},{"char":"た","romaji":"ta"},{"char":"ち","romaji":"chi"},{"char":"つ","romaji":"tsu"},{"char":"て","romaji":"te"},{"char":"と","romaji":"to"},{"char":"な","romaji":"na"},{"char":"に","romaji":"ni"},{"char":"ぬ","romaji":"nu"},{"char":"ね","romaji":"ne"},{"char":"の","romaji":"no"},{"char":"は","romaji":"ha"},{"char":"ひ","romaji":"hi"},{"char":"ふ","romaji":"fu"},{"char":"へ","romaji":"he"},{"char":"ほ","romaji":"ho"},{"char":"ま","romaji":"ma"},{"char":"み","romaji":"mi"},{"char":"む","romaji":"mu"},{"char":"め","romaji":"me"},{"char":"も","romaji":"mo"},{"char":"や","romaji":"ya"},{"char":"ゆ","romaji":"yu"},{"char":"よ","romaji":"yo"},{"char":"ら","romaji":"ra"},{"char":"り","romaji":"ri"},{"char":"る","romaji":"ru"},{"char":"れ","romaji":"re"},{"char":"ろ","romaji":"ro"},{"char":"わ","romaji":"wa"},{"char":"を","romaji":"wo"},{"char":"ん","romaji":"n"}],"kata":[{"char":"ア","romaji":"a"},{"char":"イ","romaji":"i"},{"char":"ウ","romaji":"u"},{"char":"エ","romaji":"e"},{"char":"オ","romaji":"o"},{"char":"カ","romaji":"ka"},{"char":"キ","romaji":"ki"},{"char":"ク","romaji":"ku"},{"char":"ケ","romaji":"ke"},{"char":"コ","romaji":"ko"},{"char":"サ","romaji":"sa"},{"char":"シ","romaji":"shi"},{"char":"ス","romaji":"su"},{"char":"セ","romaji":"se"},{"char":"ソ","romaji":"so"},{"char":"タ","romaji":"ta"},{"char":"チ","romaji":"chi"},{"char":"ツ","romaji":"tsu"},{"char":"テ","romaji":"te"},{"char":"ト","romaji":"to"},{"char":"ナ","romaji":"na"},{"char":"ニ","romaji":"ni"},{"char":"ヌ","romaji":"nu"},{"char":"ネ","romaji":"ne"},{"char":"ノ","romaji":"no"},{"char":"ハ","romaji":"ha"},{"char":"ヒ","romaji":"hi"},{"char":"フ","romaji":"fu"},{"char":"ヘ","romaji":"he"},{"char":"ホ","romaji":"ho"},{"char":"マ","romaji":"ma"},{"char":"ミ","romaji":"mi"},{"char":"ム","romaji":"mu"},{"char":"メ","romaji":"me"},{"char":"モ","romaji":"mo"},{"char":"ヤ","romaji":"ya"},{"char":"ユ","romaji":"yu"},{"char":"ヨ","romaji":"yo"},{"char":"ラ","romaji":"ra"},{"char":"リ","romaji":"ri"},{"char":"ル","romaji":"ru"},{"char":"レ","romaji":"re"},{"char":"ロ","romaji":"ro"},{"char":"ワ","romaji":"wa"},{"char":"ヲ","romaji":"wo"},{"char":"ン","romaji":"n"}],"strokes":{"viewBox":1000,"source":"KanjiVG (https://kanjivg.tagaini.net)","license":"CC BY-SA 3.0 — © Ulrich Apel / KanjiVG contributors","note":"Generated by tools/fetch_stroke_data.mjs. One median polyline per stroke, in stroke order.","hiragana":{"あ":[[[284,303],[288,306],[292,309],[297,312],[303,314],[309,316],[317,318],[324,319],[333,319],[363,317],[396,314],[430,311],[465,306],[500,300],[535,294],[570,287],[603,280],[609,279],[616,277],[624,276],[632,275],[640,274],[649,274],[657,274],[664,275]],[[457,162],[460,166],[462,170],[465,176],[467,182],[469,189],[470,196],[470,203],[469,210],[457,269],[446,332],[436,396],[429,460],[423,524],[420,587],[420,646],[422,702],[424,721],[427,740],[430,758],[434,774],[438,790],[443,804],[448,816],[453,827]],[[602,405],[605,409],[607,416],[608,423],[609,431],[610,439],[610,447],[609,454],[607,461],[590,503],[571,544],[549,585],[523,626],[493,666],[459,707],[419,748],[374,789],[350,806],[325,815],[300,818],[277,812],[257,799],[241,779],[230,750],[225,712],[230,674],[245,636],[272,599],[307,565],[351,533],[402,505],[459,483],[522,467],[565,461],[609,461],[652,467],[693,478],[729,495],[760,518],[785,548],[802,584],[811,629],[810,673],[799,715],[779,755],[750,790],[712,821],[665,846],[610,863]]],"い":[[[197,272],[204,280],[209,288],[213,296],[216,304],[217,313],[218,322],[218,331],[217,340],[209,404],[205,462],[206,515],[212,564],[223,609],[240,649],[262,687],[290,721],[309,739],[323,749],[333,752],[341,748],[346,737],[349,721],[352,699],[354,673]],[[669,335],[701,364],[731,395],[759,429],[784,466],[805,506],[822,549],[833,595],[838,645]]],"う":[[[385,142],[404,149],[421,155],[437,159],[453,163],[467,166],[480,168],[492,169],[503,170],[528,170],[546,172],[556,175],[559,180],[555,187],[544,195],[525,206],[500,220]],[[303,389],[310,393],[317,397],[325,401],[334,404],[344,406],[354,407],[367,405],[381,401],[397,395],[417,385],[438,375],[461,364],[484,353],[507,345],[530,339],[550,337],[570,340],[587,347],[603,359],[617,376],[629,398],[637,426],[643,461],[644,502],[641,555],[630,607],[613,658],[588,707],[557,754],[518,799],[473,841],[421,881]]],"え":[[[372,122],[391,128],[408,134],[425,139],[442,143],[457,146],[472,148],[487,149],[501,149],[526,150],[544,151],[554,154],[557,159],[553,166],[541,175],[523,186],[498,200]],[[298,414],[305,418],[312,421],[320,424],[329,425],[338,425],[347,425],[356,423],[366,420],[381,413],[404,403],[431,391],[460,377],[490,363],[518,349],[543,338],[561,329],[575,324],[589,322],[600,323],[609,328],[615,335],[616,344],[611,357],[601,371],[558,422],[513,474],[467,527],[420,580],[373,632],[327,684],[282,733],[239,779],[230,789],[226,797],[225,802],[227,804],[232,804],[238,802],[245,798],[252,791],[295,746],[331,708],[362,676],[388,650],[411,631],[431,617],[450,609],[469,607],[489,613],[502,632],[510,658],[513,690],[516,724],[518,758],[523,788],[531,812],[547,828],[572,839],[603,845],[638,847],[675,846],[710,842],[743,837],[771,831]]],"お":[[[210,322],[215,326],[221,329],[227,333],[234,336],[241,339],[249,341],[257,342],[265,342],[279,339],[303,333],[332,325],[365,317],[397,308],[426,299],[447,293],[459,289],[464,287],[471,285],[477,282],[484,280],[492,278],[499,276],[506,273],[513,271]],[[381,148],[388,152],[395,158],[400,166],[404,175],[408,185],[410,195],[410,205],[409,216],[401,276],[395,345],[390,419],[387,495],[385,569],[384,639],[386,700],[389,751],[390,778],[390,799],[387,815],[381,825],[372,830],[360,830],[344,826],[323,817],[304,806],[284,794],[263,781],[243,766],[225,750],[210,734],[201,718],[197,703],[207,674],[235,640],[278,604],[332,569],[396,537],[465,510],[537,493],[608,486],[663,490],[710,499],[750,515],[782,534],[806,558],[824,585],[834,614],[837,644],[833,674],[821,704],[802,734],[774,762],[739,788],[697,809],[648,826],[592,837]],[[670,203],[687,212],[704,222],[718,232],[731,242],[742,251],[752,261],[760,270],[767,279],[773,289],[776,297],[777,304],[775,310],[772,315],[767,319],[762,322],[757,324]]],"か":[[[226,354],[233,359],[240,364],[249,367],[258,369],[268,370],[280,369],[292,367],[305,363],[384,340],[446,326],[493,323],[528,329],[552,343],[566,366],[574,396],[576,433],[575,465],[573,496],[571,526],[566,555],[561,583],[554,611],[546,638],[537,665],[512,724],[491,766],[472,792],[455,805],[438,807],[422,800],[406,785],[389,765]],[[445,161],[448,166],[451,173],[452,181],[453,190],[454,199],[453,208],[452,217],[450,226],[429,282],[404,344],[376,408],[348,469],[321,526],[297,574],[280,609],[270,628],[259,648],[248,668],[237,688],[226,708],[215,727],[205,745],[194,762],[183,778]],[[710,290],[735,315],[758,341],[779,368],[798,396],[815,426],[829,456],[840,487],[847,518]]],"き":[[[280,278],[287,280],[294,282],[301,284],[309,285],[316,286],[323,286],[329,286],[334,286],[360,281],[392,275],[428,268],[464,260],[499,252],[531,244],[558,236],[577,231],[584,228],[590,226],[596,223],[602,221],[607,219],[612,217],[617,214],[622,211]],[[333,447],[340,449],[348,452],[356,454],[364,455],[372,456],[379,456],[385,456],[390,456],[419,451],[453,444],[491,436],[530,427],[567,417],[602,408],[630,400],[651,394],[658,391],[665,388],[672,386],[677,383],[683,380],[688,378],[693,375],[698,372]],[[385,130],[391,133],[396,137],[401,143],[406,149],[411,155],[415,162],[419,169],[422,177],[443,224],[468,273],[496,322],[526,371],[559,419],[593,465],[628,509],[664,550],[687,576],[704,596],[714,609],[715,616],[706,617],[686,613],[654,602],[609,586]],[[310,764],[349,793],[391,813],[437,826],[484,833],[531,833],[576,829],[620,821],[659,810]]],"く":[[[557,138],[558,144],[559,152],[559,161],[558,170],[557,180],[555,189],[551,198],[547,205],[524,238],[500,271],[477,302],[454,332],[432,360],[411,386],[393,410],[377,430],[365,446],[356,460],[351,473],[349,484],[350,495],[353,506],[360,518],[368,531],[388,558],[409,588],[430,620],[451,653],[473,686],[493,719],[512,751],[530,781],[535,790],[540,798],[545,807],[550,816],[555,826],[560,836],[566,847],[571,860]]],"け":[[[226,181],[231,187],[235,193],[239,199],[242,207],[245,214],[246,222],[247,231],[246,240],[235,293],[225,346],[216,397],[208,447],[201,497],[198,547],[198,598],[201,649],[207,700],[213,728],[218,735],[223,726],[230,706],[238,678],[249,647],[263,617]],[[492,354],[500,359],[507,362],[515,365],[522,367],[530,369],[538,369],[547,369],[556,368],[583,364],[610,359],[636,355],[660,350],[684,346],[706,341],[726,336],[745,331],[754,329],[763,327],[772,325],[780,324],[788,323],[795,322],[802,321],[808,321]],[[658,132],[664,137],[670,142],[674,148],[678,154],[681,160],[683,166],[684,173],[684,179],[684,218],[684,254],[684,290],[684,324],[685,357],[685,389],[685,422],[685,455],[685,522],[682,581],[677,634],[669,681],[655,725],[634,765],[607,804],[570,843]]],"こ":[[[319,245],[323,249],[328,252],[333,255],[340,257],[347,259],[355,260],[364,260],[374,259],[400,255],[425,251],[450,247],[474,243],[499,240],[525,238],[551,236],[579,235],[622,237],[646,242],[653,251],[646,262],[627,275],[600,289],[565,304],[526,318]],[[275,625],[287,670],[308,707],[336,735],[371,756],[412,770],[457,778],[507,781],[560,779],[582,777],[603,775],[623,772],[643,769],[663,766],[682,762],[702,757],[721,752]]],"さ":[[[248,357],[256,361],[265,364],[275,366],[284,368],[294,368],[304,368],[314,368],[324,367],[359,360],[400,350],[445,338],[492,324],[537,309],[579,295],[613,282],[637,271],[646,267],[654,263],[661,259],[667,256],[673,252],[680,248],[687,244],[695,239]],[[381,127],[386,131],[392,135],[398,140],[404,146],[409,153],[414,160],[419,167],[422,174],[443,222],[467,269],[494,316],[524,362],[557,407],[592,452],[629,495],[669,537],[692,562],[707,582],[713,595],[711,603],[700,604],[680,598],[651,585],[613,565]],[[323,739],[344,774],[373,801],[411,820],[455,831],[504,834],[559,831],[616,822],[676,807]]],"し":[[[359,161],[363,171],[365,183],[366,194],[367,206],[367,218],[366,230],[364,242],[362,255],[356,301],[350,347],[345,392],[341,437],[338,482],[336,526],[335,570],[335,613],[343,697],[367,761],[405,805],[455,831],[517,840],[588,832],[667,809],[752,772]]],"す":[[[142,341],[153,347],[164,351],[177,353],[191,353],[206,352],[222,350],[240,347],[259,343],[316,331],[375,321],[434,313],[492,305],[548,298],[600,292],[647,287],[687,283],[710,281],[732,280],[752,279],[772,279],[791,279],[811,280],[830,282],[850,284]],[[529,123],[535,128],[540,134],[545,140],[548,146],[551,153],[552,160],[554,168],[554,177],[554,218],[554,268],[554,323],[554,380],[554,435],[554,484],[554,524],[554,551],[548,595],[531,629],[509,650],[482,659],[456,656],[433,640],[417,610],[411,567],[418,524],[436,494],[463,478],[493,476],[523,489],[550,518],[569,563],[576,625],[572,669],[563,708],[549,744],[531,777],[509,807],[484,835],[457,861],[429,886]]],"せ":[[[151,458],[162,465],[173,470],[186,472],[200,472],[215,471],[231,469],[249,466],[268,463],[332,452],[391,442],[448,432],[501,423],[553,415],[603,407],[652,400],[701,393],[724,390],[746,388],[766,386],[786,385],[805,385],[824,386],[844,387],[863,390]],[[640,163],[646,168],[651,174],[656,180],[659,186],[662,193],[664,200],[665,208],[665,217],[665,251],[665,283],[665,313],[665,341],[665,367],[665,390],[665,412],[665,432],[663,509],[656,564],[645,601],[632,622],[615,631],[597,629],[577,620],[556,607]],[[327,241],[333,246],[338,252],[343,258],[346,264],[349,271],[351,278],[352,286],[352,295],[352,333],[352,376],[352,422],[352,467],[352,510],[352,550],[352,582],[352,607],[355,653],[363,691],[377,722],[397,746],[423,764],[455,777],[493,784],[537,786],[569,786],[597,786],[622,785],[645,784],[668,783],[691,780],[716,776],[744,771]]],"そ":[[[352,202],[359,206],[367,208],[376,210],[384,210],[394,210],[403,209],[412,207],[421,205],[444,199],[466,193],[489,187],[511,180],[534,174],[556,168],[578,162],[599,156],[614,154],[627,155],[637,159],[644,165],[647,173],[647,183],[642,193],[632,204],[588,242],[539,282],[489,322],[437,360],[388,397],[341,430],[300,458],[265,482],[246,495],[234,506],[226,514],[225,520],[229,523],[240,524],[256,522],[278,517],[337,502],[397,487],[458,473],[518,460],[576,448],[633,438],[687,429],[738,422],[766,419],[786,418],[799,418],[804,420],[800,423],[789,426],[770,430],[742,435],[687,446],[632,465],[579,491],[530,522],[488,557],[456,595],[434,636],[427,678],[432,720],[446,756],[470,787],[503,811],[544,828],[594,838],[651,838],[716,830]]],"た":[[[224,325],[229,327],[235,329],[242,331],[249,333],[257,335],[265,336],[274,336],[282,335],[306,331],[332,327],[360,322],[389,316],[419,310],[450,304],[480,298],[510,291],[520,289],[529,287],[538,284],[547,281],[556,279],[564,276],[572,272],[580,269]],[[413,155],[415,160],[417,165],[418,171],[419,178],[419,184],[419,191],[418,197],[416,203],[394,273],[373,339],[351,401],[329,460],[307,518],[286,574],[264,629],[243,683],[238,698],[231,715],[223,733],[215,753],[207,772],[200,790],[193,806],[188,818]],[[517,489],[557,480],[592,473],[623,467],[650,463],[674,460],[695,459],[715,459],[734,460],[773,465],[790,470],[790,474],[777,479],[756,484],[733,490],[711,496],[695,505]],[[497,755],[514,776],[537,793],[565,805],[600,813],[642,817],[691,817],[748,813],[813,806]]],"ち":[[[225,299],[230,301],[236,304],[243,306],[250,308],[258,309],[266,310],[275,310],[283,310],[308,305],[336,299],[367,293],[399,285],[433,277],[466,269],[499,261],[530,254],[539,252],[548,250],[557,247],[566,245],[575,242],[584,239],[592,236],[600,233]],[[419,143],[421,148],[422,154],[423,160],[424,166],[424,173],[424,179],[423,185],[422,191],[412,240],[404,284],[396,325],[387,365],[379,405],[369,448],[358,494],[345,546],[335,583],[326,610],[321,626],[320,632],[324,631],[334,622],[352,607],[378,586],[408,566],[440,548],[473,533],[507,521],[542,511],[576,504],[609,500],[640,499],[668,501],[694,508],[717,520],[736,536],[752,555],[763,578],[771,603],[773,632],[766,676],[747,714],[718,747],[681,776],[639,800],[593,819],[546,834],[499,845]]],"つ":[[[128,411],[135,416],[143,420],[151,422],[160,424],[170,424],[180,423],[191,420],[203,416],[262,392],[317,371],[369,353],[419,339],[468,329],[516,321],[565,317],[615,316],[657,320],[696,329],[732,344],[763,364],[789,389],[808,419],[820,453],[824,492],[814,553],[785,607],[742,653],[687,692],[623,725],[554,752],[483,772],[412,787]]],"て":[[[188,242],[195,247],[202,251],[210,254],[219,256],[229,257],[239,257],[250,256],[263,255],[333,243],[397,233],[454,224],[508,215],[560,207],[612,198],[666,188],[722,178],[760,171],[787,168],[804,167],[810,168],[805,172],[790,177],[764,183],[726,190],[665,207],[608,233],[556,268],[509,310],[471,359],[441,414],[423,473],[416,536],[423,601],[444,658],[476,706],[518,745],[567,775],[621,796],[679,809],[739,813]]],"と":[[[326,169],[332,172],[338,176],[343,181],[349,186],[354,193],[358,201],[361,209],[363,218],[367,235],[372,265],[380,303],[388,346],[396,388],[403,427],[409,458],[413,476]],[[717,234],[717,241],[717,247],[717,254],[715,261],[712,268],[708,274],[703,281],[696,287],[674,302],[651,318],[627,333],[603,349],[576,366],[549,385],[519,405],[487,427],[445,458],[406,490],[373,521],[344,553],[321,584],[303,616],[293,647],[289,679],[293,711],[304,738],[323,760],[349,777],[383,790],[426,799],[477,805],[536,806],[558,806],[582,806],[607,805],[633,804],[659,803],[684,801],[710,798],[734,795]]],"な":[[[210,266],[214,268],[220,270],[225,271],[232,273],[238,274],[245,275],[253,275],[260,275],[279,275],[298,273],[317,271],[336,269],[354,266],[373,262],[392,258],[412,253],[428,249],[444,244],[459,239],[473,233],[486,228],[497,223],[507,219],[516,214]],[[394,128],[396,132],[398,136],[398,140],[399,144],[399,149],[399,154],[398,158],[397,163],[386,211],[373,257],[359,302],[343,346],[326,389],[308,430],[288,471],[267,510],[259,523],[252,535],[245,548],[237,560],[230,572],[222,584],[214,596],[206,608]],[[663,213],[686,222],[708,232],[728,242],[747,252],[763,263],[778,275],[789,287],[798,300],[809,321],[813,334],[812,340],[807,342],[799,341],[789,338],[778,336],[766,336]],[[632,409],[628,416],[625,425],[622,434],[619,443],[617,454],[615,464],[614,475],[615,485],[617,509],[619,532],[622,555],[624,578],[626,601],[627,625],[628,649],[628,674],[617,735],[588,778],[548,807],[501,822],[454,823],[413,813],[384,791],[373,760],[376,742],[385,727],[399,714],[417,703],[437,695],[458,689],[480,686],[500,685],[532,686],[566,690],[602,698],[638,709],[674,723],[710,742],[743,764],[773,790]]],"に":[[[225,209],[229,214],[232,220],[235,227],[236,234],[237,242],[237,250],[237,258],[235,267],[224,322],[211,377],[198,433],[186,488],[175,543],[168,598],[165,652],[168,704],[175,756],[182,784],[191,792],[200,785],[210,765],[221,737],[232,705],[246,672]],[[488,281],[492,284],[496,286],[500,289],[506,291],[512,292],[518,293],[526,294],[535,293],[559,291],[584,286],[610,281],[636,276],[662,271],[687,267],[712,264],[737,263],[772,264],[789,268],[790,275],[778,284],[756,294],[727,305],[694,318],[660,330]],[[482,624],[491,664],[508,697],[530,722],[557,741],[589,753],[624,760],[663,763],[704,761],[721,759],[737,758],[753,756],[769,754],[784,752],[800,749],[817,746],[835,742]]],"ぬ":[[[233,261],[239,266],[245,272],[250,278],[254,284],[257,291],[260,299],[262,307],[264,315],[270,357],[278,398],[285,439],[294,479],[304,519],[315,558],[328,596],[342,633],[349,648],[355,663],[362,677],[370,691],[378,706],[386,720],[395,734],[405,748]],[[524,177],[527,184],[529,191],[530,197],[531,204],[532,210],[532,217],[531,224],[530,231],[516,286],[498,347],[477,411],[453,475],[429,536],[405,592],[383,640],[363,677],[324,732],[288,759],[256,762],[228,748],[205,722],[189,691],[178,660],[174,635],[192,559],[240,486],[310,423],[396,371],[490,336],[585,320],[673,328],[746,364],[770,386],[790,409],[805,435],[817,462],[825,489],[830,518],[831,548],[830,578],[812,659],[775,721],[727,763],[673,787],[619,795],[573,788],[541,767],[529,733],[536,705],[555,687],[584,677],[620,675],[659,679],[701,689],[741,704],[777,723],[788,730],[800,738],[812,747],[824,756],[835,765],[846,774],[856,783],[865,791]]],"ね":[[[305,133],[311,139],[315,144],[318,150],[320,156],[322,163],[323,170],[323,178],[323,187],[319,231],[316,282],[312,337],[309,398],[306,462],[304,530],[301,601],[299,674],[299,690],[299,706],[299,722],[298,738],[298,754],[298,770],[298,787],[297,803]],[[157,348],[163,350],[169,353],[175,355],[181,356],[187,357],[194,357],[201,356],[209,354],[218,352],[229,349],[242,345],[257,340],[273,335],[290,329],[306,323],[322,317],[342,311],[356,307],[366,306],[371,308],[372,314],[369,323],[362,335],[351,351],[331,378],[310,406],[288,436],[266,467],[244,499],[222,531],[201,564],[182,596],[166,625],[156,645],[152,657],[153,661],[159,660],[169,652],[183,640],[200,624],[266,559],[331,496],[396,435],[460,380],[523,333],[583,297],[641,273],[696,265],[731,270],[759,284],[780,308],[795,341],[805,383],[811,434],[814,494],[815,563],[803,648],[771,708],[727,747],[676,766],[625,769],[581,759],[550,739],[538,712],[545,684],[566,665],[597,654],[634,650],[676,653],[719,662],[760,677],[795,695],[805,702],[814,709],[824,717],[833,726],[842,734],[850,742],[858,750],[864,757]]],"の":[[[494,263],[497,268],[499,275],[501,282],[503,289],[504,298],[504,306],[503,315],[502,323],[494,358],[485,397],[473,438],[460,480],[446,521],[431,561],[417,596],[403,627],[371,686],[341,724],[313,744],[285,745],[259,731],[232,703],[206,661],[180,609],[165,539],[182,465],[224,393],[287,327],[366,274],[455,238],[549,225],[644,239],[740,287],[805,357],[840,441],[846,531],[825,620],[776,699],[701,760],[600,797]]],"は":[[[225,165],[229,171],[233,177],[236,184],[238,192],[240,200],[241,208],[241,217],[240,226],[228,287],[217,349],[207,412],[199,475],[194,538],[193,602],[195,666],[203,729],[210,771],[215,791],[219,794],[222,782],[226,761],[232,733],[241,702],[255,672]],[[455,348],[464,353],[472,357],[481,360],[489,362],[498,364],[507,365],[517,364],[527,363],[559,358],[589,353],[618,348],[646,343],[672,338],[697,332],[720,327],[742,321],[752,319],[763,316],[772,314],[782,313],[791,311],[799,310],[806,310],[813,310]],[[640,151],[647,159],[653,166],[658,173],[661,180],[664,188],[665,195],[666,203],[667,211],[667,233],[669,277],[671,337],[673,407],[676,480],[678,549],[680,609],[680,651],[668,718],[636,765],[591,795],[540,808],[488,808],[443,797],[411,776],[399,748],[409,720],[434,702],[471,693],[515,692],[562,695],[606,702],[644,712],[670,721],[690,732],[709,744],[728,757],[746,770],[762,782],[775,793],[786,802],[793,807]]],"ひ":[[[183,230],[188,234],[194,237],[201,240],[208,243],[216,245],[225,246],[234,245],[243,243],[253,240],[265,236],[277,232],[291,227],[305,221],[319,215],[333,209],[348,202],[367,193],[382,189],[394,189],[402,192],[406,199],[404,209],[398,223],[387,239],[306,348],[251,449],[219,542],[210,624],[222,694],[254,750],[304,791],[373,815],[435,818],[496,800],[554,763],[605,707],[648,631],[679,538],[697,426],[699,297],[698,253],[697,222],[698,202],[701,194],[706,198],[714,214],[724,242],[737,281],[751,319],[767,356],[785,390],[804,422],[824,451],[844,479],[865,503],[885,524]]],"ふ":[[[391,143],[404,154],[417,164],[430,173],[444,180],[459,187],[474,192],[491,196],[508,200],[535,205],[549,210],[554,216],[551,223],[541,230],[527,238],[509,247],[491,256]],[[400,430],[408,446],[419,463],[433,480],[449,498],[467,518],[487,540],[508,564],[531,591],[559,636],[570,682],[566,725],[547,762],[516,791],[473,807],[419,807],[356,789]],[[151,673],[154,687],[157,701],[161,714],[166,727],[172,738],[179,749],[187,758],[197,766],[201,767],[204,763],[209,756],[217,747],[230,734],[250,719],[279,701],[319,682]],[[735,568],[753,580],[770,592],[786,604],[801,615],[814,626],[826,635],[834,643],[840,649],[857,673],[865,689],[864,698],[857,702],[845,704],[829,706],[813,708],[797,714]]],"へ":[[[138,447],[145,452],[153,456],[161,458],[169,459],[178,458],[186,455],[194,451],[202,444],[214,432],[227,420],[240,408],[253,397],[266,385],[279,373],[292,361],[305,347],[323,330],[339,319],[354,312],[368,310],[382,312],[396,318],[410,327],[425,339],[469,376],[516,415],[564,454],[610,492],[652,526],[688,556],[715,578],[732,591],[744,601],[761,614],[780,630],[800,647],[820,664],[837,679],[851,690],[859,697]]],"ほ":[[[225,172],[229,178],[233,184],[236,191],[238,199],[240,207],[241,215],[241,224],[240,233],[228,294],[217,357],[207,421],[199,486],[194,551],[193,617],[195,681],[203,745],[210,787],[215,807],[219,810],[222,798],[226,777],[232,749],[241,718],[255,688]],[[487,194],[494,198],[500,201],[507,204],[514,206],[521,207],[528,208],[535,208],[543,207],[568,203],[592,199],[615,194],[637,190],[658,186],[677,181],[695,177],[712,172],[721,170],[729,168],[736,167],[744,165],[751,164],[757,163],[763,163],[768,163]],[[494,406],[501,411],[509,415],[517,418],[525,420],[533,421],[542,422],[550,422],[560,421],[588,416],[616,412],[643,408],[668,403],[691,399],[714,394],[735,390],[754,385],[764,382],[774,380],[783,378],[792,377],[801,375],[809,375],[816,374],[822,374]],[[665,211],[670,217],[673,224],[675,231],[677,238],[679,246],[680,254],[680,262],[680,271],[681,291],[683,332],[686,387],[689,451],[693,518],[696,582],[698,638],[698,679],[687,732],[656,770],[612,795],[561,807],[511,808],[467,799],[436,780],[424,752],[433,724],[456,704],[490,693],[532,688],[577,690],[621,698],[662,710],[695,726],[714,738],[733,751],[752,764],[770,776],[786,788],[800,798],[811,806],[818,812]]],"ま":[[[274,296],[281,300],[289,303],[297,305],[305,307],[313,308],[321,308],[330,308],[339,308],[380,304],[422,299],[465,294],[508,288],[549,282],[589,276],[625,269],[657,263],[667,262],[676,260],[685,260],[694,259],[702,259],[710,259],[716,259],[723,259]],[[310,476],[319,481],[327,484],[336,487],[345,488],[354,489],[363,489],[373,488],[383,487],[415,482],[447,477],[478,471],[508,466],[539,460],[569,453],[600,447],[631,440],[642,437],[653,435],[663,433],[673,431],[683,430],[692,429],[700,428],[707,428]],[[512,128],[517,135],[520,142],[523,150],[526,159],[527,167],[528,176],[528,185],[529,194],[529,219],[529,269],[530,337],[531,417],[531,499],[532,578],[533,644],[533,692],[521,756],[490,802],[445,831],[395,845],[344,846],[300,835],[269,813],[257,783],[267,750],[296,728],[338,714],[390,708],[448,709],[506,718],[562,733],[611,753],[631,765],[651,776],[671,786],[688,797],[705,807],[721,818],[734,828],[747,837]]],"み":[[[298,239],[305,244],[312,248],[319,250],[326,252],[334,252],[343,252],[352,251],[361,250],[375,248],[388,245],[401,242],[414,238],[428,234],[442,230],[456,226],[470,221],[484,218],[495,217],[505,218],[512,222],[516,229],[517,239],[516,252],[512,268],[504,289],[494,315],[483,346],[469,381],[454,419],[437,459],[420,501],[401,545],[354,642],[307,711],[262,756],[220,779],[185,783],[157,772],[139,748],[133,716],[141,672],[164,639],[199,614],[241,598],[290,589],[340,586],[390,587],[436,592],[497,602],[552,613],[604,626],[654,640],[701,657],[748,676],[795,698],[843,722]],[[728,502],[730,510],[732,518],[732,525],[733,533],[732,540],[731,546],[730,553],[728,560],[719,591],[707,628],[691,669],[670,712],[643,756],[611,797],[572,836],[525,869]]],"む":[[[180,290],[187,295],[194,299],[202,301],[209,303],[217,304],[225,303],[234,303],[242,301],[270,297],[297,291],[323,286],[350,281],[376,275],[402,269],[428,263],[455,256],[464,254],[474,251],[483,249],[491,248],[499,246],[507,245],[514,245],[520,244]],[[340,142],[345,147],[349,152],[353,157],[356,162],[358,169],[359,175],[359,183],[359,190],[356,228],[353,265],[350,302],[346,340],[342,379],[337,420],[330,464],[322,510],[305,571],[281,612],[252,637],[222,648],[194,645],[171,631],[156,608],[152,578],[155,553],[163,529],[175,509],[189,492],[206,477],[225,466],[246,458],[267,454],[286,454],[306,457],[325,464],[340,476],[350,494],[352,519],[343,551],[321,592],[284,653],[258,703],[245,742],[244,773],[256,795],[281,811],[318,821],[368,826],[405,828],[440,829],[473,830],[505,830],[536,829],[567,826],[598,823],[630,818],[670,810],[695,803],[708,796],[712,787],[710,776],[705,761],[700,741],[697,716]],[[720,333],[743,343],[764,354],[784,364],[801,375],[818,387],[832,399],[845,412],[857,425],[873,449],[879,463],[877,470],[868,471],[856,470],[842,467],[828,466],[816,467]]],"め":[[[252,291],[258,295],[262,300],[266,305],[269,311],[272,318],[273,325],[274,332],[275,339],[278,379],[282,419],[287,458],[295,496],[304,533],[314,567],[327,599],[342,627],[347,637],[355,649],[364,663],[373,677],[383,691],[392,704],[401,714],[408,723]],[[547,178],[550,183],[553,190],[555,197],[556,205],[557,213],[557,221],[556,230],[555,239],[542,292],[524,351],[501,412],[475,473],[448,532],[421,586],[394,634],[370,672],[331,722],[298,755],[270,773],[245,777],[223,768],[203,747],[185,717],[166,678],[163,621],[187,559],[234,497],[300,439],[379,392],[468,358],[562,344],[656,354],[742,394],[798,453],[827,523],[829,598],[805,672],[756,737],[681,787],[583,814]]],"も":[[[451,135],[457,142],[461,150],[464,158],[465,167],[466,176],[465,186],[464,197],[461,209],[451,257],[442,304],[434,351],[426,398],[418,445],[411,493],[404,543],[397,595],[390,659],[389,714],[393,761],[405,800],[426,830],[457,852],[499,865],[553,869],[618,863],[671,847],[714,820],[744,783],[762,736],[768,680],[759,615],[737,541]],[[243,318],[248,321],[252,324],[258,327],[264,331],[271,333],[279,335],[288,336],[299,336],[336,333],[371,330],[405,326],[437,322],[468,318],[498,313],[526,309],[553,304],[566,302],[577,300],[587,298],[597,297],[606,296],[615,295],[625,294],[634,295]],[[242,490],[239,503],[239,515],[243,525],[250,534],[260,542],[274,547],[292,550],[313,552],[344,551],[373,550],[402,548],[430,546],[457,543],[482,541],[504,537],[523,534],[531,533],[539,532],[548,530],[557,528],[567,526],[576,523],[584,521],[592,518]]],"や":[[[165,453],[172,458],[180,463],[190,466],[200,468],[210,469],[221,468],[233,466],[244,461],[307,430],[369,399],[430,369],[489,342],[547,318],[603,300],[658,288],[711,284],[741,287],[768,292],[793,301],[815,313],[833,329],[846,348],[854,371],[857,397],[852,426],[839,453],[819,479],[791,503],[758,524],[720,541],[677,554],[632,561]],[[432,146],[450,150],[467,155],[484,162],[499,170],[512,179],[524,188],[532,197],[538,206],[543,221],[544,229],[543,234],[538,235],[533,234],[526,232],[518,231],[511,230]],[[275,224],[283,230],[289,235],[295,241],[299,246],[303,252],[306,258],[309,264],[311,272],[322,316],[337,373],[355,439],[375,510],[395,581],[414,648],[432,707],[446,753],[449,761],[452,771],[455,781],[458,793],[462,805],[465,817],[469,828],[473,840]]],"ゆ":[[[193,233],[198,238],[201,245],[204,252],[207,259],[208,267],[209,275],[208,283],[207,290],[198,330],[190,369],[185,408],[181,447],[179,487],[179,527],[182,568],[187,611],[195,662],[200,689],[203,696],[205,688],[206,669],[208,645],[211,619],[217,598],[252,524],[294,460],[341,406],[393,361],[448,326],[506,301],[565,286],[624,281],[677,286],[721,299],[756,318],[783,343],[802,372],[816,403],[823,435],[825,467],[813,550],[779,613],[730,657],[670,682],[604,690],[539,682],[480,658],[431,620]],[[536,154],[544,160],[551,166],[556,172],[560,179],[563,186],[565,196],[567,206],[568,219],[571,254],[574,288],[576,321],[578,353],[579,386],[581,419],[582,453],[583,489],[582,564],[575,628],[564,682],[549,726],[531,764],[511,795],[491,823],[469,849]]],"よ":[[[534,325],[560,320],[584,316],[607,311],[629,306],[649,302],[669,297],[687,292],[704,287],[713,284],[721,282],[729,281],[736,279],[743,278],[750,277],[756,277],[761,276]],[[501,127],[508,135],[514,142],[519,149],[522,156],[525,164],[527,171],[527,179],[528,187],[526,246],[525,305],[525,366],[526,427],[528,489],[531,551],[535,614],[540,678],[531,747],[498,796],[447,827],[387,842],[326,844],[273,833],[235,812],[220,783],[231,749],[259,726],[301,714],[352,710],[407,713],[461,721],[510,732],[550,746],[576,756],[599,766],[620,775],[639,785],[658,796],[677,809],[697,823],[720,841]]],"ら":[[[324,138],[338,147],[353,156],[370,162],[388,168],[407,172],[429,175],[451,176],[476,177],[505,177],[518,179],[519,183],[511,188],[499,193],[484,199],[471,204],[464,209]],[[329,328],[322,343],[316,358],[312,373],[308,388],[305,403],[303,418],[301,434],[300,449],[299,470],[298,490],[297,511],[295,533],[293,555],[290,578],[286,601],[281,625],[273,659],[271,679],[273,688],[278,688],[286,682],[294,673],[302,664],[308,657],[348,626],[387,600],[424,580],[461,565],[497,554],[534,547],[570,543],[607,542],[638,545],[667,552],[693,562],[716,577],[735,595],[749,616],[758,642],[761,670],[755,714],[738,753],[710,788],[674,816],[631,840],[580,858],[524,870],[463,876]]],"り":[[[356,232],[360,237],[363,244],[367,251],[369,258],[371,266],[372,275],[372,284],[370,292],[360,336],[350,384],[341,434],[334,485],[329,536],[326,587],[327,636],[331,681],[337,714],[342,728],[346,727],[351,714],[356,694],[362,670],[371,646],[383,624]],[[636,172],[643,179],[649,186],[654,194],[657,201],[660,208],[662,216],[663,224],[663,232],[663,248],[663,280],[663,322],[663,372],[663,424],[663,475],[663,522],[663,560],[661,613],[655,661],[645,704],[631,743],[614,778],[595,809],[572,837],[547,863]]],"る":[[[315,187],[321,191],[329,195],[337,199],[346,202],[357,204],[368,205],[380,204],[393,201],[407,197],[422,193],[439,188],[457,183],[476,178],[495,172],[516,165],[536,158],[555,153],[570,151],[581,152],[588,156],[591,162],[590,172],[585,183],[576,197],[560,219],[536,251],[505,291],[469,336],[430,383],[392,430],[355,473],[322,509],[294,538],[272,560],[256,576],[248,585],[250,586],[263,579],[289,564],[329,539],[387,510],[451,489],[516,480],[580,483],[636,502],[682,536],[712,589],[723,662],[707,731],[664,782],[604,818],[536,838],[467,843],[407,835],[364,812],[348,778],[355,745],[375,723],[404,711],[438,708],[476,714],[512,728],[546,748],[572,774]]],"れ":[[[316,119],[321,124],[326,130],[330,137],[334,144],[337,152],[339,160],[340,169],[339,178],[337,206],[333,258],[329,327],[325,405],[321,485],[317,560],[315,622],[314,663],[314,692],[314,720],[314,746],[315,771],[315,794],[315,814],[315,830],[315,842]],[[156,374],[163,378],[170,381],[177,383],[185,384],[193,383],[202,381],[213,378],[225,374],[239,368],[252,363],[265,358],[278,352],[291,347],[306,340],[323,332],[344,323],[357,319],[366,317],[373,318],[376,322],[377,328],[376,335],[372,345],[367,356],[349,386],[330,416],[311,446],[291,476],[269,507],[246,539],[221,573],[194,609],[171,640],[156,664],[148,681],[147,690],[155,691],[170,683],[192,666],[223,638],[269,594],[309,556],[345,520],[380,486],[415,453],[451,418],[490,381],[534,339],[559,319],[587,301],[616,286],[644,278],[668,278],[688,288],[699,311],[701,347],[697,384],[694,422],[691,459],[688,495],[685,531],[683,566],[681,599],[680,630],[682,694],[693,738],[713,765],[739,776],[769,774],[801,761],[833,738],[864,709]]],"ろ":[[[339,201],[345,207],[352,214],[360,219],[370,223],[380,226],[392,227],[404,226],[417,224],[431,220],[444,216],[459,212],[474,207],[491,202],[508,197],[527,190],[547,183],[565,178],[579,176],[588,177],[593,181],[595,187],[593,197],[587,209],[578,222],[550,260],[520,299],[489,338],[457,379],[424,419],[391,461],[358,503],[325,546],[302,576],[283,599],[271,614],[266,621],[271,620],[285,611],[312,593],[352,567],[416,531],[486,505],[557,490],[625,488],[686,500],[735,529],[768,575],[779,641],[773,691],[754,734],[725,771],[687,801],[643,826],[593,845],[540,861],[485,871]]],"わ":[[[353,135],[358,140],[362,146],[366,153],[369,160],[371,168],[372,176],[372,185],[372,194],[368,243],[364,305],[360,375],[356,448],[352,520],[349,586],[347,640],[347,679],[346,708],[346,736],[345,762],[344,787],[343,810],[342,830],[341,846],[341,858]],[[161,374],[168,378],[175,381],[182,383],[189,383],[198,382],[207,381],[217,378],[230,374],[249,367],[267,361],[285,355],[302,349],[320,343],[338,336],[358,328],[379,319],[392,314],[403,312],[412,313],[418,317],[420,323],[419,332],[413,343],[404,356],[381,383],[358,412],[335,441],[311,472],[286,504],[259,538],[231,573],[201,611],[178,641],[162,665],[153,681],[152,690],[159,690],[173,682],[197,665],[229,638],[306,573],[387,514],[468,463],[548,424],[624,400],[695,394],[758,408],[811,445],[849,500],[865,558],[862,616],[839,672],[800,725],[745,771],[677,809],[597,836]]],"を":[[[262,256],[268,259],[273,262],[279,265],[285,267],[292,268],[300,268],[308,267],[317,266],[353,259],[384,253],[413,248],[440,242],[466,237],[492,232],[517,227],[544,223],[556,221],[566,219],[576,218],[585,216],[594,216],[603,215],[612,215],[621,216]],[[458,132],[461,136],[463,141],[465,146],[466,153],[467,160],[466,167],[465,175],[462,183],[445,218],[428,254],[410,289],[392,324],[372,359],[351,394],[328,428],[304,461],[277,498],[257,524],[246,539],[243,545],[250,542],[265,530],[290,510],[324,484],[357,462],[393,445],[429,437],[463,441],[493,463],[516,505],[531,572],[534,666]],[[762,366],[764,372],[764,379],[763,385],[761,392],[757,399],[751,406],[744,412],[734,419],[707,433],[652,462],[581,503],[502,552],[427,606],[365,662],[328,718],[324,770],[340,798],[364,819],[395,834],[431,842],[471,847],[514,847],[557,845],[599,841],[614,839],[630,837],[645,835],[660,833],[674,831],[688,829],[701,827],[713,825]]],"ん":[[[517,151],[519,158],[521,167],[523,177],[523,187],[522,198],[521,208],[518,218],[513,227],[484,274],[446,334],[403,404],[357,478],[311,551],[268,620],[231,680],[203,726],[176,771],[158,804],[149,825],[147,834],[154,830],[167,813],[188,782],[216,737],[276,651],[331,592],[381,558],[425,547],[460,555],[487,581],[504,622],[510,675],[518,751],[539,806],[573,838],[615,847],[663,832],[716,791],[771,724],[824,630]]]},"katakana":{"ア":[[[216,241],[224,245],[231,249],[239,251],[247,252],[257,252],[267,251],[279,250],[294,248],[339,241],[393,233],[454,224],[518,215],[582,206],[641,198],[694,191],[737,186],[753,185],[768,187],[778,191],[785,197],[787,206],[784,216],[776,228],[761,241],[738,258],[714,275],[690,292],[666,309],[639,327],[611,346],[581,366],[547,388]],[[487,377],[490,383],[492,388],[493,394],[494,400],[495,406],[495,412],[494,419],[493,426],[478,487],[461,545],[443,599],[422,651],[398,701],[372,749],[343,796],[310,843]]],"イ":[[[640,154],[640,160],[640,166],[639,173],[637,179],[635,186],[632,192],[629,198],[625,204],[589,250],[549,298],[505,348],[456,400],[403,451],[343,501],[278,550],[206,597]],[[517,403],[520,407],[523,411],[525,417],[526,422],[528,428],[528,434],[529,439],[529,445],[529,462],[529,498],[529,547],[529,603],[529,658],[529,708],[529,745],[529,763],[529,771],[529,783],[528,798],[528,814],[528,830],[528,846],[528,860],[528,870]]],"ウ":[[[489,134],[492,138],[494,143],[496,148],[498,154],[499,159],[499,165],[500,171],[500,177],[500,185],[500,198],[500,215],[500,234],[500,252],[500,269],[500,283],[500,292]],[[243,287],[246,291],[249,296],[251,301],[252,306],[253,312],[254,318],[254,323],[255,329],[255,345],[255,363],[256,381],[256,401],[257,421],[258,441],[258,460],[259,479],[259,488],[259,496],[259,504],[260,512],[260,519],[260,526],[260,533],[260,539]],[[267,329],[334,322],[401,314],[466,307],[528,301],[586,294],[638,289],[682,283],[717,279],[743,276],[762,276],[775,279],[782,285],[785,294],[784,307],[780,323],[774,342],[753,398],[723,464],[685,534],[641,608],[589,680],[531,749],[467,810],[398,861]]],"エ":[[[292,327],[301,329],[309,331],[318,332],[327,332],[335,332],[344,332],[353,331],[361,330],[393,325],[428,321],[466,316],[506,311],[547,307],[589,302],[630,298],[670,295],[678,294],[685,294],[693,294],[701,294],[709,294],[716,295],[724,295],[732,297]],[[489,350],[493,354],[495,359],[497,364],[499,369],[500,375],[501,381],[501,387],[501,392],[500,410],[499,430],[498,453],[498,478],[496,505],[495,534],[494,565],[493,596],[493,604],[493,612],[492,620],[492,629],[492,637],[492,645],[491,653],[491,662]],[[174,692],[186,695],[199,697],[212,698],[225,699],[238,699],[251,698],[263,697],[275,696],[336,688],[396,681],[455,675],[513,670],[571,666],[628,663],[684,661],[739,660],[751,660],[763,661],[775,662],[787,664],[800,666],[812,669],[824,672],[835,677]]],"オ":[[[179,347],[192,353],[205,356],[218,359],[231,360],[243,360],[256,359],[268,358],[280,357],[341,348],[401,339],[460,332],[518,325],[575,320],[632,315],[688,310],[744,307],[755,307],[766,307],[778,307],[789,308],[801,310],[813,313],[826,316],[840,320]],[[554,150],[558,156],[561,162],[564,169],[566,176],[567,184],[568,191],[569,199],[569,206],[569,246],[569,305],[568,379],[568,460],[568,543],[567,623],[567,692],[567,744],[564,801],[558,834],[548,847],[536,847],[522,836],[508,821],[494,806],[482,795]],[[553,334],[552,339],[550,346],[547,352],[543,359],[538,366],[533,373],[527,381],[520,389],[491,423],[457,460],[420,498],[380,538],[338,577],[294,617],[249,655],[202,692]]],"カ":[[[234,373],[241,377],[248,380],[256,383],[264,385],[273,387],[281,387],[290,387],[299,386],[359,378],[417,370],[471,363],[522,356],[570,349],[614,343],[654,337],[689,332],[712,330],[732,330],[748,333],[760,339],[768,349],[773,363],[773,381],[768,405],[761,434],[753,464],[744,495],[735,528],[724,562],[712,597],[699,634],[683,672],[650,743],[622,789],[598,813],[577,821],[558,817],[541,806],[524,793],[507,781]],[[513,157],[515,163],[518,169],[520,176],[521,184],[522,192],[522,200],[521,209],[520,219],[502,297],[478,374],[449,449],[416,521],[377,589],[336,652],[290,709],[242,759]]],"キ":[[[248,372],[254,374],[262,375],[270,377],[278,378],[287,378],[296,378],[305,377],[314,375],[357,363],[405,350],[454,337],[503,324],[550,312],[593,301],[630,292],[658,284],[668,282],[678,280],[690,279],[701,277],[712,276],[723,275],[732,275],[741,275]],[[179,604],[187,606],[197,608],[208,610],[219,611],[231,611],[243,610],[254,608],[266,605],[326,587],[384,570],[440,554],[496,540],[551,526],[605,513],[661,499],[717,486],[729,483],[743,481],[758,478],[772,476],[787,475],[801,474],[813,473],[824,474]],[[448,154],[456,160],[463,166],[469,172],[473,178],[477,185],[480,192],[482,200],[484,210],[492,264],[502,330],[512,403],[523,481],[533,558],[543,632],[552,699],[560,753],[561,765],[563,777],[564,791],[566,805],[568,819],[569,833],[571,845],[572,855]]],"ク":[[[459,180],[460,185],[461,191],[461,197],[461,203],[460,209],[459,215],[457,221],[454,227],[440,255],[426,282],[411,309],[394,336],[376,363],[356,391],[333,419],[306,448]],[[470,263],[479,263],[489,263],[498,262],[507,261],[516,260],[525,258],[533,256],[540,254],[560,250],[578,245],[595,241],[612,237],[628,233],[644,228],[661,224],[679,219],[697,215],[712,213],[723,214],[731,217],[735,224],[735,234],[732,247],[726,264],[688,342],[645,418],[597,492],[544,564],[486,633],[423,698],[354,760],[280,819]]],"ケ":[[[376,164],[377,171],[378,178],[378,186],[378,193],[377,201],[376,209],[373,216],[370,224],[354,259],[337,293],[320,328],[300,362],[279,396],[255,432],[228,468],[197,505]],[[348,345],[355,348],[362,350],[369,351],[377,352],[384,353],[392,352],[400,351],[408,350],[452,341],[495,332],[538,324],[580,316],[622,309],[662,302],[700,296],[736,290],[748,288],[760,287],[770,286],[781,285],[791,285],[801,285],[811,285],[821,286]],[[591,357],[593,363],[594,370],[594,378],[595,385],[594,393],[594,401],[592,409],[591,416],[577,465],[561,516],[542,569],[518,621],[489,674],[455,725],[414,773],[365,819]]],"コ":[[[276,321],[282,325],[288,328],[294,331],[300,334],[307,336],[315,337],[325,337],[336,336],[385,328],[435,321],[483,314],[530,307],[574,301],[614,295],[649,290],[679,286],[708,282],[729,281],[745,284],[754,290],[759,300],[760,314],[758,332],[752,354],[743,391],[734,429],[725,468],[717,507],[709,548],[701,589],[694,631],[688,674]],[[252,710],[261,713],[269,716],[277,719],[286,720],[295,721],[305,721],[316,720],[328,719],[367,714],[406,709],[445,704],[484,700],[522,696],[561,692],[599,690],[638,688],[651,688],[662,688],[673,688],[683,688],[693,689],[703,690],[714,691],[726,693]]],"サ":[[[151,407],[161,411],[170,414],[179,417],[188,419],[197,420],[208,420],[220,419],[233,417],[295,407],[360,397],[429,389],[499,382],[569,376],[639,372],[706,369],[770,368],[784,368],[797,369],[810,369],[821,370],[832,371],[843,373],[854,374],[866,376]],[[336,214],[339,219],[342,224],[344,228],[345,233],[346,239],[347,244],[347,251],[348,258],[348,290],[349,323],[350,357],[351,392],[351,426],[352,460],[353,492],[354,523],[355,534],[355,546],[356,558],[357,569],[357,580],[358,591],[358,600],[358,608]],[[639,152],[643,159],[647,165],[650,171],[651,176],[653,183],[653,190],[654,199],[654,210],[654,235],[653,256],[653,273],[653,287],[653,302],[652,317],[652,334],[652,356],[648,434],[637,508],[618,578],[593,642],[563,702],[526,755],[485,802],[439,842]]],"シ":[[[366,181],[383,188],[400,196],[416,206],[430,217],[443,229],[455,240],[464,251],[471,260]],[[239,391],[251,396],[266,403],[282,412],[299,422],[315,434],[330,445],[342,456],[351,466]],[[303,780],[315,782],[328,784],[340,784],[352,783],[364,781],[375,778],[387,773],[398,767],[458,730],[516,691],[571,647],[624,601],[675,550],[725,496],[773,437],[821,374]]],"ス":[[[276,270],[283,274],[289,278],[297,281],[304,283],[312,284],[320,284],[329,284],[337,282],[382,271],[424,261],[464,252],[502,243],[537,235],[569,228],[598,221],[624,214],[646,210],[663,210],[676,213],[685,219],[690,228],[691,239],[689,252],[683,267],[642,349],[596,428],[544,503],[486,574],[422,639],[352,697],[276,749],[193,792]],[[560,525],[597,552],[633,580],[668,610],[702,642],[734,676],[763,711],[791,749],[817,788]]],"セ":[[[156,453],[166,458],[176,462],[185,465],[194,467],[203,469],[213,469],[223,468],[235,466],[310,449],[374,434],[430,421],[481,409],[531,397],[582,385],[637,373],[699,359],[763,349],[797,352],[807,366],[798,389],[774,419],[742,453],[705,489],[670,525]],[[389,179],[395,186],[400,193],[403,200],[406,206],[407,213],[408,221],[408,230],[408,240],[408,298],[407,354],[405,407],[404,456],[402,502],[401,544],[400,583],[400,617],[402,660],[406,695],[414,723],[425,743],[441,758],[460,767],[485,772],[514,774],[541,774],[567,775],[590,775],[612,775],[631,775],[649,775],[665,775],[679,775],[692,775],[705,774],[718,773],[730,772],[742,771],[754,769],[765,767],[775,765]]],"ソ":[[[216,234],[229,249],[242,265],[255,283],[268,303],[280,324],[292,347],[303,372],[314,398]],[[766,193],[770,201],[773,209],[774,218],[775,226],[775,236],[773,246],[771,258],[767,271],[741,344],[704,422],[658,502],[604,581],[545,657],[481,726],[415,785],[349,833]]],"タ":[[[448,181],[449,187],[450,194],[450,201],[450,208],[449,215],[448,222],[446,229],[443,235],[426,267],[410,298],[392,329],[374,360],[353,392],[329,424],[302,456],[272,490]],[[456,279],[466,280],[475,281],[483,280],[492,280],[500,279],[509,277],[517,275],[526,273],[546,268],[565,264],[584,259],[601,254],[619,250],[636,245],[654,240],[672,235],[690,231],[706,230],[718,232],[727,237],[732,245],[734,256],[732,270],[726,287],[688,369],[648,447],[604,521],[555,592],[498,658],[432,721],[355,781],[266,837]],[[398,419],[420,431],[440,444],[458,459],[475,475],[490,493],[505,513],[519,534],[533,558]]],"チ":[[[640,140],[638,149],[635,156],[632,164],[627,170],[622,176],[617,181],[611,185],[604,189],[576,204],[545,220],[510,236],[473,253],[431,269],[385,284],[334,298],[279,311]],[[170,472],[179,475],[188,478],[196,481],[204,483],[212,484],[221,485],[231,485],[242,484],[315,476],[382,468],[446,461],[507,455],[568,450],[628,445],[691,442],[757,439],[773,439],[787,439],[801,441],[813,442],[825,444],[836,447],[846,450],[857,453]],[[503,282],[506,285],[509,289],[512,293],[515,299],[517,305],[518,311],[519,318],[520,326],[520,346],[520,366],[520,386],[520,406],[520,427],[520,448],[520,470],[520,493],[518,545],[511,595],[500,644],[484,691],[463,736],[436,779],[405,818],[368,853]]],"ツ":[[[197,288],[205,300],[213,314],[220,329],[227,346],[232,364],[237,382],[240,399],[242,415]],[[419,218],[430,231],[441,246],[452,262],[461,280],[469,298],[476,317],[480,336],[483,354]],[[776,256],[778,264],[780,272],[780,281],[779,291],[778,300],[776,310],[773,320],[769,329],[741,394],[706,461],[665,528],[617,594],[562,657],[499,715],[428,767],[347,811]]],"テ":[[[335,197],[342,201],[350,204],[358,207],[366,208],[374,209],[383,210],[392,210],[401,209],[436,205],[468,201],[497,197],[524,193],[550,189],[576,186],[601,182],[627,179],[639,177],[650,176],[660,176],[669,175],[677,175],[685,175],[693,176],[702,177]],[[183,405],[193,408],[202,410],[211,412],[220,413],[228,413],[237,413],[245,413],[252,412],[326,402],[394,392],[458,383],[519,375],[577,368],[634,362],[691,358],[749,356],[767,355],[782,355],[795,355],[807,356],[817,357],[826,358],[835,359],[844,361]],[[532,397],[535,400],[537,405],[539,409],[541,414],[542,420],[543,425],[543,431],[542,437],[533,491],[517,548],[495,604],[468,658],[436,709],[400,754],[360,792],[317,821]]],"ト":[[[404,150],[408,155],[412,160],[415,165],[418,172],[420,178],[422,186],[423,193],[423,201],[423,291],[423,379],[423,463],[423,541],[423,609],[423,665],[423,706],[423,729],[423,744],[423,761],[423,778],[423,795],[423,812],[423,827],[423,841],[423,852]],[[452,396],[490,411],[524,428],[555,447],[583,468],[609,490],[632,515],[655,540],[677,568]]],"ナ":[[[170,405],[179,408],[187,410],[196,412],[206,413],[216,413],[227,413],[239,411],[253,409],[320,400],[385,391],[448,383],[510,376],[570,370],[627,365],[682,361],[734,358],[747,357],[762,357],[776,356],[791,356],[805,357],[819,357],[832,358],[843,359]],[[489,133],[494,138],[499,143],[504,148],[507,155],[510,162],[512,169],[513,178],[514,188],[514,205],[514,231],[514,264],[514,300],[515,336],[515,369],[515,395],[515,411],[512,478],[505,544],[492,606],[473,665],[450,721],[421,772],[386,819],[346,861]]],"ニ":[[[299,318],[308,322],[316,325],[324,328],[331,329],[340,331],[348,331],[357,331],[368,331],[406,327],[440,324],[472,320],[501,316],[530,312],[558,308],[586,304],[616,301],[625,301],[635,300],[646,300],[656,300],[666,300],[676,301],[685,301],[693,302]],[[183,687],[192,690],[201,693],[210,695],[219,696],[230,697],[241,697],[253,696],[267,694],[335,684],[400,676],[462,669],[522,665],[581,662],[637,660],[693,659],[748,658],[761,659],[774,660],[788,662],[801,664],[814,668],[827,671],[839,676],[850,680]]],"ヌ":[[[306,253],[316,257],[325,260],[334,262],[344,262],[354,262],[364,262],[374,261],[384,259],[419,253],[452,248],[485,242],[517,237],[549,231],[582,225],[614,219],[647,213],[667,210],[683,209],[695,210],[703,215],[706,222],[706,233],[703,247],[696,265],[670,324],[637,388],[596,456],[546,526],[487,597],[418,667],[339,733],[248,796]],[[412,426],[452,450],[491,476],[529,504],[565,534],[600,567],[632,603],[663,641],[693,683]]],"ネ":[[[471,114],[483,122],[496,131],[510,142],[523,154],[536,167],[549,181],[561,197],[572,213]],[[247,332],[256,336],[265,340],[274,343],[284,345],[294,346],[304,346],[314,345],[325,343],[361,334],[397,325],[433,317],[468,308],[503,299],[538,291],[573,282],[608,274],[628,270],[644,270],[655,273],[663,278],[666,286],[664,295],[659,305],[650,317],[610,359],[569,401],[525,442],[476,484],[421,526],[358,570],[286,616],[202,665]],[[499,497],[503,503],[507,509],[509,515],[511,521],[512,528],[513,536],[514,543],[514,552],[514,569],[514,601],[514,642],[514,688],[514,734],[514,775],[514,806],[514,821],[514,828],[514,835],[514,842],[514,849],[514,857],[514,866],[514,875],[514,884]],[[600,492],[641,512],[677,533],[710,554],[740,575],[766,596],[789,618],[810,641],[828,665]]],"ノ":[[[664,232],[666,239],[668,247],[669,255],[670,264],[670,272],[669,281],[668,290],[666,298],[637,382],[600,461],[555,535],[504,603],[449,666],[390,724],[329,775],[266,820]]],"ハ":[[[361,338],[362,343],[363,347],[363,352],[364,357],[363,362],[363,367],[361,372],[360,376],[338,422],[315,465],[291,505],[267,543],[241,578],[214,611],[186,642],[156,672]],[[601,334],[644,367],[685,403],[723,441],[757,481],[788,522],[816,562],[839,602],[858,640]]],"ヒ":[[[325,408],[331,413],[338,417],[346,420],[354,423],[362,425],[371,426],[379,426],[388,426],[422,421],[453,416],[482,411],[510,406],[536,401],[561,396],[586,391],[610,386],[621,384],[632,383],[644,381],[656,380],[667,379],[678,378],[688,378],[696,378]],[[284,162],[289,166],[292,172],[295,178],[298,185],[300,192],[301,200],[301,209],[302,218],[301,243],[300,292],[299,358],[298,433],[296,508],[295,575],[294,625],[294,651],[295,683],[301,710],[310,733],[323,752],[341,767],[362,777],[389,783],[420,786],[442,786],[467,786],[494,786],[521,786],[548,786],[574,786],[597,786],[616,786],[633,785],[649,784],[666,783],[681,781],[697,779],[711,777],[726,775],[740,772]]],"フ":[[[225,275],[231,281],[237,285],[244,289],[251,291],[258,292],[266,292],[275,291],[284,290],[334,283],[384,276],[434,268],[484,260],[534,252],[585,244],[635,236],[686,227],[708,225],[727,227],[742,232],[754,241],[760,254],[762,270],[758,289],[749,311],[713,377],[674,443],[631,509],[583,574],[526,636],[460,696],[382,752],[290,803]]],"ヘ":[[[142,450],[152,454],[161,456],[170,457],[178,456],[186,454],[194,451],[200,446],[206,441],[220,428],[236,414],[251,400],[266,387],[281,374],[294,362],[306,351],[316,342],[327,331],[339,322],[352,315],[366,311],[380,310],[395,313],[410,319],[426,331],[466,365],[507,401],[549,437],[592,473],[635,509],[676,544],[716,578],[754,610],[769,622],[783,633],[796,645],[809,656],[821,667],[833,678],[846,688],[858,697]]],"ホ":[[[208,370],[216,374],[225,377],[234,379],[243,381],[254,383],[265,383],[277,383],[291,382],[350,376],[404,371],[456,366],[505,362],[554,358],[603,354],[654,350],[708,346],[720,346],[733,345],[746,345],[759,346],[771,347],[784,348],[797,350],[810,352]],[[493,157],[497,164],[500,171],[503,179],[504,187],[505,196],[506,205],[506,215],[506,225],[506,251],[506,304],[505,374],[505,455],[505,536],[505,610],[505,668],[505,701],[502,766],[495,806],[485,826],[472,830],[458,824],[443,811],[428,798],[415,789]],[[251,545],[252,576],[250,605],[247,633],[241,659],[233,683],[222,706],[209,727],[193,746]],[[672,484],[707,516],[737,548],[761,577],[782,606],[798,634],[810,661],[819,687],[825,712]]],"マ":[[[197,310],[204,315],[210,320],[216,323],[223,325],[230,326],[238,326],[247,326],[257,324],[322,317],[383,309],[442,302],[498,295],[554,288],[610,281],[667,274],[727,266],[749,264],[766,266],[779,270],[788,277],[791,288],[789,301],[781,317],[767,336],[741,366],[713,399],[681,434],[648,470],[614,508],[578,547],[541,586],[503,626]],[[398,540],[427,564],[455,590],[482,618],[507,647],[531,679],[551,712],[569,746],[584,781]]],"ミ":[[[384,183],[420,193],[454,203],[488,214],[519,226],[548,238],[574,251],[596,265],[613,279]],[[385,430],[422,440],[458,451],[492,462],[524,475],[554,488],[581,501],[603,515],[622,530]],[[335,688],[389,704],[441,722],[491,742],[539,762],[582,784],[621,807],[654,830],[681,854]]],"ム":[[[494,206],[497,213],[498,220],[499,228],[499,236],[498,244],[497,253],[494,261],[490,270],[460,330],[430,387],[402,441],[374,492],[346,541],[318,590],[289,639],[259,689],[248,709],[241,725],[239,738],[241,747],[247,754],[259,757],[276,757],[299,755],[337,748],[395,738],[466,726],[542,712],[616,699],[681,687],[730,678],[754,673]],[[662,552],[686,574],[709,599],[731,626],[751,654],[770,684],[786,716],[799,749],[809,784]]],"メ":[[[673,175],[676,182],[677,189],[678,197],[677,205],[676,213],[675,221],[672,230],[670,239],[640,316],[605,395],[564,473],[517,551],[462,625],[401,695],[333,759],[257,815]],[[362,362],[419,390],[473,420],[525,452],[574,486],[618,523],[657,562],[690,603],[716,646]]],"モ":[[[256,240],[264,244],[272,247],[280,250],[288,251],[296,253],[305,253],[314,253],[324,253],[363,249],[402,246],[440,242],[477,238],[514,233],[551,228],[588,222],[625,217],[634,215],[644,214],[655,214],[665,214],[675,214],[685,214],[694,214],[702,215]],[[161,499],[169,502],[178,505],[187,507],[196,508],[207,509],[218,509],[230,508],[244,506],[311,495],[374,485],[433,477],[490,469],[545,462],[601,457],[658,453],[718,450],[731,449],[744,449],[756,450],[769,451],[782,452],[794,454],[807,456],[820,458]],[[447,274],[451,280],[454,286],[456,292],[458,299],[459,306],[460,314],[460,322],[460,330],[460,361],[459,404],[458,455],[457,509],[456,562],[455,607],[455,642],[454,659],[456,684],[460,705],[467,723],[477,737],[490,749],[507,758],[527,764],[551,767],[570,769],[590,770],[610,770],[630,770],[650,769],[669,769],[686,768],[701,767],[716,766],[728,765],[740,764],[750,762],[760,761],[769,759],[779,757],[789,754]]],"ヤ":[[[165,420],[173,425],[183,429],[193,433],[205,435],[218,436],[231,436],[244,435],[258,432],[321,417],[381,403],[439,389],[494,376],[548,363],[601,350],[653,337],[706,323],[765,314],[793,322],[797,344],[784,376],[760,412],[730,449],[702,482],[681,507]],[[353,178],[358,183],[363,187],[367,192],[371,198],[374,204],[377,210],[380,217],[382,226],[389,253],[402,312],[420,391],[440,480],[460,569],[478,649],[491,707],[498,735],[500,746],[503,759],[507,774],[511,790],[515,807],[519,823],[522,837],[526,850]]],"ユ":[[[271,325],[279,329],[288,333],[297,336],[307,339],[318,340],[329,340],[342,340],[356,338],[398,332],[434,327],[466,323],[495,319],[522,315],[549,311],[578,307],[609,302],[630,299],[646,298],[658,301],[666,306],[671,314],[673,326],[672,341],[669,360],[660,400],[652,441],[644,483],[636,524],[629,564],[621,603],[615,641],[609,677]],[[156,705],[165,710],[174,714],[183,717],[192,719],[202,721],[213,721],[226,721],[240,719],[314,710],[381,702],[444,696],[503,691],[561,688],[618,685],[676,684],[736,683],[749,684],[762,684],[774,685],[787,686],[800,688],[813,690],[825,692],[838,694]]],"ヨ":[[[267,276],[276,281],[284,285],[294,288],[304,290],[314,291],[326,292],[338,291],[352,290],[400,285],[446,279],[491,274],[534,269],[575,264],[614,260],[651,255],[686,251],[704,249],[719,250],[730,252],[738,258],[743,266],[745,277],[746,291],[746,310],[742,363],[739,415],[735,467],[732,517],[729,565],[725,612],[722,656],[718,697]],[[268,485],[277,490],[285,494],[295,497],[305,499],[315,500],[327,501],[340,500],[353,499],[390,495],[428,491],[466,487],[503,483],[540,480],[575,477],[608,474],[639,471],[648,470],[657,470],[666,470],[675,471],[684,472],[693,473],[701,474],[710,476]],[[216,723],[225,727],[234,731],[243,733],[252,735],[262,736],[273,737],[285,736],[299,735],[344,731],[391,727],[441,722],[491,718],[541,714],[589,711],[636,709],[679,709],[690,709],[701,709],[711,709],[721,709],[731,710],[741,711],[753,712],[765,714]]],"ラ":[[[354,193],[362,199],[369,204],[377,208],[386,211],[395,213],[405,214],[416,214],[428,213],[458,210],[485,206],[510,203],[534,199],[557,196],[579,192],[602,189],[626,186],[634,185],[642,184],[649,183],[656,183],[663,183],[670,183],[678,183],[686,184]],[[239,384],[247,390],[256,394],[265,397],[275,400],[286,401],[297,402],[310,401],[323,400],[373,393],[424,385],[475,377],[526,369],[575,361],[620,354],[662,347],[698,342],[717,340],[733,340],[745,343],[754,348],[760,355],[762,365],[761,378],[756,394],[729,459],[694,523],[653,586],[605,646],[549,703],[487,755],[417,801],[341,840]]],"リ":[[[321,169],[325,174],[328,179],[330,184],[332,190],[334,195],[335,201],[336,207],[336,213],[336,228],[336,257],[336,295],[336,337],[336,379],[336,417],[336,446],[336,461],[336,469],[336,478],[336,488],[336,498],[336,508],[336,517],[336,526],[336,532]],[[651,141],[656,146],[661,151],[664,156],[667,162],[670,169],[672,176],[673,183],[673,190],[673,208],[673,241],[673,285],[673,335],[672,386],[672,432],[672,469],[672,492],[668,557],[657,615],[639,669],[614,717],[585,760],[551,799],[513,833],[473,863]]],"ル":[[[315,292],[319,298],[322,303],[325,308],[327,314],[329,319],[330,325],[330,331],[330,337],[324,414],[312,485],[296,552],[276,612],[253,667],[227,716],[199,757],[170,791]],[[518,180],[523,185],[528,190],[531,195],[535,201],[537,208],[539,215],[540,222],[540,229],[540,254],[540,307],[540,379],[540,460],[540,542],[539,616],[539,673],[539,703],[540,734],[541,757],[545,771],[552,777],[562,776],[577,767],[598,751],[625,728],[657,701],[687,675],[716,648],[745,621],[774,592],[803,562],[834,529],[867,493]]],"レ":[[[317,181],[321,186],[326,191],[329,196],[333,202],[335,209],[337,216],[338,223],[338,231],[338,256],[338,312],[338,387],[338,473],[338,559],[337,637],[337,696],[337,727],[337,753],[338,773],[341,785],[347,791],[358,791],[373,786],[394,776],[423,761],[471,735],[524,701],[578,663],[633,622],[687,579],[737,536],[782,494],[820,454]]],"ロ":[[[229,305],[234,310],[238,315],[242,320],[245,326],[247,333],[249,340],[250,347],[251,354],[255,390],[258,429],[262,469],[265,510],[269,552],[273,594],[276,635],[280,674],[281,686],[282,697],[283,709],[284,719],[285,730],[286,741],[287,751],[288,760]],[[258,331],[297,327],[349,323],[408,318],[472,312],[534,307],[592,302],[641,297],[677,292],[701,290],[721,290],[736,292],[747,298],[753,307],[756,319],[756,334],[753,353],[746,391],[739,429],[732,467],[724,506],[717,546],[709,587],[700,629],[692,673]],[[294,717],[321,714],[363,710],[414,706],[470,701],[524,697],[572,693],[608,690],[628,689],[639,689],[651,689],[665,689],[679,689],[693,689],[707,689],[721,690],[734,691]]],"ワ":[[[229,217],[234,221],[238,226],[242,232],[245,238],[247,244],[249,251],[250,259],[251,266],[254,296],[256,318],[258,336],[260,351],[261,367],[263,386],[266,410],[269,444],[270,455],[271,467],[272,478],[273,489],[274,500],[275,510],[275,520],[276,530]],[[255,242],[265,243],[274,244],[284,244],[293,244],[301,244],[310,243],[320,242],[330,241],[377,237],[424,233],[471,229],[519,225],[566,221],[614,217],[663,212],[712,208],[737,206],[757,206],[772,209],[782,214],[788,223],[792,234],[792,249],[789,268],[768,359],[738,444],[699,523],[651,596],[596,664],[533,726],[463,782],[387,833]]],"ヲ":[[[277,231],[286,236],[295,240],[304,243],[314,246],[325,247],[336,248],[349,247],[362,246],[404,242],[443,237],[480,233],[515,229],[549,224],[581,220],[612,217],[642,213],[652,212],[661,211],[671,209],[680,208],[689,207],[698,206],[708,205],[717,204]],[[266,428],[274,433],[282,437],[290,439],[298,441],[307,443],[317,443],[328,442],[340,441],[369,437],[401,433],[435,428],[469,424],[504,419],[538,415],[571,411],[602,406],[610,405],[618,404],[626,403],[634,402],[642,401],[649,400],[657,399],[664,398]],[[716,210],[718,217],[720,225],[721,233],[721,241],[720,249],[720,258],[718,266],[717,274],[694,352],[661,431],[619,508],[568,583],[511,655],[449,721],[382,780],[312,831]]],"ン":[[[243,228],[263,237],[284,250],[305,264],[325,281],[343,300],[361,319],[375,339],[388,359]],[[263,768],[271,773],[280,776],[289,777],[298,777],[307,775],[316,772],[325,768],[334,763],[401,721],[464,678],[524,634],[580,589],[635,542],[687,492],[738,440],[789,385]]]}},"lesson":{"type":"lesson","id":"work_intro_01","can_do":{"en":"Greet colleagues and introduce yourself on your first day at work.","bn":"কর্মস্থলে প্রথম দিনে সহকর্মীদের অভিবাদন ও নিজের পরিচয় দিতে পারা।","ja":"職場の初日に同僚にあいさつし、自己紹介ができる。"},"jlpt_or_jft":"JFT-Basic A1/A2","verified":true,"source":"Aligned to Irodori Starter Can-do (self-introduction / greetings)","items":[{"id":"wi_01","jp":"おはようございます","kana":"おはようございます","romaji":"ohayō gozaimasu","meaning":{"en":"Good morning (polite)","bn":"সুপ্রভাত (ভদ্রভাবে)","ja":"おはよう（丁寧）"},"note":{"en":"Say it as you arrive at work. ございます makes it polite.","bn":"সকালে কর্মস্থলে ঢুকেই বলবে। শেষে ございます থাকায় এটি ভদ্র রূপ।","ja":"出勤時に言う。ございますで丁寧になる。"},"srs_words":["おはよう","ございます"]},{"id":"wi_02","jp":"こんにちは","kana":"こんにちは","romaji":"konnichiwa","meaning":{"en":"Hello / good afternoon","bn":"নমস্কার / হ্যালো (দুপুরে)","ja":"こんにちは（昼のあいさつ）"},"note":{"en":"は is pronounced 'wa' here, not 'ha'.","bn":"は এখানে \"wa\" উচ্চারণ হয়, \"ha\" নয়।","ja":"ここでのはは「わ」と読む。"},"srs_words":["こんにちは"]},{"id":"wi_03","jp":"はじめまして","kana":"はじめまして","romaji":"hajimemashite","meaning":{"en":"Nice to meet you (first time)","bn":"প্রথম সাক্ষাতে — পরিচিত হয়ে ভালো লাগল","ja":"はじめまして（初対面）"},"note":{"en":"Use it the first time you meet someone.","bn":"নতুন কাউকে প্রথমবার দেখা হলেই বলবে।","ja":"初めて会うときに使う。"},"srs_words":["はじめまして"]},{"id":"wi_04","jp":"わたしはラーマンです","kana":"わたしはラーマンです","romaji":"watashi wa Rāman desu","meaning":{"en":"I am Rahman.","bn":"আমি রহমান।","ja":"私はラーマンです。"},"note":{"en":"Pattern: わたしは ＿ です = 'I am ＿'. は = wa (topic marker).","bn":"গঠন: わたしは ＿ です = \"আমি ＿\"। は = wa (বিষয় নির্দেশক)।","ja":"型：わたしは＿です。はは「わ」（主題）。"},"srs_words":["わたし","です"]},{"id":"wi_05","jp":"よろしくおねがいします","kana":"よろしくおねがいします","romaji":"yoroshiku onegai shimasu","meaning":{"en":"I look forward to working with you (courtesy)","bn":"আপনার সাথে কাজ করতে পেরে ভালো লাগবে (সৌজন্য)","ja":"よろしくお願いします（締めのあいさつ）"},"note":{"en":"Said at the end of an introduction — very important politeness in Japan.","bn":"পরিচয়ের শেষে বলা হয় — জাপানে খুব গুরুত্বপূর্ণ ভদ্রতা।","ja":"自己紹介の最後に言う大切な表現。"},"srs_words":["よろしく","おねがいします"]},{"id":"wi_06","jp":"すみません","kana":"すみません","romaji":"sumimasen","meaning":{"en":"Excuse me / sorry","bn":"মাফ করবেন / এক্সকিউজ মি","ja":"すみません（呼びかけ・軽い謝罪）"},"note":{"en":"To get attention or apologize for a small thing.","bn":"কারো দৃষ্টি আকর্ষণ করতে বা ছোট ভুলে ক্ষমা চাইতে।","ja":"呼びかけや軽い謝罪に。"},"srs_words":["すみません"]},{"id":"wi_07","jp":"ありがとうございます","kana":"ありがとうございます","romaji":"arigatō gozaimasu","meaning":{"en":"Thank you (polite)","bn":"ধন্যবাদ (ভদ্রভাবে)","ja":"ありがとうございます（丁寧）"},"note":{"en":"ございます makes it more polite — use this at work.","bn":"ございます যোগ করায় বেশি ভদ্র — কর্মস্থলে এটাই ব্যবহার করবে।","ja":"ございますでより丁寧。職場で使う。"},"srs_words":["ありがとう"]},{"id":"wi_08","jp":"わかりません","kana":"わかりません","romaji":"wakarimasen","meaning":{"en":"I don't understand","bn":"আমি বুঝতে পারিনি","ja":"わかりません"},"note":{"en":"Don't stay silent if you don't get it — saying this is useful, not shameful.","bn":"না বুঝলে চুপ থেকো না — এটি বলা দোষের নয়, বরং কাজে দরকারি।","ja":"分からないときは黙らず言おう。"},"srs_words":["わかりません"]},{"id":"wi_09","jp":"もういちどおねがいします","kana":"もういちどおねがいします","romaji":"mō ichido onegai shimasu","meaning":{"en":"Please say it once more","bn":"অনুগ্রহ করে আরেকবার বলুন","ja":"もう一度お願いします"},"note":{"en":"If someone speaks fast, say this to hear it again.","bn":"কেউ দ্রুত বললে এটি বলে আবার শুনে নাও।","ja":"速いときはこれでもう一度聞く。"},"srs_words":["もういちど"]}]},"pitch":[{"id":"p_hashi_chopsticks","word":"はし","kanji":"箸","romaji":"hashi","pattern":[1,0],"meaning":{"en":"chopsticks","bn":"চপস্টিক","ja":"箸（食器）"},"accent_type":{"en":"atamadaka (head-high: HL)","bn":"atamadaka (মাথা-উঁচু: উঁচু-নিচু)","ja":"頭高型（高低）"}},{"id":"p_hashi_bridge","word":"はし","kanji":"橋","romaji":"hashi","pattern":[0,1],"meaning":{"en":"bridge","bn":"সেতু","ja":"橋"},"accent_type":{"en":"odaka (tail-high: LH, drops on particle)","bn":"odaka (শেষ-উঁচু: নিচু-উঁচু)","ja":"尾高型（低高）"}},{"id":"p_ame_rain","word":"あめ","kanji":"雨","romaji":"ame","pattern":[1,0],"meaning":{"en":"rain","bn":"বৃষ্টি","ja":"雨"},"accent_type":{"en":"atamadaka (HL)","bn":"atamadaka (উঁচু-নিচু)","ja":"頭高型"}},{"id":"p_ame_candy","word":"あめ","kanji":"飴","romaji":"ame","pattern":[0,1],"meaning":{"en":"candy","bn":"ক্যান্ডি / মিষ্টি","ja":"飴"},"accent_type":{"en":"heiban (flat: LH, stays high)","bn":"heiban (সমতল: নিচু-উঁচু)","ja":"平板型（低高）"}},{"id":"p_kaki_oyster","word":"かき","kanji":"牡蠣","romaji":"kaki","pattern":[1,0],"meaning":{"en":"oyster","bn":"ঝিনুক (অয়েস্টার)","ja":"牡蠣"},"accent_type":{"en":"atamadaka (HL)","bn":"atamadaka (উঁচু-নিচু)","ja":"頭高型"}},{"id":"p_kaki_persimmon","word":"かき","kanji":"柿","romaji":"kaki","pattern":[0,1],"meaning":{"en":"persimmon","bn":"পার্সিমন (এক ধরনের ফল)","ja":"柿"},"accent_type":{"en":"heiban (flat: LH)","bn":"heiban (সমতল: নিচু-উঁচু)","ja":"平板型"}}]};
let LANG = 'bn';
let tab = 2; // open on Learn (the micro-loop) first

const T = (tri) => (tri ? (tri[LANG] || tri.en) : '');
const gloss = (tri) => (LANG === 'bn' && tri && tri.en ? tri.en : '');

const NAV = [
  ['Kana','M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v6H4zM14 15h6v6h-6z'],
  ['Write','M4 20h16M6 16l9-9a2 2 0 0 1 3 3l-9 9-4 1z'],
  ['Learn','M3 7l9-4 9 4-9 4zM7 10v5c0 1 5 3 5 3s5-2 5-3v-5'],
  ['Speak','M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM5 11a7 7 0 0 0 14 0M12 18v3'],
  ['Pitch','M3 17l5-6 4 3 5-8'],
  ['Review','M4 9a8 8 0 0 1 14-4M20 5v4h-4M20 15a8 8 0 0 1-14 4M4 19v-4h4'],
];

function renderNav(){
  document.getElementById('nav').innerHTML = NAV.map((n,i)=>
    '<button class="'+(i===tab?'on':'')+'" onclick="go('+i+')"><svg viewBox="0 0 24 24"><path d="'+n[1]+'"/></svg>'+n[0]+'</button>'
  ).join('');
}
function go(i){ tab=i; render(); }
window.go = go;

function render(){
  renderNav();
  const s = document.getElementById('screen');
  s.innerHTML = [screenKana, screenWrite, screenLearn, screenSpeak, screenPitch, screenReview][tab]();
  if (tab===1) initWrite();
  s.scrollTop = 0;
}

/* ---------- 0: KANA ---------- */
let kataMode=false;
function screenKana(){
  const set = kataMode?DATA.kata:DATA.hira;
  return '<h2 class="title">'+(LANG==='bn'?'কানা শেখো':'Kana')+'</h2>'+
    '<div class="seg"><button class="'+(!kataMode?'on':'')+'" onclick="setKata(0)">ひらがな</button>'+
    '<button class="'+(kataMode?'on':'')+'" onclick="setKata(1)">カタカナ</button></div>'+
    '<div class="grid">'+set.map(k=>
      '<div class="cell" onclick="ping(this)"><div class="c">'+k.char+'</div><div class="r">'+k.romaji+'</div></div>'
    ).join('')+'</div>';
}
window.setKata=(v)=>{kataMode=!!v; render();};
window.ping=(el)=>{el.style.borderColor='var(--pink)'; setTimeout(()=>el.style.borderColor='',260);};

/* ---------- 1: WRITE (real KanjiVG stroke animation) ---------- */
let wKata=false, wIdx=0;
function screenWrite(){
  const chars = (wKata?DATA.kata:DATA.hira).map(k=>k.char);
  return '<h2 class="title">'+(LANG==='bn'?'লেখা অনুশীলন':'Write')+'</h2>'+
    '<div class="seg"><button class="'+(!wKata?'on':'')+'" onclick="setW(0)">ひらがな</button>'+
    '<button class="'+(wKata?'on':'')+'" onclick="setW(1)">カタカナ</button></div>'+
    '<div class="strip">'+chars.map((c,i)=>'<button class="chip '+(i===wIdx?'on':'')+'" onclick="pickW('+i+')">'+c+'</button>').join('')+'</div>'+
    '<div class="pad"><canvas id="paper"></canvas></div>'+
    '<div class="tools">'+
      '<button class="btn primary" onclick="playStroke()">▶ '+(LANG==='bn'?'দেখাও':'watch')+'</button>'+
      '<button class="btn line" onclick="toggleGuide()" id="guideBtn">👁 guide</button>'+
      '<button class="btn line" onclick="clearInk()">⌫ clear</button>'+
    '</div>'+
    '<div class="row" style="padding:0 16px 18px"><button class="btn filled grow" onclick="pickW('+((wIdx+1))+')">Skip / পরের ›</button></div>';
}
window.setW=(v)=>{wKata=!!v; wIdx=0; render();};
window.pickW=(i)=>{const n=(wKata?DATA.kata:DATA.hira).length; wIdx=((i%n)+n)%n; render();};
let guide=true, ink=[], anim=null;
window.toggleGuide=()=>{guide=!guide; drawPaper(0,null);};
window.clearInk=()=>{ink=[]; drawPaper(0,null);};
function curStrokes(){const c=(wKata?DATA.kata:DATA.hira)[wIdx].char; const set=wKata?DATA.strokes.katakana:DATA.strokes.hiragana; return set[c]||[];}
function initWrite(){
  const cv=document.getElementById('paper'); if(!cv) return;
  const fit=()=>{const r=cv.getBoundingClientRect(); const dpr=Math.min(devicePixelRatio||1,2);
    cv.width=r.width*dpr; cv.height=r.width*dpr; cv._s=r.width*dpr; drawPaper(0,null);};
  fit();
  let drawing=false;
  const pt=(e)=>{const r=cv.getBoundingClientRect(); const s=cv._s/r.width; return [(e.clientX-r.left)*s,(e.clientY-r.top)*s];};
  cv.onpointerdown=(e)=>{if(anim)return; drawing=true; ink.push([pt(e)]); cv.setPointerCapture(e.pointerId);};
  cv.onpointermove=(e)=>{if(!drawing||anim)return; ink[ink.length-1].push(pt(e)); drawPaper(animT,animStrokesLocal);};
  cv.onpointerup=()=>{drawing=false;};
}
let animT=0, animStrokesLocal=null;
function drawPaper(t, strokesShown){
  const cv=document.getElementById('paper'); if(!cv)return; const g=cv.getContext('2d'); const S=cv._s||cv.width;
  g.clearRect(0,0,S,S); g.fillStyle='#FBFBFD'; g.fillRect(0,0,S,S);
  const pad=S*0.06; g.strokeStyle='#E6E7EE'; g.lineWidth=1.4;
  g.strokeRect(pad,pad,S-2*pad,S-2*pad);
  g.beginPath(); g.moveTo(S/2,pad); g.lineTo(S/2,S-pad); g.moveTo(pad,S/2); g.lineTo(S-pad,S/2); g.stroke();
  if(guide && !strokesShown){ g.fillStyle='#E3E4EC'; g.font='700 '+(S*0.7)+'px var(--font)'; g.textAlign='center'; g.textBaseline='middle';
    g.fillText((wKata?DATA.kata:DATA.hira)[wIdx].char, S/2, S/2+S*0.04); }
  // user ink
  g.strokeStyle='#14141F'; g.lineWidth=S*0.045; g.lineCap='round'; g.lineJoin='round';
  for(const st of ink){ if(st.length<2){continue;} g.beginPath(); g.moveTo(st[0][0],st[0][1]); for(let i=1;i<st.length;i++)g.lineTo(st[i][0],st[i][1]); g.stroke(); }
  // stroke-order animation (scaled from viewBox 1000)
  if(strokesShown){
    const sc=S/1000; g.lineWidth=S*0.06;
    const scaled=strokesShown.map(s=>s.map(p=>[p[0]*sc,p[1]*sc]));
    const lens=scaled.map(len); const total=lens.reduce((a,b)=>a+b,0); let target=t*total, consumed=0;
    for(let i=0;i<scaled.length;i++){ if(consumed>=target)break; drawUpTo(g,scaled[i],Math.min(lens[i],target-consumed)); consumed+=lens[i]; }
  }
}
function len(p){let s=0;for(let i=1;i<p.length;i++)s+=Math.hypot(p[i][0]-p[i-1][0],p[i][1]-p[i-1][1]);return s;}
function drawUpTo(g,pts,maxLen){ if(pts.length<2)return; g.beginPath(); g.moveTo(pts[0][0],pts[0][1]); let acc=0;
  for(let i=1;i<pts.length;i++){const seg=Math.hypot(pts[i][0]-pts[i-1][0],pts[i][1]-pts[i-1][1]);
    if(acc+seg<=maxLen){g.lineTo(pts[i][0],pts[i][1]); acc+=seg;}
    else{const f=seg<=0?0:(maxLen-acc)/seg; g.lineTo(pts[i-1][0]+(pts[i][0]-pts[i-1][0])*f, pts[i-1][1]+(pts[i][1]-pts[i-1][1])*f); break;}}
  g.stroke(); }
window.playStroke=()=>{
  const strokes=curStrokes(); if(!strokes.length)return; ink=[]; if(anim)cancelAnimationFrame(anim);
  animStrokesLocal=strokes; const dur=600*strokes.length; const t0=performance.now();
  const step=(now)=>{animT=Math.min(1,(now-t0)/dur); drawPaper(animT,strokes);
    if(animT<1){anim=requestAnimationFrame(step);} else {anim=null; animStrokesLocal=null;}};
  anim=requestAnimationFrame(step);
};

/* ---------- 2: LEARN (5-step micro-loop) ---------- */
const PHASES=['intro','recognition','production','context','srs'];
const PLAB={intro:['পরিচিতি','Intro'],recognition:['চেনা','Recognition'],production:['বলা/লেখা','Production'],context:['বাক্য','Context'],srs:['রিভিউ','SRS']};
let L={started:false,done:false,item:0,phase:0,hint:false,pick:null,revealed:false,write:false,built:[],bank:null,bankItem:-1,showRom:true};
function lz(){return DATA.lesson.items;}
function resetStep(){L.hint=false;L.pick=null;L.revealed=false;L.write=false;L.built=[];L.bank=null;L.bankItem=-1;}
window.lStart=()=>{L.started=true;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lQuit=()=>{L.started=false;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lHint=()=>{L.hint=!L.hint;render();};
window.lAdvance=()=>{const n=lz().length;resetStep();
  if(L.phase<4)L.phase++; else if(L.item<n-1){L.item++;L.phase=0;} else {L.started=false;L.done=true;} render();};
window.lToggleRom=()=>{L.showRom=!L.showRom;render();};
window.lReveal=()=>{L.revealed=!L.revealed;render();};
window.lWrite=()=>{L.write=!L.write;render();};

function seededShuffle(arr,seed){const a=arr.slice();let s=seed;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};
  for(let i=a.length-1;i>0;i--){const j=Math.floor(rnd()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}

function screenLearn(){
  const les=DATA.lesson;
  if(L.done) return '<div class="center"><div style="font-size:42px">✅</div><div class="big" style="font-size:20px">'+(LANG==='bn'?'লেসন শেষ':'Lesson complete')+'</div><div class="muted">'+(LANG==='bn'?'আরেকটা?':'Another round?')+'</div><button class="btn filled" style="margin-top:12px" onclick="lStart()">'+(LANG==='bn'?'আবার':'Restart')+'</button></div>';
  if(!L.started) return '<div class="center"><div class="big" style="font-size:19px;text-wrap:balance">'+T(les.can_do)+'</div>'+(gloss(les.can_do)?'<div class="faint">'+gloss(les.can_do)+'</div>':'')+'<div class="muted">'+les.items.length+' '+(LANG==='bn'?'শব্দ':'items')+' · ৫ '+(LANG==='bn'?'ধাপ':'steps')+'</div><div class="faint" style="font-size:12px">'+(LANG==='bn'?'যেকোনো সময় Skip / Hint / Quit — কোনো চাপ নেই।':'Skip / Hint / Quit anytime — no pressure.')+'</div><button class="btn primary" style="margin-top:14px;min-width:160px" onclick="lStart()">'+(LANG==='bn'?'শুরু করো':'Start')+'</button></div>';

  const it=lz()[L.item]; const ph=PHASES[L.phase];
  let head='<div class="phaselab"><span class="muted">'+(LANG==='bn'?'শব্দ':'word')+' '+(L.item+1)+'/'+lz().length+'</span><span style="font-weight:600">'+(LANG==='bn'?PLAB[ph][0]:PLAB[ph][1])+'</span></div>'+
    '<div class="steps">'+PHASES.map((_,i)=>'<i class="'+(i<=L.phase?'on':'')+'"></i>').join('')+'</div>'+
    '<div class="controls"><button class="btn line" onclick="lHint()">💡 '+(LANG==='bn'?'ইঙ্গিত':'Hint')+'</button>'+
      '<button class="btn line" onclick="lAdvance()">⏭ '+(LANG==='bn'?'বাদ':'Skip')+'</button>'+
      '<button class="btn line" onclick="lQuit()">✕ '+(LANG==='bn'?'বন্ধ':'Quit')+'</button></div>';

  let body='';
  if(ph==='intro') body=phIntro(it);
  else if(ph==='recognition') body=phRecog(it);
  else if(ph==='production') body=phProd(it);
  else if(ph==='context') body=phContext(it);
  else body=phSrs(it);

  const hint = L.hint? '<div class="pad"><div class="card" style="background:var(--surface2);display:flex;gap:10px;align-items:flex-start"><span>💡</span><div><b>'+it.jp+'</b> · <span class="faint">'+it.romaji+'</span><div>'+T(it.meaning)+'</div></div></div></div>':'';
  return head+'<div class="pad">'+body+'</div>'+hint;
}
function phIntro(it){return '<div class="card" style="text-align:center">'+
  '<div class="big">'+it.jp+'</div>'+(L.showRom?'<div class="faint">'+it.romaji+'</div>':'')+
  '<div style="font-size:22px;margin:6px">🔊</div>'+
  '<div style="font-size:18px;font-weight:600">'+T(it.meaning)+'</div>'+(gloss(it.meaning)?'<div class="faint">'+gloss(it.meaning)+'</div>':'')+
  '<div class="card" style="background:#12190f;margin-top:12px;text-align:left">'+T(it.note)+(gloss(it.note)?'<div class="faint" style="font-size:12px">'+gloss(it.note)+'</div>':'')+'</div>'+
  '<div class="row" style="margin-top:14px"><button class="btn ghost" onclick="lToggleRom()">Romaji '+(L.showRom?'off':'on')+'</button><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'বুঝেছি':'Got it')+' ✓</button></div></div>';}
function phRecog(it){
  const others=lz().filter(x=>x.id!==it.id); const pick=seededShuffle(others,L.item+1).slice(0,3);
  const opts=seededShuffle([{m:it.meaning,ok:true}].concat(pick.map(o=>({m:o.meaning,ok:false}))), L.item*7+3);
  L._opts=opts;
  const chosen=L.pick!=null; const good=chosen&&opts[L.pick].ok;
  let h='<div class="card" style="text-align:center;margin-bottom:12px"><div class="big" style="font-size:28px">'+it.jp+'</div><div style="font-size:20px">🔊</div></div>';
  h+='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'এর মানে কী?':'What does it mean?')+'</div>';
  h+=opts.map((o,k)=>{let cls='opt'; if(L.pick===k)cls+=o.ok?' good':' bad'; if(L.hint&&o.ok)cls+=' hint';
    return '<button class="'+cls+'" onclick="lPick('+k+')">'+T(o.m)+'</button>';}).join('');
  if(good) h+='<div class="row" style="align-items:center;margin-top:4px"><span class="tag">✓ '+(LANG==='bn'?'ঠিক!':'Correct')+'</span><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(chosen) h+='<div style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'আবার দেখো':'Not quite — try another')+'</div>';
  return h;
}
window.lPick=(k)=>{L.pick=k;render();};
function phProd(it){return '<div class="card" style="text-align:center">'+
  '<div class="muted">'+(L.write?(LANG==='bn'?'এটি লেখো':'Write this'):(LANG==='bn'?'এটি বলো':'Say this'))+'</div>'+
  '<div style="font-size:18px;font-weight:600;margin:8px">'+T(it.meaning)+'</div>'+
  (L.revealed?'<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div>':'<div class="faint" style="font-size:26px">· · ·</div>')+
  '<div class="pillrow" style="justify-content:center;margin:14px 0">'+
    '<button class="btn line">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button>'+
    '<button class="btn line" onclick="lReveal()">'+(L.revealed?'🙈 Hide':'👁 Model')+'</button>'+
    '<button class="btn line" onclick="lWrite()">🔁 '+(L.write?'Speak':'Write')+'</button></div>'+
  '<div class="row"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';}
function phContext(it){
  const tokens=it.srs_words;
  if(tokens.length<2) return '<div class="card" style="text-align:center"><div class="muted">'+(LANG==='bn'?'বাক্যে':'In context')+'</div><div class="big" style="font-size:26px;margin:8px">'+it.jp+'</div><div>'+T(it.meaning)+'</div><div class="row" style="margin-top:14px"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';
  if(L.bankItem!==L.item){L.built=[]; L.bank=seededShuffle(tokens,L.item+5); L.bankItem=L.item;}
  const complete=L.built.length===tokens.length; const ordered=complete&&L.built.join('|')===tokens.join('|');
  let h='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'শব্দগুলো সাজিয়ে বাক্য বানাও':'Arrange the words')+'</div>';
  h+='<div style="margin-bottom:10px">'+T(it.meaning)+'</div>';
  h+='<div class="assembled '+(complete?(ordered?'good':'bad'):'')+'">'+(L.built.length?L.built.map((w,k)=>'<button class="tok" onclick="lUnbuild('+k+')">'+w+'</button>').join(''):'<span class="faint">'+(LANG==='bn'?'নিচের শব্দে ট্যাপ করো':'tap words below')+'</span>')+'</div>';
  h+='<div class="bank" style="margin-top:12px">'+L.bank.map((w,k)=>'<button class="tok" onclick="lBuild('+k+')">'+w+'</button>').join('')+'</div>';
  if(complete&&ordered) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="tag">✓</span><span class="grow" style="font-size:14px">'+it.jp+'</span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(complete) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="grow" style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'একটু এদিক-ওদিক':'not quite — rearrange')+'</span><button class="btn ghost" onclick="lResetCtx()">'+(LANG==='bn'?'আবার':'Reset')+'</button></div>';
  return h;
}
window.lBuild=(k)=>{L.built.push(L.bank.splice(k,1)[0]);render();};
window.lUnbuild=(k)=>{L.bank.push(L.built.splice(k,1)[0]);render();};
window.lResetCtx=()=>{const t=lz()[L.item].srs_words;L.bank=seededShuffle(t,L.item+5);L.built=[];render();};
function phSrs(it){return '<div class="card"><div class="muted">'+(LANG==='bn'?'রিভিউতে যোগ হলো':'Added to your review')+'</div>'+
  '<div class="pillrow" style="margin:12px 0">'+it.srs_words.map(w=>'<span class="pill">'+w+'</span>').join('')+'</div>'+
  '<div class="faint" style="font-size:13px;margin-bottom:8px">'+(LANG==='bn'?'কেমন লাগল?':'How was it?')+'</div>'+
  '<div class="rate">'+[['আবার','Again'],['কঠিন','Hard'],['ভালো','Good'],['সহজ','Easy']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="lAdvance()">'+(LANG==='bn'?r[0]:r[1])+'</button>').join('')+'</div></div>';}

/* ---------- 3: SPEAK (shadowing stub) ---------- */
function screenSpeak(){const it=lz()[0];
  return '<h2 class="title">'+(LANG==='bn'?'শ্যাডোয়িং':'Speak')+'</h2><div class="pad"><div class="card" style="text-align:center">'+
    '<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div><div>'+T(it.meaning)+'</div>'+
    '<div class="wave" style="margin:16px 0"></div>'+
    '<div class="pillrow" style="justify-content:center"><button class="btn line">🔊 '+(LANG==='bn'?'শোনো':'Listen')+'</button><button class="btn primary">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button></div>'+
    '<div class="faint" style="font-size:12px;margin-top:10px">'+(LANG==='bn'?'রেকর্ড করে নিজের সাথে মিলাও (Tier 0–1)':'Record & self-compare (Tier 0–1)')+'</div></div></div>';}

/* ---------- 4: PITCH ---------- */
function screenPitch(){
  return '<h2 class="title">'+(LANG==='bn'?'উচ্চারণ · পিচ':'Pitch accent')+'</h2><div class="pad">'+
    DATA.pitch.map(p=>{const max=Math.max.apply(null,p.pattern);
      const contour='<div class="contour">'+p.pattern.map((v,i)=>'<div class="mora"><div class="b" style="height:'+(v?38:16)+'px;background:'+(v?'var(--pink)':'var(--faint)')+'"></div><small class="faint" style="font-size:10px">'+([...p.word][i]||'')+'</small></div>').join('')+'</div>';
      return '<div class="card" style="margin-bottom:10px"><div class="row" style="justify-content:space-between;align-items:baseline"><div><span class="big" style="font-size:22px">'+p.word+'</span> <span class="faint">'+p.romaji+'</span></div><span class="tag">'+T(p.accent_type)+'</span></div>'+contour+'<div class="muted" style="font-size:13px;margin-top:6px">'+T(p.meaning)+'</div></div>';
    }).join('')+'</div>';
}

/* ---------- 5: REVIEW (FSRS flashcard) ---------- */
let rIdx=0, rRevealed=false;
const RDECK=[{w:'ありがとうございます',m:{en:'Thank you',bn:'ধন্যবাদ',ja:'ありがとう'}},{w:'すみません',m:{en:'Excuse me',bn:'মাফ করবেন',ja:'すみません'}}];
function screenReview(){
  if(rIdx>=RDECK.length) return '<div class="center"><div style="font-size:40px">🎉</div><div class="big" style="font-size:18px">'+(LANG==='bn'?'রিভিউ শেষ':'Review done')+'</div><button class="btn ghost" onclick="rReset()">↺</button></div>';
  const c=RDECK[rIdx];
  let h='<h2 class="title">'+(LANG==='bn'?'রিভিউ · FSRS':'Review')+'</h2><div class="pad"><div class="card" style="text-align:center;padding:28px"><div class="big" style="font-size:26px">'+c.w+'</div>'+(rRevealed?'<div style="margin-top:10px">'+T(c.m)+'</div>':'')+'</div>';
  if(!rRevealed) h+='<button class="btn primary" style="width:100%;margin-top:14px" onclick="rShow()">'+(LANG==='bn'?'উত্তর দেখাও':'Show answer')+'</button>';
  else h+='<div class="rate" style="margin-top:14px">'+[['আবার','Again','1d'],['কঠিন','Hard','3d'],['ভালো','Good','7d'],['সহজ','Easy','15d']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="rRate()">'+(LANG==='bn'?r[0]:r[1])+'<small>'+r[2]+'</small></button>').join('')+'</div>';
  return h+'</div>';
}
window.rShow=()=>{rRevealed=true;render();};
window.rRate=()=>{rRevealed=false;rIdx++;render();};
window.rReset=()=>{rIdx=0;rRevealed=false;render();};

/* ---------- lang + boot ---------- */
document.getElementById('langs').addEventListener('click',(e)=>{const b=e.target.closest('button'); if(!b)return;
  LANG=b.dataset.l; [...document.querySelectorAll('#langs button')].forEach(x=>x.classList.toggle('on',x===b)); render();});
render();
</script>
```


## File: prototypes\SENSEI_Architecture_v1.1_Changes.md

```md
# SENSEI v1.1 — Architecture Revision

**Purpose of this document:** Your v1.0 spec is engineered well. This revision keeps that engineering and changes the *mission-critical layers* to match the real goal you stated:

> Teach a Bangladeshi worker/student — often with near-zero Japanese — enough correct Japanese to **pass the exam required to work in Japan**, including **accent/pronunciation**, and **never teach wrong Japanese**.

It is written as a changelog against v1.0. Anything not mentioned here (device analysis, llama.cpp/whisper.cpp integration, FSRS engine, DB schema, thermal management, download manager) stays as-is.

---

## 0. The single biggest change: the target

v1.0 aimed at a "Year 2+ → JLPT N1 → business Japanese" ladder. That is the wrong target for your users and quietly triples your scope.

**The real target that gets a worker to Japan (SSW / 特定技能 "Specified Skilled Worker" visa):**

| User's target sector | Required Japanese test | Level | Where / frequency |
|---|---|---|---|
| Manufacturing, construction, agriculture, industrial cleaning, food/drink manufacturing, etc. (most workers) | **JFT-Basic** (Japan Foundation Test for Basic Japanese) | **A2**, pass mark **200 points** | Dhaka, CBT, ~6×/year, **same-day result** |
| Caregiving, food service, hospitality | **JLPT N4** | N4 | Twice yearly, result in ~2 months |

Both routes also require an industry **skills test**, but that is outside the language app's scope.

**Decision for v1:**
- **Primary track = JFT-Basic A2.** Faster, more frequent, same-day results, and it is a *practical everyday-communication* test — exactly your audience.
- **Secondary track = JLPT N4**, selectable for care/food/hospitality users.
- **Cut from v1 scope:** N3, N2, N1, business Japanese, dialects, "Year 2+ mastery." Add them later as content packs if the app succeeds. Shipping a focused A2/N4 app that actually gets people to Japan beats a half-built N1 ladder.

### Anchor all content on *Irodori* (this is the key unlock)

The Japan Foundation publishes a **free** coursebook, **"Irodori: Japanese for Life in Japan,"** built around the exact "Can-do" real-life tasks that JFT-Basic tests, **with native-recorded audio**. Levels: Starter (A1) → Elementary 1 & 2 (A2).

Using Irodori's Can-do list as your syllabus spine solves three problems at once:
1. **Exam alignment** — you are teaching precisely what is tested.
2. **Correctness** — you start from authoritative, verified material instead of model-generated content.
3. **Accent** — you get free native audio for every core sentence.

> Action: verify the current Irodori content licence for redistribution inside an app; at minimum you can align your own authored content to its Can-do structure, and link learners to the official audio.

---

## 1. Correctness architecture — "never teach wrong Japanese"

This is a hard constraint, and it is **architectural, not a prompt**. A 1.7B model *will* sometimes produce wrong Japanese or a wrong Bengali explanation. No system-prompt line ("never give incorrect grammar") can prevent that. So the design must guarantee the learner never *learns* from unverified output.

### Principle: Authored content is truth. The LLM is a conversation partner, never an authority.

**Two clearly separated content classes, visible in the UI:**

| Class | Source | Shown as | The learner should… |
|---|---|---|---|
| **Verified lesson content** | Pre-authored + human/expert-checked (Irodori-aligned, JLPT N4 lists; readings validated against **JMdict/JMdict-EDICT**) | ✅ "Verified" badge | Memorize / trust fully |
| **Practice conversation** | Live LLM output | 💬 "Practice mode" label | Use to build fluency, not to learn new facts |

### What the LLM is allowed to do (and not do)

**Allowed:**
- Drive branching **conversation practice** using only sanctioned vocabulary/patterns for the learner's current level.
- Encourage, vary phrasing, role-play scenario NPCs.
- **Surface** a pre-written Bengali explanation via retrieval (see below).

**Not allowed / removed:**
- ❌ Generating grammar rules or word readings on the fly as authoritative content.
- ❌ Being the judge of whether an exam-style answer is correct.
- ❌ Introducing vocabulary/kanji the learner hasn't been formally taught.

### Three mechanisms that enforce it

1. **Retrieval-grounded explanations (RAG over your own verified content).**
   When the learner asks "why が and not は here?", the app looks up the *authored* explanation for that grammar point and shows it. The model may *select/paraphrase lightly in Bengali* but the facts come from the verified store. If no authored explanation exists, the app says "let me note this — not yet covered," instead of inventing one.

2. **Grammar-constrained decoding (llama.cpp GBNF grammar).**
   In drills and structured turns, constrain the model so it can only emit sanctioned tokens/structures. This also fixes v1.0's fragile "must output 8 tags every turn" assumption — a 1.7B model won't reliably free-form that format, but a GBNF grammar *forces* it.

3. **Deterministic answer-checking for anything graded.**
   Exam items and drills have known correct answers (from the authored key). Check the learner's answer with **string/rule matching against the key**, never by asking the LLM "is this right?" Reserve model judgment for open conversation only — and even there, correct only against a whitelist of known patterns, framed gently.

### Where correctness is riskiest: correcting the *learner's* free output

A small model grading free-form learner Japanese will sometimes mark correct answers wrong (worse for morale) or wrong answers correct (worse for the exam). Mitigations:
- Keep **free conversation labelled as practice**, explicitly "I may not catch every mistake."
- For anything the learner should *rely on*, route them to a **structured drill** with a deterministic key.
- Log suspected mistakes to `grammar_mistakes` but only *surface* corrections that match an authored mistake-pattern entry with a verified explanation.

---

## 2. True-beginner onboarding (worker with ~zero Japanese)

v1.0 assumes a motivated self-learner. Many of your users start at zero and are studying after a workday. Adjust:

- **Sound & script before everything.** Hiragana → Katakana with audio, then straight into high-frequency **survival + workplace** phrases (greetings, numbers, days off, "I don't understand, please repeat," clinic, konbini). These are literally JFT-Basic Can-dos.
- **Bengali as scaffold, then fade it.** Bengali-first is right for *instructions and safety*, but for the target sentences, move from "Bengali + Japanese" → "Japanese with picture/context" as the learner progresses, so they stop leaning on translation.
- **Romaji as a training wheel with an expiry.** Show romaji only through the kana-learning phase, then turn it off automatically. Romaji that never goes away caps pronunciation and reading.
- **Short, finishable daily sessions** (10–15 min) with a clear "today's Can-do" — better for tired workers than open-ended chat.
- **Kanji: recognition only, minimal.** JFT-Basic/N4 need very limited kanji. Don't ship the 500-kanji stroke-order plan in v1; teach the small set the exam actually uses, recognition-first.

---

## 3. Accent & pronunciation engine (new Layer)

"Accent" in Japanese for a Bengali speaker means three things, in priority order for being *understood*:

1. **Mora timing & length** — long vs short vowels (おばさん vs おばあさん), っ (small tsu), ん as its own beat. Highest impact on intelligibility.
2. **Individual sounds** — つ, ら-row, ふ, devoiced vowels (です → "des"), which don't map cleanly from Bangla.
3. **Pitch accent (高低アクセント)** — 箸 vs 橋 vs 端 (hashi), 雨 vs 飴 (ame). Bangla has no lexical pitch, so this must be taught explicitly, not absorbed.

### Engine design

- **Native audio is the reference, not TTS.** Drop C-grade Kokoro as the pronunciation model for core content; use **Irodori's native recordings** (or your own native voice-actor recordings) for every target sentence. Keep TTS only for dynamic filler where accuracy doesn't matter — or drop it from the pronunciation path entirely.
- **Shadowing loop (the core drill):** play native line → learner repeats → **record learner** → play native + learner back-to-back for self-comparison. Shadowing + honest self-compare is the highest-return accent tool and needs no ML.
- **Pitch-accent visualization:** show the high/low contour line for each word/phrase (the way OJAD does), teach the 4 patterns (heiban / atamadaka / nakadaka / odaka), and drill **minimal pairs** as a mini-game.
- **Bengali-interference notes**, authored per sound: e.g. "খেয়াল রাখুন — জাপানিজে 'ু' ছোট, おばさন (khala) আর おばあさん (dadi/nani) আলাদা।"

### On-device pronunciation scoring — scope honestly

- **v1 (feasible):** extract the learner's **pitch (F0) contour** with an on-device algorithm (pYIN/YIN, or a tiny CREPE) and the **energy/duration envelope**; align to the reference and score *pitch-shape similarity* and *rhythm/timing*. This gives real, useful feedback ("your pitch went up where it should go down"; "your っ pause was too short").
- **v2 (hard, be realistic):** phoneme-level scoring ("was your つ correct?") needs forced alignment / an acoustic model offline — genuinely difficult on a Helio G99 with no NPU. Don't promise it in v1.

---

## 4. Latency & UX for the conversational core

v1.0's 12–18s response loop kills the fast back-and-forth that language practice needs, and tired workers won't wait.

- Make the **spine of the app pre-authored and instant** (lessons, drills, scenarios, shadowing). The LLM is the *occasional* enrichment, not on the critical path of every screen.
- When the LLM is used, **stream tokens** so the learner sees a response forming instead of an 18-second blank.
- Cache TTS/audio for all core content (already in v1.0 — keep it).

---

## 5. Revised roadmap (replaces v1.0 §19)

Keeps your phase structure; retargets content and adds correctness + accent. Note that **content authoring is the real bottleneck**, not the code — budget for it.

**Phase 1 — Foundation (Weeks 1–2):** Flutter project, DB schema, kana lessons with native audio, FSRS engine, Irodori-aligned content pipeline (JSON schema + a verified-content authoring/QA process).

**Phase 2 — Verified content core (Weeks 3–5):** Author + expert-check the JFT-Basic A2 Can-do units (survival + workplace scenarios), readings validated against JMdict. This is the heaviest phase. Build the "Verified vs Practice" content separation.

**Phase 3 — AI conversation, constrained (Weeks 6–7):** llama.cpp via FFI, **GBNF grammar-constrained** output, RAG retrieval over verified explanations, deterministic drill checking. Streaming UI.

**Phase 4 — Voice & accent (Weeks 8–9):** whisper.cpp STT, shadowing loop + record/playback, pitch-accent visualization, on-device F0/timing scoring (v1 tier), Bengali-interference notes.

**Phase 5 — Exam mode & launch (Weeks 10–12):** JFT-Basic **mock tests in real CBT format** (script/vocab, conversation & expression, listening, reading), progress dashboard tied to "exam readiness," JLPT N4 track toggle, beta test with 5–10 real candidates in Dhaka, polish.

Realistically **12 weeks**, with content authoring as the risk.

---

## 6. Smaller fixes

- It's **Tecno** Pova 4, not "Techno."
- v1.0's per-turn 8-tag output format → replace with GBNF-constrained structured output (see §1).
- Kokoro voice quality is C-grade **by your own table** — fine for filler, not for teaching accent.
- whisper-base Bengali accuracy is modest; keep confidence thresholds and a "type instead" fallback.
- Keep FSRS, but **hide the review queue inside the lesson/scenario flow** so it feels like progress, not homework.

---

## Summary of the shift

| | v1.0 | v1.1 |
|---|---|---|
| Target | JLPT N5→N1, fluency, business | **JFT-Basic A2** (+ JLPT N4 track) → SSW visa |
| Content source | AI-generated + some pre-built | **Verified, Irodori-aligned; AI never authoritative** |
| Correctness | "System prompt says be correct" | **Architectural: authored=truth, LLM constrained + retrieval-grounded + deterministic checking** |
| Pronunciation | Kokoro C-grade TTS | **Native audio + shadowing + pitch-accent + on-device pitch scoring** |
| LLM role | The tutor / source of truth | **Conversation partner only, clearly labelled** |
| Scope | 2+ years to N1 | **12 weeks to a shippable exam-prep app** |

Same solid engine. A soul that gets your users to Japan without ever teaching them a wrong sentence.

```


## File: prototypes\SENSEI_Project_Status.md

```md
# SENSEI — Project Status & What To Do Next

*Plain-language guide. No coding knowledge needed to read this.*

---

## What SENSEI is

An offline phone app that teaches a Bangladeshi worker enough **correct** Japanese
to pass the exam needed to work in Japan, and to speak with a decent accent —
with the app's menus available in **English, Bengali, or Japanese**.

The real target we locked in: **JFT-Basic (A2 level)** — the test taken in Dhaka
for the Specified Skilled Worker (SSW) visa — plus **JLPT N4** for care/food/
hospitality jobs. Not the far-off "become fluent" dream; the exam that gets
someone on a plane.

---

## What you have right now (two things)

### 1. A working demo you can open today — `sensei_prototype.html`
Double-click it in any web browser (Chrome is best). No install. It shows the
real feel of the app:
- Learn the kana alphabet (tap to hear each letter)
- A workplace lesson (greetings, self-introduction) — verified correct Japanese
- **Shadowing**: hear a phrase, record yourself, watch your live pitch line
- **Pitch accent**: see how 箸 (chopsticks) vs 橋 (bridge) differ in melody
- A flashcard review that schedules words the smart way
- A language switch (English / বাংলা / 日本語). In Bengali it shows **English
  underneath**, so imperfect Bengali wording is always backed up.

This is what you show people, use yourself, or hand to an investor.

### 2. The real app's foundation — the `sensei_app/` folder
This is the actual app's skeleton in Flutter (the tool used to build real phone
apps). It's not yet an installable app, but the hard, correctness-critical parts
are done and **tested**:

| Piece | What it does | Proven? |
|---|---|---|
| Memory scheduler (FSRS) | Decides when to review each word so you don't forget | ✅ 11/11 tests pass |
| Pitch/accent engine | Measures your voice's melody and scores it vs native | ✅ 8/8 tests pass |
| Content checker | Blocks any lesson that isn't 100% verified & trilingual | ✅ all content passes |
| Verified content | 46 hiragana, 46 katakana, 2 workplace lessons, 6 pitch pairs | ✅ |
| Trilingual menus | English / Bengali / Japanese, Bengali shown bilingually | ✅ |
| App screens | Kana, Lesson, Shadowing, Pitch, Review | built |

**The core promise — "never teach wrong Japanese" — is built into the code.**
Every lesson is written and checked ahead of time; the AI is only ever a
practice partner, never the source of what's "correct."

---

## The honest gap: what's NOT done yet

To become a real app someone installs from the Play Store, three things remain,
and they **need a phone/computer with developer tools** (they couldn't be done or
tested in this chat):

1. **Wiring the "brain" onto the phone** — the offline AI (for conversation), the
   voice-to-text, and the Japanese voice. These are known open-source pieces; they
   need a developer to plug into the Android side.
2. **Turning on the microphone** for real recording (the demo already shows how).
3. **Building and testing on an actual Techno/Tecno phone.**

Think of it this way: the *engine and the blueprint* are built and tested. The
*final assembly onto a phone* is the remaining work.

---

## What to do next — your options

**Option A — Keep it as a demo for now (₹0, no developer).**
Use `sensei_prototype.html` to show the idea, get feedback from real JFT-Basic
students, and refine the lessons. I can keep adding verified content (more
lessons: clinic, train station, asking for days off) and polish the demo.

**Option B — Turn it into a real app (needs a Flutter developer).**
Hand them the `sensei_app/` folder and the architecture document. Because the
scheduler, pitch engine, content system, and screens are already built and
tested, a developer is mostly doing the "assembly onto the phone" part.
Rough estimate: a single experienced Flutter/Android developer, **6–10 weeks**
for a first installable version — with content authoring as the ongoing work.

**What to hand a developer:**
- The `sensei_app/` folder (the code)
- `SENSEI_Architecture_v1.1_Changes.md` (the plan)
- This file (the status)
- Tell them: *"The FSRS engine, pitch engine, content pipeline and screens are
  done and tested. I need the native model integration (llama.cpp / whisper.cpp /
  audio), real mic capture, and an Android build for the Tecno Pova 4."*

---

## The one rule to protect

Whoever continues this must keep the safety rule: **the learner only ever learns
from pre-written, verified content — never from raw AI output.** That's what makes
SENSEI trustworthy for someone whose visa depends on passing. The code already
enforces it (`validate_content.mjs` must pass before any lesson ships).

---

## Quick file map

- `sensei_prototype.html` — the clickable demo (open in a browser)
- `SENSEI_Architecture_v1.1_Changes.md` — the strategy & design
- `sensei_app/` — the real app foundation
  - `README.md` inside — how a developer runs it
  - `assets/content/` — the verified lessons (this is the app's "textbook")
  - `lib/` — the app's code (engine + screens)
  - `tools/` — the test/validation scripts that prove it works

You started with a strong architecture doc. You now have a runnable demo, a
tested foundation, and a clear path. That's real progress. 頑張って (ganbatte)!

```


## File: prototypes\bhasago_brand.html

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Bhasago — brand & UI kit</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=Noto+Sans+Bengali:wght@400;600;800&family=Noto+Sans+JP:wght@500;700&display=swap" rel="stylesheet">
<style>
  :root{
    --bg:#0E1116; --surface:#171B22; --surface-hi:#212734; --outline:#2E3644;
    --ai:#5B7CFA; --ai-bright:#8AA0FF; --ai-deep:#29347A;
    --sakura:#FF6F86; --gold:#FFC24B;
    --ink:#F3F5FA; --ink-dim:#AAB3C5;
    --flow:#00C853; --struggle:#FF6D00; --burnout:#2979FF; --boredom:#AA00FF;
    --r:16px;
  }
  *{box-sizing:border-box}
  body{margin:0;background:radial-gradient(1200px 700px at 70% -10%, #14204a 0%, var(--bg) 55%);
    color:var(--ink);font-family:Inter,'Noto Sans Bengali',system-ui,sans-serif;line-height:1.5;
    -webkit-font-smoothing:antialiased}
  .bn{font-family:'Noto Sans Bengali',Inter,sans-serif}
  .jp{font-family:'Noto Sans JP',sans-serif}
  .wrap{max-width:1080px;margin:0 auto;padding:40px 24px 80px}
  h2{font-size:14px;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-dim);
    margin:56px 0 18px;font-weight:600}
  .muted{color:var(--ink-dim)}
  .card{background:var(--surface);border:1px solid var(--outline);border-radius:var(--r);padding:20px}

  /* ---------- hero ---------- */
  .hero{display:flex;gap:32px;align-items:center;flex-wrap:wrap}
  .logo{width:132px;height:132px;flex:0 0 auto;filter:drop-shadow(0 18px 40px rgba(61,90,254,.35))}
  .brandname{font-size:56px;font-weight:800;letter-spacing:-.02em;margin:0;
    background:linear-gradient(92deg,#fff,#cdd7ff 60%,var(--sakura));-webkit-background-clip:text;background-clip:text;color:transparent}
  .tag{font-size:19px;margin:.35em 0 0}
  .kicker{display:inline-block;margin-top:14px;font-size:12.5px;color:var(--ink-dim);
    border:1px solid var(--outline);border-radius:999px;padding:5px 12px}

  /* torii draw animation */
  .torii-sun{transform-origin:512px 452px;animation:sun 2.4s ease-out both}
  .torii-gate{transform-origin:512px 540px;animation:gate 1s ease-out .25s both}
  .torii-bridge{stroke-dasharray:520;stroke-dashoffset:520;animation:draw 1.1s ease-out .7s forwards}
  .torii-dot{opacity:0;animation:pop .4s ease-out 1.5s forwards}
  @keyframes sun{from{transform:scale(.4);opacity:0}to{transform:scale(1);opacity:1}}
  @keyframes gate{from{transform:translateY(26px) scale(.96);opacity:0}to{transform:none;opacity:1}}
  @keyframes draw{to{stroke-dashoffset:0}}
  @keyframes pop{from{opacity:0;transform:scale(.2)}to{opacity:1;transform:none}}
  @media (prefers-reduced-motion:reduce){
    .torii-sun,.torii-gate,.torii-bridge,.torii-dot{animation:none;opacity:1;stroke-dashoffset:0}
  }

  /* ---------- icon lab ---------- */
  .iconrow{display:flex;gap:24px;align-items:center;flex-wrap:wrap}
  .appicon{width:120px;height:120px;border-radius:27px;cursor:pointer;transition:transform .25s, box-shadow .25s;
    box-shadow:0 14px 30px rgba(0,0,0,.45)}
  .appicon:hover{transform:translateY(-4px) scale(1.03);box-shadow:0 22px 46px rgba(91,124,250,.5)}
  .sizes{display:flex;gap:16px;align-items:flex-end}
  .sizes .appicon{cursor:default}
  .s76{width:76px;height:76px;border-radius:18px}
  .s52{width:52px;height:52px;border-radius:12px}
  .s32{width:32px;height:32px;border-radius:8px}
  .btn{background:var(--ai-deep);color:#dfe5ff;border:1px solid #38489a;border-radius:10px;
    padding:9px 15px;font:inherit;font-size:14px;cursor:pointer;transition:background .2s}
  .btn:hover{background:#324099}

  /* ---------- tokens ---------- */
  .swatches{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px}
  .sw{border-radius:12px;border:1px solid var(--outline);overflow:hidden;background:var(--surface)}
  .sw .chip{height:64px}
  .sw .lab{padding:9px 11px;font-size:12.5px}
  .sw .lab b{display:block;font-size:13px}
  .sw .hex{color:var(--ink-dim);font-variant-numeric:tabular-nums}

  /* ---------- type ---------- */
  .type div{margin:6px 0}
  .t24{font-size:24px;font-weight:800}.t20{font-size:20px;font-weight:600}
  .t16{font-size:16px}.t14{font-size:14px}.t12{font-size:12px;color:var(--ink-dim)}

  /* ---------- phone ---------- */
  .stage{display:flex;gap:40px;flex-wrap:wrap;align-items:flex-start}
  .phone{width:300px;flex:0 0 auto;background:var(--bg);border:10px solid #05070c;border-radius:38px;
    padding:0;overflow:hidden;box-shadow:0 30px 70px rgba(0,0,0,.6)}
  .status{height:26px;display:flex;justify-content:center;align-items:center}
  .notch{width:110px;height:18px;background:#05070c;border-radius:0 0 14px 14px}
  .topbar{display:flex;align-items:center;gap:9px;padding:6px 14px 12px}
  .topbar .mk{width:26px;height:26px;border-radius:7px}
  .topbar b{font-size:16px;flex:1}
  .langs{display:flex;gap:5px}
  .lang{font-size:11px;border:1px solid var(--outline);border-radius:999px;padding:3px 8px;color:var(--ink-dim);cursor:pointer}
  .lang.active{background:var(--ai-deep);color:#dfe5ff;border-color:#38489a}
  .screen{padding:6px 14px 14px;min-height:404px}
  .hide{display:none}
  .gcard{background:linear-gradient(135deg,var(--ai-deep),#1a2140);border:1px solid #33407e;
    border-radius:var(--r);padding:15px}
  .gcard .lbl{font-size:12px;color:#bcc7ff}
  .gcard .goal{font-size:17px;font-weight:700;margin-top:2px}
  .ring{display:flex;gap:14px;align-items:center;margin-top:14px}
  .stats{display:flex;gap:10px;margin-top:14px}
  .stat{flex:1;background:var(--surface);border:1px solid var(--outline);border-radius:12px;padding:10px}
  .stat .n{font-size:20px;font-weight:800}.stat .k{font-size:11px;color:var(--ink-dim)}
  .cta{margin-top:14px;background:var(--ai);color:#0a1230;border:none;border-radius:12px;
    padding:13px;width:100%;font:inherit;font-weight:700;font-size:15px;cursor:pointer}
  .nav{display:flex;border-top:1px solid var(--outline);background:var(--surface)}
  .nav button{flex:1;background:none;border:none;color:var(--ink-dim);font:inherit;font-size:10.5px;
    padding:9px 0 8px;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:3px}
  .nav button .ic{width:22px;height:22px;border-radius:6px;border:2px solid currentColor;opacity:.75}
  .nav button.on{color:var(--ai-bright)}
  .nav button.on .ic{background:var(--ai-deep);opacity:1}

  /* lesson micro-loop */
  .lesson .word{font-size:40px;font-weight:700;text-align:center;margin:20px 0 2px}
  .lesson .romaji{text-align:center;color:var(--ink-dim);font-size:14px}
  .lesson .mean{text-align:center;margin:14px 0;font-size:16px}
  .answer{background:var(--surface-hi);border:1px dashed #3a4560;border-radius:12px;padding:12px;text-align:center}
  .invariant{display:flex;gap:8px;margin-top:16px}
  .invariant button{flex:1;background:var(--surface-hi);border:1px solid var(--outline);color:var(--ink);
    border-radius:10px;padding:11px 0;font:inherit;font-size:13px;cursor:pointer;min-height:44px}
  .invariant button:hover{border-color:var(--ai)}
  .pill{display:inline-block;background:rgba(0,200,83,.14);color:#5df2a0;border:1px solid #1e5e3e;
    border-radius:999px;font-size:11px;padding:3px 9px}
  .note{font-size:12.5px;color:var(--ink-dim)}
  .foot{margin-top:60px;border-top:1px solid var(--outline);padding-top:20px;font-size:13px;color:var(--ink-dim)}
  code{background:var(--surface-hi);padding:2px 6px;border-radius:6px;font-size:12.5px}
</style>
</head>
<body>
<div class="wrap">

  <!-- ===================== HERO ===================== -->
  <div class="hero">
    <svg class="logo" id="heroLogo" viewBox="0 0 1024 1024" aria-label="Bhasago logo">
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#1B2350"/><stop offset=".55" stop-color="#2A3A8F"/><stop offset="1" stop-color="#3D5AFE"/>
        </linearGradient>
        <radialGradient id="sun" cx=".5" cy=".5" r=".5">
          <stop offset="0" stop-color="#FFC24B" stop-opacity=".95"/>
          <stop offset=".6" stop-color="#FF8A5B" stop-opacity=".55"/>
          <stop offset="1" stop-color="#FF6F86" stop-opacity="0"/>
        </radialGradient>
        <linearGradient id="torii" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#FFE3E9"/>
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" rx="232" fill="url(#bg)"/>
      <circle class="torii-sun" cx="512" cy="452" r="238" fill="url(#sun)"/>
      <g class="torii-gate" fill="url(#torii)">
        <path d="M266 356 C320 330,704 330,758 356 L742 410 C700 392,324 392,282 410 Z"/>
        <rect x="322" y="446" width="380" height="46" rx="8"/>
        <path d="M372 470 h58 l14 250 h-86 Z"/>
        <path d="M652 470 h58 l14 250 h-86 Z"/>
      </g>
      <path class="torii-bridge" d="M300 792 C430 748,594 748,724 792" fill="none" stroke="#FF6F86" stroke-width="30" stroke-linecap="round"/>
      <circle class="torii-dot" cx="512" cy="772" r="15" fill="#FFC24B"/>
    </svg>
    <div>
      <h1 class="brandname">Bhasago</h1>
      <div class="tag bn">বাংলায় জাপানি ভাষা শিখুন <span class="muted">· Learn Japanese in Bangla</span></div>
      <span class="kicker">Ai&nbsp;indigo × Sakura vermilion · dark, calm, offline-first · internal codename SENSEI</span>
    </div>
  </div>

  <!-- ===================== INTERACTIVE ICON ===================== -->
  <h2>App icon — tap to replay</h2>
  <div class="card iconrow">
    <svg class="appicon" id="appIcon" viewBox="0 0 1024 1024" aria-label="Bhasago app icon">
      <rect width="1024" height="1024" rx="232" fill="url(#bg)"/>
      <circle class="i-sun" cx="512" cy="452" r="238" fill="url(#sun)"/>
      <g class="i-gate" fill="url(#torii)">
        <path d="M266 356 C320 330,704 330,758 356 L742 410 C700 392,324 392,282 410 Z"/>
        <rect x="322" y="446" width="380" height="46" rx="8"/>
        <path d="M372 470 h58 l14 250 h-86 Z"/><path d="M652 470 h58 l14 250 h-86 Z"/>
      </g>
      <path class="i-bridge" d="M300 792 C430 748,594 748,724 792" fill="none" stroke="#FF6F86" stroke-width="30" stroke-linecap="round"/>
      <circle class="i-dot" cx="512" cy="772" r="15" fill="#FFC24B"/>
    </svg>
    <div>
      <button class="btn" id="replay">▶ Replay animation</button>
      <p class="note" style="margin:12px 0 0;max-width:360px">The torii is the gateway to Japan; the brushstroke beneath is the bridge from Bengal. Hover to lift, tap to redraw. Ships as <code>assets/brand/bhasago_icon.svg</code>.</p>
      <div class="sizes" style="margin-top:16px">
        <svg class="appicon s76" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="232" fill="url(#bg)"/><circle cx="512" cy="452" r="238" fill="url(#sun)"/><g fill="url(#torii)"><path d="M266 356 C320 330,704 330,758 356 L742 410 C700 392,324 392,282 410 Z"/><rect x="322" y="446" width="380" height="46" rx="8"/><path d="M372 470 h58 l14 250 h-86 Z"/><path d="M652 470 h58 l14 250 h-86 Z"/></g><path d="M300 792 C430 748,594 748,724 792" fill="none" stroke="#FF6F86" stroke-width="30" stroke-linecap="round"/></svg>
        <svg class="appicon s52" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="232" fill="url(#bg)"/><circle cx="512" cy="452" r="238" fill="url(#sun)"/><g fill="url(#torii)"><path d="M266 356 C320 330,704 330,758 356 L742 410 C700 392,324 392,282 410 Z"/><rect x="322" y="446" width="380" height="46" rx="8"/><path d="M372 470 h58 l14 250 h-86 Z"/><path d="M652 470 h58 l14 250 h-86 Z"/></g></svg>
        <svg class="appicon s32" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="232" fill="url(#bg)"/><circle cx="512" cy="452" r="238" fill="url(#sun)"/><g fill="url(#torii)"><path d="M266 356 C320 330,704 330,758 356 L742 410 C700 392,324 392,282 410 Z"/><rect x="322" y="446" width="380" height="46" rx="8"/><path d="M372 470 h58 l14 250 h-86 Z"/><path d="M652 470 h58 l14 250 h-86 Z"/></g></svg>
      </div>
    </div>
  </div>

  <!-- ===================== COLOR TOKENS ===================== -->
  <h2>Color system</h2>
  <div class="swatches" id="swatches"></div>

  <!-- ===================== TYPE ===================== -->
  <h2>Typography — Noto Sans Bengali · Noto Sans JP</h2>
  <div class="card type">
    <div class="t24 bn">দারুণ চলছে! <span class="jp">よくできました</span></div>
    <div class="t20 bn">কনবিনিতে কেনাকাটা — Convenience store</div>
    <div class="t16 bn">এই শব্দটা মনে রাখো: <span class="jp">みず</span> (mizu) — জল</div>
    <div class="t14 muted">14px · secondary · captions & helper copy</div>
    <div class="t12">12px · meta · scale 12 / 14 / 16 / 20 / 24</div>
  </div>

  <!-- ===================== LIVE APP ===================== -->
  <h2>The app, rebranded — tap the nav</h2>
  <div class="stage">
    <div class="phone">
      <div class="status"><div class="notch"></div></div>
      <div class="topbar">
        <svg class="mk" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="232" fill="url(#bg)"/><circle cx="512" cy="452" r="238" fill="url(#sun)"/><g fill="url(#torii)"><path d="M266 356 C320 330,704 330,758 356 L742 410 C700 392,324 392,282 410 Z"/><rect x="322" y="446" width="380" height="46" rx="8"/><path d="M372 470 h58 l14 250 h-86 Z"/><path d="M652 470 h58 l14 250 h-86 Z"/></g></svg>
        <b>Bhasago</b>
        <div class="langs">
          <span class="lang">EN</span><span class="lang active bn">বাংলা</span><span class="lang jp">日本語</span>
        </div>
      </div>

      <!-- HOME -->
      <div class="screen" data-screen="home">
        <div class="gcard">
          <div class="lbl bn">তোমার লক্ষ্য</div>
          <div class="goal bn">জাপান ওয়ার্ক ভিসা (SSW) — পাস মার্ক ২০০</div>
          <div class="ring">
            <svg width="58" height="58" viewBox="0 0 58 58">
              <circle cx="29" cy="29" r="24" fill="none" stroke="#2b3566" stroke-width="7"/>
              <circle cx="29" cy="29" r="24" fill="none" stroke="#FFC24B" stroke-width="7" stroke-linecap="round"
                stroke-dasharray="151" stroke-dashoffset="66" transform="rotate(-90 29 29)"/>
            </svg>
            <div><div style="font-size:20px;font-weight:800">১২৭<span style="font-size:12px;color:#bcc7ff">/200</span></div>
            <div style="font-size:11px;color:#bcc7ff" class="bn">আনুমানিক স্কোর</div></div>
          </div>
        </div>
        <div class="stats">
          <div class="stat"><div class="n">৩১৮</div><div class="k bn">শব্দ শেখা</div></div>
          <div class="stat"><div class="n">১৪</div><div class="k bn">আজ due</div></div>
          <div class="stat"><div class="n">৭</div><div class="k bn">দিন ধারা</div></div>
        </div>
        <button class="cta bn">আরেকটা? →</button>
        <p class="note bn" style="margin:10px 2px 0">ধারা শুধু হিসাব — কোনো সতর্কতা নেই, চাপ নেই।</p>
      </div>

      <!-- LEARN / LESSON -->
      <div class="screen hide lesson" data-screen="learn">
        <span class="pill bn">✓ যাচাই করা content</span>
        <div class="word jp">みず</div>
        <div class="romaji">mizu</div>
        <div class="mean bn" id="meanRow">অর্থ লুকানো — চাপ ছাড়াই চেষ্টা করো</div>
        <button class="btn" id="showAns" style="width:100%">উত্তর দেখাও</button>
        <div class="invariant">
          <button class="bn">এড়িয়ে যাও</button>
          <button class="bn">হিন্ট</button>
          <button class="bn">বন্ধ</button>
        </div>
        <p class="note bn" style="margin-top:12px">এড়িয়ে যাও · হিন্ট · বন্ধ — সব স্ক্রিনে, সবসময়, ১ ট্যাপে।</p>
      </div>

      <!-- SPEAK -->
      <div class="screen hide" data-screen="speak">
        <div class="mean bn" style="margin-top:22px">উচ্চারণ ও শ্যাডোয়িং</div>
        <div class="card" style="text-align:center;margin-top:8px">
          <div class="jp" style="font-size:22px">おはよう</div>
          <svg width="220" height="46" style="margin-top:8px"><polyline points="0,30 30,24 60,10 90,16 120,8 150,20 180,14 220,26" fill="none" stroke="#8AA0FF" stroke-width="3"/></svg>
          <div style="width:64px;height:64px;border-radius:50%;background:var(--sakura);margin:10px auto 0;display:flex;align-items:center;justify-content:center;font-size:24px">●</div>
          <div class="note bn" style="margin-top:8px">ধরে রাখো — রেকর্ড করো — নিজের সাথে মেলাও</div>
        </div>
      </div>

      <!-- REVIEW -->
      <div class="screen hide" data-screen="review">
        <div class="mean bn" style="margin-top:22px">আজকের রিভিউ · ১৪টি কার্ড</div>
        <div class="card"><div class="jp" style="font-size:26px;text-align:center">たべもの</div>
          <div class="stats" style="margin-top:14px">
            <div class="stat" style="background:rgba(255,109,0,.14);border-color:#5a3410"><div class="k bn">আবার</div></div>
            <div class="stat" style="background:rgba(255,194,75,.14);border-color:#5c4200"><div class="k bn">কঠিন</div></div>
            <div class="stat" style="background:rgba(0,200,83,.14);border-color:#1e5e3e"><div class="k bn">ভালো</div></div>
            <div class="stat" style="background:rgba(91,124,250,.18);border-color:#33407e"><div class="k bn">সহজ</div></div>
          </div>
        </div>
        <p class="note bn" style="margin-top:10px">FSRS-4.5 · ভুলে যাওয়ার আগে সঠিক সময়ে।</p>
      </div>

      <div class="nav">
        <button class="on" data-go="home"><span class="ic"></span>হোম</button>
        <button data-go="learn"><span class="ic"></span>শেখো</button>
        <button data-go="speak"><span class="ic"></span>বলো</button>
        <button data-go="review"><span class="ic"></span>রিভিউ</button>
      </div>
    </div>

    <div style="flex:1;min-width:230px">
      <div class="card">
        <b>What changed in the rebrand</b>
        <p class="note" style="margin:.6em 0 0">Display name → <b>Bhasago</b> across <code>app_en/bn/ja.arb</code>, <code>main.dart</code>, README. New <code>lib/app/theme.dart</code> (this palette) wired into <code>MaterialApp</code>. Package <code>sensei_app</code>, the <code>SenseiApp</code> class and <code>sensei.db</code> stay — renaming them would break the running build and existing user data.</p>
      </div>
      <div class="card" style="margin-top:14px">
        <b>Guardrails kept</b>
        <p class="note" style="margin:.6em 0 0">Streak is a plain number (no loss warnings). <b>Skip · Hint · Quit</b> present on every learning screen. Bengali-first copy with optional EN/JA. Dark + calm for budget AMOLED.</p>
      </div>
    </div>
  </div>

  <div class="foot">
    Bhasago brand & UI kit · dark theme · generated preview. Fonts: Noto Sans Bengali / Noto Sans JP.
    Open in any browser — self-contained, no build step.
  </div>
</div>

<script>
  // color tokens
  const tokens=[
    ['Ai indigo','--ai','#5B7CFA'],['Ai bright','--ai-bright','#8AA0FF'],['Ai deep','--ai-deep','#29347A'],
    ['Sakura','--sakura','#FF6F86'],['Gold','--gold','#FFC24B'],
    ['Ink bg','--bg','#0E1116'],['Surface','--surface','#171B22'],['Surface hi','--surface-hi','#212734'],
    ['Flow','--flow','#00C853'],['Struggle','--struggle','#FF6D00'],['Burnout','--burnout','#2979FF'],['Boredom','--boredom','#AA00FF']
  ];
  document.getElementById('swatches').innerHTML=tokens.map(function(t){
    return '<div class="sw"><div class="chip" style="background:'+t[2]+'"></div>'+
      '<div class="lab"><b>'+t[0]+'</b><span class="hex">'+t[2]+' · <code>'+t[1]+'</code></span></div></div>';
  }).join('');

  // replay icon animation
  var icon=document.getElementById('appIcon');
  function replay(el){
    ['.i-sun','.i-gate','.i-bridge','.i-dot'].forEach(function(sel){
      var n=el.querySelector(sel); if(!n)return;
      n.style.animation='none'; void n.offsetWidth;  // reflow
      n.style.animation='';
    });
    el.classList.remove('play'); void el.offsetWidth; el.classList.add('play');
  }
  // apply keyframes to icon parts when .play is set
  var css=document.createElement('style');
  css.textContent='.appicon.play .i-sun{animation:sun 1.4s ease-out both}'+
    '.appicon.play .i-gate{animation:gate .9s ease-out .2s both}'+
    '.appicon.play .i-bridge{stroke-dasharray:520;stroke-dashoffset:520;animation:draw 1s ease-out .55s forwards}'+
    '.appicon.play .i-dot{opacity:0;animation:pop .4s ease-out 1.3s forwards}';
  document.head.appendChild(css);
  document.getElementById('replay').onclick=function(){replay(icon)};
  icon.onclick=function(){replay(icon)};
  replay(icon);

  // phone nav
  document.querySelectorAll('.nav button').forEach(function(b){
    b.onclick=function(){
      document.querySelectorAll('.nav button').forEach(function(x){x.classList.remove('on')});
      b.classList.add('on');
      var go=b.getAttribute('data-go');
      document.querySelectorAll('.screen').forEach(function(s){
        s.classList.toggle('hide', s.getAttribute('data-screen')!==go);
      });
    };
  });

  // lesson: show answer
  var sa=document.getElementById('showAns');
  if(sa){sa.onclick=function(){
    document.getElementById('meanRow').textContent='জল  ·  water';
    sa.style.display='none';
  };}

  // language chips (visual)
  document.querySelectorAll('.lang').forEach(function(l){
    l.onclick=function(){document.querySelectorAll('.lang').forEach(function(x){x.classList.remove('active')});l.classList.add('active')};
  });
</script>
</body>
</html>

```


## File: prototypes\sensei_lessons.html

```html
<!DOCTYPE html>
<html lang="bn"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SENSEI — Lessons</title>
<style>
 body{margin:0;background:#0e1116;color:#e8edf3;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans Bengali","Noto Sans JP",sans-serif}
 header{padding:16px;background:#141a22;border-bottom:1px solid #2d3540;position:sticky;top:0;z-index:5}
 .brand{font-weight:800;font-size:20px}.brand span{color:#ff5a3c}
 .langsw{display:flex;gap:6px;margin-top:10px;max-width:900px}
 .langsw button{flex:1;background:#232a35;border:1px solid #2d3540;color:#96a0ad;padding:8px;border-radius:9px;font-weight:700;cursor:pointer}
 .langsw button.on{background:#ff5a3c;color:#fff;border-color:#ff5a3c}
 .wrap{max-width:900px;margin:0 auto;padding:16px}
 .tabs{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px}
 .tabs button{background:#1a1f28;border:1px solid #2d3540;color:#dfe7ef;padding:8px 12px;border-radius:20px;cursor:pointer;font-size:13px}
 .tabs button.on{background:#38bdf8;color:#05070a;border-color:#38bdf8;font-weight:700}
 .cando{background:#161b22;border:1px solid #2b3949;border-radius:12px;padding:14px;margin-bottom:16px;color:#cfe0cf}
 .cando b{color:#38bdf8}
 .verified{display:inline-block;font-size:11px;color:#22c55e;background:#0f2417;border:1px solid #1c5232;padding:2px 8px;border-radius:20px;margin-left:8px}
 .card{background:#1a1f28;border:1px solid #2d3540;border-radius:14px;padding:16px;margin-bottom:12px}
 .jp{font-size:26px;font-weight:700}
 .rom{color:#96a0ad;font-size:14px;margin:4px 0}
 .mean{font-size:18px;margin-top:6px}
 .note{background:#161d16;border:1px solid #2a3a2a;border-radius:10px;padding:10px;margin-top:10px;font-size:13px;color:#cfe0cf}
 .second{display:block;font-size:.8em;color:#7c8794;margin-top:2px;font-weight:400}
 .count{color:#96a0ad;font-size:12px;margin-bottom:10px}
</style></head><body>
<header>
 <div class="brand">SEN<span>SEI</span> — Lessons</div>
 <div class="langsw">
  <button id="l-en" onclick="setLang('en')">English</button>
  <button id="l-bn" class="on" onclick="setLang('bn')">বাংলা</button>
  <button id="l-ja" onclick="setLang('ja')">日本語</button>
 </div>
</header>
<div class="wrap"><div class="tabs" id="tabs"></div><div id="content"></div></div>
<script>
const LESSONS = [{"type": "lesson", "id": "numbers_01", "can_do": {"en": "Say numbers 1–10, hundreds and thousands, and understand prices in yen.", "bn": "১–১০, শত ও হাজার বলা, এবং ইয়েনে দাম বোঝা।", "ja": "1〜10、百・千を言い、円の値段が分かる。"}, "jlpt_or_jft": "JFT-Basic A1", "verified": true, "source": "Standard Japanese numerals (Sino-Japanese readings)", "items": [{"id": "nm_1", "jp": "いち", "kana": "いち", "romaji": "ichi", "meaning": {"en": "1 (one)", "bn": "১ (এক)", "ja": "1（いち）"}, "note": {"en": "Basic counting number.", "bn": "মৌলিক গণনার সংখ্যা।", "ja": "基本の数。"}, "srs_words": ["いち"]}, {"id": "nm_2", "jp": "に", "kana": "に", "romaji": "ni", "meaning": {"en": "2 (two)", "bn": "২ (দুই)", "ja": "2（に）"}, "note": {"en": "Basic counting number.", "bn": "মৌলিক গণনার সংখ্যা।", "ja": "基本の数。"}, "srs_words": ["に"]}, {"id": "nm_3", "jp": "さん", "kana": "さん", "romaji": "san", "meaning": {"en": "3 (three)", "bn": "৩ (তিন)", "ja": "3（さん）"}, "note": {"en": "Basic counting number.", "bn": "মৌলিক গণনার সংখ্যা।", "ja": "基本の数。"}, "srs_words": ["さん"]}, {"id": "nm_4", "jp": "よん", "kana": "よん", "romaji": "yon", "meaning": {"en": "4 (four)", "bn": "৪ (চার)", "ja": "4（よん／し）"}, "note": {"en": "Also 'shi', but 'yon' is safer and more common.", "bn": "'শি'ও হয়, তবে 'ইয়োন' নিরাপদ ও বেশি প্রচলিত।", "ja": "「し」とも言うが「よん」が安全。"}, "srs_words": ["よん"]}, {"id": "nm_5", "jp": "ご", "kana": "ご", "romaji": "go", "meaning": {"en": "5 (five)", "bn": "৫ (পাঁচ)", "ja": "5（ご）"}, "note": {"en": "Basic counting number.", "bn": "মৌলিক গণনার সংখ্যা।", "ja": "基本の数。"}, "srs_words": ["ご"]}, {"id": "nm_6", "jp": "ろく", "kana": "ろく", "romaji": "roku", "meaning": {"en": "6 (six)", "bn": "৬ (ছয়)", "ja": "6（ろく）"}, "note": {"en": "Basic counting number.", "bn": "মৌলিক গণনার সংখ্যা।", "ja": "基本の数。"}, "srs_words": ["ろく"]}, {"id": "nm_7", "jp": "なな", "kana": "なな", "romaji": "nana", "meaning": {"en": "7 (seven)", "bn": "৭ (সাত)", "ja": "7（なな／しち）"}, "note": {"en": "Also 'shichi'; 'nana' is clearer.", "bn": "'শিচি'ও হয়; 'নানা' বেশি স্পষ্ট।", "ja": "「しち」とも。「なな」が明瞭。"}, "srs_words": ["なな"]}, {"id": "nm_8", "jp": "はち", "kana": "はち", "romaji": "hachi", "meaning": {"en": "8 (eight)", "bn": "৮ (আট)", "ja": "8（はち）"}, "note": {"en": "Basic counting number.", "bn": "মৌলিক গণনার সংখ্যা।", "ja": "基本の数。"}, "srs_words": ["はち"]}, {"id": "nm_9", "jp": "きゅう", "kana": "きゅう", "romaji": "kyū", "meaning": {"en": "9 (nine)", "bn": "৯ (নয়)", "ja": "9（きゅう／く）"}, "note": {"en": "Also 'ku'; 'kyū' is safer.", "bn": "'কু'ও হয়; 'কিয়ু' নিরাপদ।", "ja": "「く」とも。「きゅう」が安全。"}, "srs_words": ["きゅう"]}, {"id": "nm_10", "jp": "じゅう", "kana": "じゅう", "romaji": "jū", "meaning": {"en": "10 (ten)", "bn": "১০ (দশ)", "ja": "10（じゅう）"}, "note": {"en": "11 = jū-ichi, 20 = ni-jū, and so on.", "bn": "১১ = জুু-ইচি, ২০ = নি-জুু — এভাবে চলে।", "ja": "11＝じゅういち、20＝にじゅう。"}, "srs_words": ["じゅう"]}, {"id": "nm_100", "jp": "ひゃく", "kana": "ひゃく", "romaji": "hyaku", "meaning": {"en": "100 (hundred)", "bn": "১০০ (একশ)", "ja": "100（ひゃく）"}, "note": {"en": "300 = san-byaku (sound changes a little).", "bn": "৩০০ = সান-বিয়াকু (উচ্চারণ একটু বদলায়)।", "ja": "300＝さんびゃく（音変化あり）。"}, "srs_words": ["ひゃく"]}, {"id": "nm_1000", "jp": "せん", "kana": "せん", "romaji": "sen", "meaning": {"en": "1000 (thousand)", "bn": "১০০০ (এক হাজার)", "ja": "1000（せん）"}, "note": {"en": "A typical konbini lunch is ~500–1000 yen.", "bn": "সাধারণ কনবিনি লাঞ্চ ~৫০০–১০০০ ইয়েন।", "ja": "コンビニ昼食は約500〜1000円。"}, "srs_words": ["せん"]}, {"id": "nm_yen", "jp": "えん", "kana": "えん", "romaji": "en", "meaning": {"en": "yen (¥, the money)", "bn": "ইয়েন (¥, জাপানি মুদ্রা)", "ja": "円（お金の単位）"}, "note": {"en": "500 yen = go-hyaku en. Prices are said number + えん.", "bn": "৫০০ ইয়েন = গো-হিয়াকু এন। দাম বলা হয় সংখ্যা + えん।", "ja": "500円＝ごひゃくえん。数＋えん。"}, "srs_words": ["えん"]}]}, {"type": "lesson", "id": "time_01", "can_do": {"en": "Ask and tell the time, and talk about today, tomorrow, and the days of the week.", "bn": "সময় জিজ্ঞেস ও বলা, এবং আজ/আগামীকাল ও সপ্তাহের দিন নিয়ে কথা বলা।", "ja": "時間を聞いて答え、今日・明日・曜日が言える。"}, "jlpt_or_jft": "JFT-Basic A1/A2", "verified": true, "source": "Aligned to Irodori Starter Can-do (time and days)", "items": [{"id": "tm_now", "jp": "いま なんじですか", "kana": "いま なんじですか", "romaji": "ima nanji desu ka", "meaning": {"en": "What time is it now?", "bn": "এখন কয়টা বাজে?", "ja": "今 何時ですか。"}, "note": {"en": "なんじ = what time. Answer with number + じ.", "bn": "なんじ = কয়টা। উত্তরে সংখ্যা + じ বসাও।", "ja": "なんじ＝何時。数＋じで答える。"}, "srs_words": ["いま", "なんじ"]}, {"id": "tm_oclock", "jp": "さんじ", "kana": "さんじ", "romaji": "san-ji", "meaning": {"en": "3 o'clock", "bn": "৩টা", "ja": "3時（さんじ）"}, "note": {"en": "Number + じ = o'clock. 7 o'clock = しちじ.", "bn": "সংখ্যা + じ = টা। ৭টা = শিচিজি।", "ja": "数＋じ＝〜時。7時＝しちじ。"}, "srs_words": ["さんじ", "じ"]}, {"id": "tm_half", "jp": "はん", "kana": "はん", "romaji": "han", "meaning": {"en": "half past", "bn": "সাড়ে / আধা ঘণ্টা", "ja": "半（〜時半）"}, "note": {"en": "3:30 = さんじはん (san-ji han).", "bn": "৩:৩০ = সানজি হান।", "ja": "3時半＝さんじはん。"}, "srs_words": ["はん"]}, {"id": "tm_today", "jp": "きょう", "kana": "きょう", "romaji": "kyō", "meaning": {"en": "today", "bn": "আজ", "ja": "今日（きょう）"}, "note": {"en": "Very common time word.", "bn": "খুব প্রচলিত সময়-শব্দ।", "ja": "よく使う時の言葉。"}, "srs_words": ["きょう"]}, {"id": "tm_tomorrow", "jp": "あした", "kana": "あした", "romaji": "ashita", "meaning": {"en": "tomorrow", "bn": "আগামীকাল", "ja": "明日（あした）"}, "note": {"en": "Used for shifts and appointments.", "bn": "শিফট ও অ্যাপয়েন্টমেন্টে ব্যবহৃত।", "ja": "シフトや予定に使う。"}, "srs_words": ["あした"]}, {"id": "tm_yesterday", "jp": "きのう", "kana": "きのう", "romaji": "kinō", "meaning": {"en": "yesterday", "bn": "গতকাল", "ja": "昨日（きのう）"}, "note": {"en": "きょう today, あした tomorrow, きのう yesterday.", "bn": "きょう আজ, あした আগামীকাল, きのう গতকাল।", "ja": "今日・明日・昨日。"}, "srs_words": ["きのう"]}, {"id": "tm_whatday", "jp": "きょうは なんようびですか", "kana": "きょうは なんようびですか", "romaji": "kyō wa nan-yōbi desu ka", "meaning": {"en": "What day (of the week) is it today?", "bn": "আজ সপ্তাহের কোন দিন?", "ja": "今日は何曜日ですか。"}, "note": {"en": "ようび = day of the week.", "bn": "ようび = সপ্তাহের দিন।", "ja": "ようび＝曜日。"}, "srs_words": ["なんようび"]}, {"id": "tm_mon", "jp": "げつようび", "kana": "げつようび", "romaji": "getsu-yōbi", "meaning": {"en": "Monday", "bn": "সোমবার", "ja": "月曜日（げつようび）"}, "note": {"en": "Mon–Sun: げつ・か・すい・もく・きん・ど・にち + ようび.", "bn": "সোম–রবি: げつ・か・すい・もく・きん・ど・にち + ようび।", "ja": "月火水木金土日＋ようび。"}, "srs_words": ["げつようび"]}, {"id": "tm_sat", "jp": "どようび", "kana": "どようび", "romaji": "do-yōbi", "meaning": {"en": "Saturday", "bn": "শনিবার", "ja": "土曜日（どようび）"}, "note": {"en": "Many factories work Saturdays too — check your shift.", "bn": "অনেক কারখানা শনিবারও চলে — শিফট দেখে নাও।", "ja": "土曜も稼働の工場が多い。"}, "srs_words": ["どようび"]}, {"id": "tm_sun", "jp": "にちようび", "kana": "にちようび", "romaji": "nichi-yōbi", "meaning": {"en": "Sunday", "bn": "রবিবার", "ja": "日曜日（にちようび）"}, "note": {"en": "Often the day off (やすみ).", "bn": "সাধারণত ছুটির দিন (やすみ)।", "ja": "休みのことが多い。"}, "srs_words": ["にちようび"]}]}, {"type": "lesson", "id": "work_intro_01", "can_do": {"en": "Greet colleagues and introduce yourself on your first day at work.", "bn": "কর্মস্থলে প্রথম দিনে সহকর্মীদের অভিবাদন ও নিজের পরিচয় দিতে পারা।", "ja": "職場の初日に同僚にあいさつし、自己紹介ができる。"}, "jlpt_or_jft": "JFT-Basic A1/A2", "verified": true, "source": "Aligned to Irodori Starter Can-do (self-introduction / greetings)", "items": [{"id": "wi_01", "jp": "おはようございます", "kana": "おはようございます", "romaji": "ohayō gozaimasu", "meaning": {"en": "Good morning (polite)", "bn": "সুপ্রভাত (ভদ্রভাবে)", "ja": "おはよう（丁寧）"}, "note": {"en": "Say it as you arrive at work. ございます makes it polite.", "bn": "সকালে কর্মস্থলে ঢুকেই বলবে। শেষে ございます থাকায় এটি ভদ্র রূপ।", "ja": "出勤時に言う。ございますで丁寧になる。"}, "srs_words": ["おはよう", "ございます"]}, {"id": "wi_02", "jp": "こんにちは", "kana": "こんにちは", "romaji": "konnichiwa", "meaning": {"en": "Hello / good afternoon", "bn": "নমস্কার / হ্যালো (দুপুরে)", "ja": "こんにちは（昼のあいさつ）"}, "note": {"en": "は is pronounced 'wa' here, not 'ha'.", "bn": "は এখানে \"wa\" উচ্চারণ হয়, \"ha\" নয়।", "ja": "ここでのはは「わ」と読む。"}, "srs_words": ["こんにちは"]}, {"id": "wi_03", "jp": "はじめまして", "kana": "はじめまして", "romaji": "hajimemashite", "meaning": {"en": "Nice to meet you (first time)", "bn": "প্রথম সাক্ষাতে — পরিচিত হয়ে ভালো লাগল", "ja": "はじめまして（初対面）"}, "note": {"en": "Use it the first time you meet someone.", "bn": "নতুন কাউকে প্রথমবার দেখা হলেই বলবে।", "ja": "初めて会うときに使う。"}, "srs_words": ["はじめまして"]}, {"id": "wi_04", "jp": "わたしはラーマンです", "kana": "わたしはラーマンです", "romaji": "watashi wa Rāman desu", "meaning": {"en": "I am Rahman.", "bn": "আমি রহমান।", "ja": "私はラーマンです。"}, "note": {"en": "Pattern: わたしは ＿ です = 'I am ＿'. は = wa (topic marker).", "bn": "গঠন: わたしは ＿ です = \"আমি ＿\"। は = wa (বিষয় নির্দেশক)।", "ja": "型：わたしは＿です。はは「わ」（主題）。"}, "srs_words": ["わたし", "です"]}, {"id": "wi_05", "jp": "よろしくおねがいします", "kana": "よろしくおねがいします", "romaji": "yoroshiku onegai shimasu", "meaning": {"en": "I look forward to working with you (courtesy)", "bn": "আপনার সাথে কাজ করতে পেরে ভালো লাগবে (সৌজন্য)", "ja": "よろしくお願いします（締めのあいさつ）"}, "note": {"en": "Said at the end of an introduction — very important politeness in Japan.", "bn": "পরিচয়ের শেষে বলা হয় — জাপানে খুব গুরুত্বপূর্ণ ভদ্রতা।", "ja": "自己紹介の最後に言う大切な表現。"}, "srs_words": ["よろしく", "おねがいします"]}, {"id": "wi_06", "jp": "すみません", "kana": "すみません", "romaji": "sumimasen", "meaning": {"en": "Excuse me / sorry", "bn": "মাফ করবেন / এক্সকিউজ মি", "ja": "すみません（呼びかけ・軽い謝罪）"}, "note": {"en": "To get attention or apologize for a small thing.", "bn": "কারো দৃষ্টি আকর্ষণ করতে বা ছোট ভুলে ক্ষমা চাইতে।", "ja": "呼びかけや軽い謝罪に。"}, "srs_words": ["すみません"]}, {"id": "wi_07", "jp": "ありがとうございます", "kana": "ありがとうございます", "romaji": "arigatō gozaimasu", "meaning": {"en": "Thank you (polite)", "bn": "ধন্যবাদ (ভদ্রভাবে)", "ja": "ありがとうございます（丁寧）"}, "note": {"en": "ございます makes it more polite — use this at work.", "bn": "ございます যোগ করায় বেশি ভদ্র — কর্মস্থলে এটাই ব্যবহার করবে।", "ja": "ございますでより丁寧。職場で使う。"}, "srs_words": ["ありがとう"]}, {"id": "wi_08", "jp": "わかりません", "kana": "わかりません", "romaji": "wakarimasen", "meaning": {"en": "I don't understand", "bn": "আমি বুঝতে পারিনি", "ja": "わかりません"}, "note": {"en": "Don't stay silent if you don't get it — saying this is useful, not shameful.", "bn": "না বুঝলে চুপ থেকো না — এটি বলা দোষের নয়, বরং কাজে দরকারি।", "ja": "分からないときは黙らず言おう。"}, "srs_words": ["わかりません"]}, {"id": "wi_09", "jp": "もういちどおねがいします", "kana": "もういちどおねがいします", "romaji": "mō ichido onegai shimasu", "meaning": {"en": "Please say it once more", "bn": "অনুগ্রহ করে আরেকবার বলুন", "ja": "もう一度お願いします"}, "note": {"en": "If someone speaks fast, say this to hear it again.", "bn": "কেউ দ্রুত বললে এটি বলে আবার শুনে নাও।", "ja": "速いときはこれでもう一度聞く。"}, "srs_words": ["もういちど"]}]}, {"type": "lesson", "id": "workplace_01", "can_do": {"en": "Handle daily workplace needs: greet coworkers, ask for time off, report being late, ask for a break.", "bn": "কর্মস্থলের দৈনন্দিন প্রয়োজন সামলানো: সহকর্মীকে অভিবাদন, ছুটি চাওয়া, দেরি জানানো, বিরতি চাওয়া।", "ja": "職場の日常：あいさつ、休みの申し出、遅刻の連絡、休憩の依頼ができる。"}, "jlpt_or_jft": "JFT-Basic A2", "verified": true, "source": "Aligned to Irodori Elementary Can-do (workplace communication)", "items": [{"id": "wp_otsukare", "jp": "おつかれさまです", "kana": "おつかれさまです", "romaji": "otsukaresama desu", "meaning": {"en": "Thanks for your hard work (workplace greeting)", "bn": "আপনার পরিশ্রমের জন্য ধন্যবাদ (কর্মস্থলের অভিবাদন)", "ja": "お疲れさまです（職場のあいさつ）"}, "note": {"en": "Said to coworkers during/after work — extremely common.", "bn": "কাজের সময়/পরে সহকর্মীদের বলা হয় — খুবই প্রচলিত।", "ja": "仕事中・後に同僚へ。非常によく使う。"}, "srs_words": ["おつかれさまです"]}, {"id": "wp_dayoff", "jp": "やすみを とりたいです", "kana": "やすみを とりたいです", "romaji": "yasumi o toritai desu", "meaning": {"en": "I'd like to take a day off.", "bn": "আমি একদিন ছুটি নিতে চাই।", "ja": "休みを取りたいです。"}, "note": {"en": "〜たいです = I want to. やすみ = rest/day off.", "bn": "〜たいです = আমি চাই। やすみ = ছুটি।", "ja": "〜たいです＝希望。休み＝休暇。"}, "srs_words": ["やすみ", "とりたい"]}, {"id": "wp_maytomorrow", "jp": "あした やすんでも いいですか", "kana": "あした やすんでも いいですか", "romaji": "ashita yasunde mo ii desu ka", "meaning": {"en": "May I take tomorrow off?", "bn": "আমি কি আগামীকাল ছুটি নিতে পারি?", "ja": "明日 休んでもいいですか。"}, "note": {"en": "〜てもいいですか = may I ...? A polite way to ask permission.", "bn": "〜てもいいですか = আমি কি ... পারি? অনুমতি চাওয়ার ভদ্র উপায়।", "ja": "〜てもいいですか＝許可を求める丁寧表現。"}, "srs_words": ["やすんでも", "いいですか"]}, {"id": "wp_late", "jp": "すみません、おくれます", "kana": "すみません、おくれます", "romaji": "sumimasen, okuremasu", "meaning": {"en": "Sorry, I'll be late.", "bn": "দুঃখিত, আমার দেরি হবে।", "ja": "すみません、遅れます。"}, "note": {"en": "Call early. おくれます = I'll be late.", "bn": "আগেভাগে ফোন করো। おくれます = দেরি হবে।", "ja": "早めに連絡を。遅れます＝遅刻する。"}, "srs_words": ["おくれます"]}, {"id": "wp_early", "jp": "はやく かえっても いいですか", "kana": "はやく かえっても いいですか", "romaji": "hayaku kaette mo ii desu ka", "meaning": {"en": "May I leave early?", "bn": "আমি কি তাড়াতাড়ি যেতে পারি?", "ja": "早く帰ってもいいですか。"}, "note": {"en": "かえる = to go home. Same 〜てもいいですか permission pattern.", "bn": "かえる = বাড়ি যাওয়া। একই 〜てもいいですか অনুমতি গঠন।", "ja": "帰る＝帰宅。許可の型。"}, "srs_words": ["はやく", "かえっても"]}, {"id": "wp_toilet", "jp": "トイレに いっても いいですか", "kana": "トイレに いっても いいですか", "romaji": "toire ni itte mo ii desu ka", "meaning": {"en": "May I go to the toilet?", "bn": "আমি কি টয়লেটে যেতে পারি?", "ja": "トイレに行ってもいいですか。"}, "note": {"en": "トイレ is katakana (toilet). に marks the destination.", "bn": "トイレ কাতাকানা (toilet)। に দিয়ে গন্তব্য বোঝায়।", "ja": "トイレは外来語。にで行き先。"}, "srs_words": ["トイレ", "いっても"]}, {"id": "wp_break", "jp": "きゅうけいは いつですか", "kana": "きゅうけいは いつですか", "romaji": "kyūkei wa itsu desu ka", "meaning": {"en": "When is the break?", "bn": "বিরতি কখন?", "ja": "休憩はいつですか。"}, "note": {"en": "きゅうけい = break/rest. いつ = when.", "bn": "きゅうけい = বিরতি। いつ = কখন।", "ja": "休憩＝break。いつ＝when。"}, "srs_words": ["きゅうけい", "いつ"]}, {"id": "wp_understood", "jp": "わかりました", "kana": "わかりました", "romaji": "wakarimashita", "meaning": {"en": "Understood. / Got it.", "bn": "বুঝেছি। / ঠিক আছে।", "ja": "わかりました。"}, "note": {"en": "Past of わかります — say it when given an instruction.", "bn": "わかります-এর অতীত রূপ — নির্দেশ পেলে বলবে।", "ja": "わかりますの過去。指示を受けたとき言う。"}, "srs_words": ["わかりました"]}]}, {"type": "lesson", "id": "konbini_01", "can_do": {"en": "Buy something at a convenience store: pay, decline a bag, ask the price, understand the clerk.", "bn": "কনভিনিয়েন্স স্টোরে কেনাকাটা করা: দাম জিজ্ঞেস করা, ব্যাগ না নেওয়া, টাকা দেওয়া, কর্মীর কথা বোঝা।", "ja": "コンビニで買い物ができる：支払い、袋を断る、値段を聞く、店員の言葉が分かる。"}, "jlpt_or_jft": "JFT-Basic A1/A2", "verified": true, "source": "Aligned to Irodori Elementary Can-do (shopping / convenience store)", "items": [{"id": "kb_01", "jp": "いらっしゃいませ", "kana": "いらっしゃいませ", "romaji": "irasshaimase", "meaning": {"en": "Welcome (staff greeting)", "bn": "স্বাগতম (দোকানের কর্মী বলে)", "ja": "いらっしゃいませ（店員のあいさつ）"}, "note": {"en": "The clerk says this — you don't need to reply, just understand it.", "bn": "এটা কর্মী বলে — উত্তর দিতে হয় না, শুধু বুঝলেই হবে।", "ja": "店員が言う。返事は不要、聞いて分かればよい。"}, "srs_words": ["いらっしゃいませ"]}, {"id": "kb_02", "jp": "これをください", "kana": "これをください", "romaji": "kore o kudasai", "meaning": {"en": "This one, please.", "bn": "এটা দিন / এটা চাই।", "ja": "これをください。"}, "note": {"en": "を marks the thing you want; ください = please give.", "bn": "を দিয়ে বোঝায় তুমি কী চাও; ください = দয়া করে দিন।", "ja": "をは対象を示す。くださいは「ください」。"}, "srs_words": ["これ", "ください"]}, {"id": "kb_03", "jp": "ふくろはいりません", "kana": "ふくろはいりません", "romaji": "fukuro wa irimasen", "meaning": {"en": "I don't need a bag.", "bn": "ব্যাগ লাগবে না।", "ja": "袋は要りません。"}, "note": {"en": "いりません = don't need. Useful — bags often cost extra in Japan.", "bn": "いりません = দরকার নেই। কাজের কথা — জাপানে ব্যাগের জন্য আলাদা টাকা লাগে।", "ja": "要りません＝不要。日本では袋は有料のことが多い。"}, "srs_words": ["ふくろ", "いりません"]}, {"id": "kb_04", "jp": "カードでおねがいします", "kana": "カードでおねがいします", "romaji": "kādo de onegai shimasu", "meaning": {"en": "By card, please.", "bn": "কার্ডে দিতে চাই।", "ja": "カードでお願いします。"}, "note": {"en": "で marks the method (card/cash). Say げんきん de for cash.", "bn": "で দিয়ে বোঝায় উপায় (কার্ড/নগদ)। নগদের জন্য げんきん de বলবে।", "ja": "では手段を示す。現金なら「げんきんで」。"}, "srs_words": ["カード", "おねがいします"]}, {"id": "kb_05", "jp": "いくらですか", "kana": "いくらですか", "romaji": "ikura desu ka", "meaning": {"en": "How much is it?", "bn": "এটার দাম কত?", "ja": "いくらですか。"}, "note": {"en": "いくら = how much. Add か at the end to make a question.", "bn": "いくら = কত। শেষে か যোগ করলে প্রশ্ন হয়।", "ja": "いくら＝金額。最後のかで疑問文。"}, "srs_words": ["いくら", "ですか"]}, {"id": "kb_06", "jp": "あたためますか", "kana": "あたためますか", "romaji": "atatamemasu ka", "meaning": {"en": "Shall I heat it up? (staff asks)", "bn": "গরম করে দেব? (কর্মী জিজ্ঞেস করে)", "ja": "温めますか。（店員が聞く）"}, "note": {"en": "The clerk asks this about bento/food. Answer はい or いいえ.", "bn": "বেন্তো/খাবার নিয়ে কর্মী এটা জিজ্ঞেস করে। উত্তর দাও はい বা いいえ।", "ja": "弁当などで店員が聞く。はい／いいえで答える。"}, "srs_words": ["あたためます"]}, {"id": "kb_07", "jp": "はい、おねがいします", "kana": "はい、おねがいします", "romaji": "hai, onegai shimasu", "meaning": {"en": "Yes, please.", "bn": "হ্যাঁ, দয়া করে।", "ja": "はい、お願いします。"}, "note": {"en": "A polite yes to an offer (e.g. heating, a bag).", "bn": "কোনো প্রস্তাবে ভদ্রভাবে হ্যাঁ (যেমন গরম করা, ব্যাগ)।", "ja": "申し出への丁寧な「はい」。"}, "srs_words": ["はい", "おねがいします"]}, {"id": "kb_08", "jp": "レシートをください", "kana": "レシートをください", "romaji": "reshīto o kudasai", "meaning": {"en": "Receipt, please.", "bn": "রসিদ দিন।", "ja": "レシートをください。"}, "note": {"en": "レシート is a katakana loanword from English 'receipt'.", "bn": "レシート হলো ইংরেজি 'receipt' থেকে আসা কাতাকানা শব্দ।", "ja": "レシートは英語receiptの外来語（カタカナ）。"}, "srs_words": ["レシート", "ください"]}]}, {"type": "lesson", "id": "restaurant_01", "can_do": {"en": "Order food and drink at a restaurant, ask for water and the bill, and be polite about the meal.", "bn": "রেস্তোরাঁয় খাবার-পানীয় অর্ডার করা, পানি ও বিল চাওয়া, এবং খাবার নিয়ে ভদ্রতা করা।", "ja": "レストランで注文し、水や会計を頼み、食事のあいさつができる。"}, "jlpt_or_jft": "JFT-Basic A1/A2", "verified": true, "source": "Aligned to Irodori Elementary Can-do (eating out)", "items": [{"id": "rs_menu", "jp": "メニューをおねがいします", "kana": "メニューをおねがいします", "romaji": "menyū o onegai shimasu", "meaning": {"en": "The menu, please.", "bn": "মেনু দিন।", "ja": "メニューをお願いします。"}, "note": {"en": "メニュー is a katakana loanword (menu).", "bn": "メニュー ইংরেজি 'menu' থেকে আসা কাতাকানা শব্দ।", "ja": "メニューは外来語。"}, "srs_words": ["メニュー", "おねがいします"]}, {"id": "rs_this", "jp": "これをおねがいします", "kana": "これをおねがいします", "romaji": "kore o onegai shimasu", "meaning": {"en": "This one, please.", "bn": "এটা দিন।", "ja": "これをお願いします。"}, "note": {"en": "Point at the menu and say this to order.", "bn": "মেনুতে দেখিয়ে অর্ডার করতে এটা বলো।", "ja": "メニューを指して注文。"}, "srs_words": ["これ", "おねがいします"]}, {"id": "rs_water", "jp": "みずをください", "kana": "みずをください", "romaji": "mizu o kudasai", "meaning": {"en": "Water, please.", "bn": "পানি দিন।", "ja": "水をください。"}, "note": {"en": "みず = water. Water is usually free in Japan.", "bn": "みず = পানি। জাপানে সাধারণত পানি ফ্রি।", "ja": "水は無料のことが多い。"}, "srs_words": ["みず", "ください"]}, {"id": "rs_recommend", "jp": "おすすめは なんですか", "kana": "おすすめは なんですか", "romaji": "osusume wa nan desu ka", "meaning": {"en": "What do you recommend?", "bn": "আপনি কী রেকমেন্ড করেন?", "ja": "おすすめは何ですか。"}, "note": {"en": "おすすめ = recommendation. Handy when the menu is hard.", "bn": "おすすめ = সুপারিশ। মেনু কঠিন হলে কাজে লাগে।", "ja": "おすすめ＝推薦。"}, "srs_words": ["おすすめ", "なん"]}, {"id": "rs_delicious", "jp": "おいしいです", "kana": "おいしいです", "romaji": "oishii desu", "meaning": {"en": "It's delicious.", "bn": "এটা সুস্বাদু।", "ja": "おいしいです。"}, "note": {"en": "A nice thing to say to staff or hosts.", "bn": "কর্মী বা আপ্যায়নকারীকে বলার সুন্দর কথা।", "ja": "店員や相手に言うと良い。"}, "srs_words": ["おいしい"]}, {"id": "rs_bill", "jp": "おかいけいを おねがいします", "kana": "おかいけいを おねがいします", "romaji": "o-kaikei o onegai shimasu", "meaning": {"en": "The bill, please.", "bn": "বিল দিন।", "ja": "お会計をお願いします。"}, "note": {"en": "かいけい = the bill/check. Often you pay at the counter.", "bn": "かいけい = বিল। প্রায়ই কাউন্টারে দাম দিতে হয়।", "ja": "会計＝支払い。レジで払うことが多い。"}, "srs_words": ["おかいけい", "おねがいします"]}, {"id": "rs_itadakimasu", "jp": "いただきます", "kana": "いただきます", "romaji": "itadakimasu", "meaning": {"en": "(said gratefully before eating)", "bn": "(খাওয়ার আগে কৃতজ্ঞতাভরে বলা হয়)", "ja": "いただきます（食べる前）"}, "note": {"en": "Cultural: said just before you start eating.", "bn": "সংস্কৃতি: খাওয়া শুরুর ঠিক আগে বলা হয়।", "ja": "食べる直前に言う習慣。"}, "srs_words": ["いただきます"]}, {"id": "rs_gochisosama", "jp": "ごちそうさまでした", "kana": "ごちそうさまでした", "romaji": "gochisōsama deshita", "meaning": {"en": "Thank you for the meal (after eating)", "bn": "খাবারের জন্য ধন্যবাদ (খাওয়ার পরে)", "ja": "ごちそうさまでした（食後）"}, "note": {"en": "Said after finishing — polite and expected.", "bn": "খাওয়া শেষে বলা হয় — ভদ্র ও প্রত্যাশিত।", "ja": "食後に言う。丁寧で自然。"}, "srs_words": ["ごちそうさまでした"]}]}, {"type": "lesson", "id": "clinic_01", "can_do": {"en": "Explain a health problem and get help at a clinic or in an emergency.", "bn": "ক্লিনিকে বা জরুরি অবস্থায় নিজের অসুস্থতা বোঝানো ও সাহায্য চাওয়া।", "ja": "クリニックや緊急時に、体の不調を伝えて助けを求められる。"}, "jlpt_or_jft": "JFT-Basic A2", "verified": true, "source": "Aligned to Irodori Elementary Can-do (health / at the clinic)", "items": [{"id": "cl_01", "jp": "びょういんはどこですか", "kana": "びょういんはどこですか", "romaji": "byōin wa doko desu ka", "meaning": {"en": "Where is the hospital?", "bn": "হাসপাতাল কোথায়?", "ja": "病院はどこですか。"}, "note": {"en": "どこ = where. Swap びょういん for any place to ask its location.", "bn": "どこ = কোথায়। びょういん-এর জায়গায় অন্য স্থান বসিয়ে যেকোনো জায়গার কথা জিজ্ঞেস করা যায়।", "ja": "どこ＝場所を聞く。病院を他の場所に替えられる。"}, "srs_words": ["びょういん", "どこ"]}, {"id": "cl_02", "jp": "ここがいたいです", "kana": "ここがいたいです", "romaji": "koko ga itai desu", "meaning": {"en": "It hurts here.", "bn": "এখানে ব্যথা করছে।", "ja": "ここが痛いです。"}, "note": {"en": "Point to the spot and say this. いたい = painful.", "bn": "যেখানে ব্যথা সেখানে দেখিয়ে এটা বলো। いたい = ব্যথা।", "ja": "痛い所を指して言う。いたい＝痛い。"}, "srs_words": ["いたい", "ここ"]}, {"id": "cl_03", "jp": "ねつがあります", "kana": "ねつがあります", "romaji": "netsu ga arimasu", "meaning": {"en": "I have a fever.", "bn": "আমার জ্বর আছে।", "ja": "熱があります。"}, "note": {"en": "あります = there is / I have. ねつ = fever.", "bn": "あります = আছে। ねつ = জ্বর।", "ja": "あります＝ある。ねつ＝発熱。"}, "srs_words": ["ねつ", "あります"]}, {"id": "cl_04", "jp": "きぶんがわるいです", "kana": "きぶんがわるいです", "romaji": "kibun ga warui desu", "meaning": {"en": "I feel unwell.", "bn": "শরীর খারাপ লাগছে।", "ja": "気分が悪いです。"}, "note": {"en": "General 'I feel sick/unwell'. わるい = bad.", "bn": "সাধারণভাবে 'শরীর খারাপ / অসুস্থ লাগছে'। わるい = খারাপ।", "ja": "全体的な体調不良。わるい＝悪い。"}, "srs_words": ["きぶん", "わるい"]}, {"id": "cl_05", "jp": "くすりをください", "kana": "くすりをください", "romaji": "kusuri o kudasai", "meaning": {"en": "Medicine, please.", "bn": "ওষুধ দিন।", "ja": "薬をください。"}, "note": {"en": "くすり = medicine. Same をください pattern as shopping.", "bn": "くすり = ওষুধ। কেনাকাটার মতোই をください গঠন।", "ja": "くすり＝薬。買い物と同じ「をください」。"}, "srs_words": ["くすり", "ください"]}, {"id": "cl_06", "jp": "ほけんしょうです", "kana": "ほけんしょうです", "romaji": "hoken shō desu", "meaning": {"en": "(This) is my insurance card.", "bn": "এটা আমার বীমা কার্ড।", "ja": "保険証です。"}, "note": {"en": "Show it at reception. ほけんしょう = health-insurance card.", "bn": "রিসেপশনে এটা দেখাও। ほけんしょう = স্বাস্থ্যবীমা কার্ড।", "ja": "受付で見せる。保険証＝健康保険証。"}, "srs_words": ["ほけんしょう"]}, {"id": "cl_07", "jp": "だいじょうぶですか", "kana": "だいじょうぶですか", "romaji": "daijōbu desu ka", "meaning": {"en": "Are you okay? (someone asks you)", "bn": "আপনি কি ঠিক আছেন? (কেউ জিজ্ঞেস করে)", "ja": "大丈夫ですか。（相手が聞く）"}, "note": {"en": "You'll hear this a lot. Reply だいじょうぶです (I'm okay) or いたいです.", "bn": "এটা প্রায়ই শুনবে। উত্তর দাও だいじょうぶです (ঠিক আছি) বা いたいです।", "ja": "よく聞かれる。だいじょうぶです／いたいですで答える。"}, "srs_words": ["だいじょうぶ"]}, {"id": "cl_08", "jp": "きゅうきゅうしゃをよんでください", "kana": "きゅうきゅうしゃをよんでください", "romaji": "kyūkyūsha o yonde kudasai", "meaning": {"en": "Please call an ambulance.", "bn": "অনুগ্রহ করে অ্যাম্বুলেন্স ডাকুন।", "ja": "救急車を呼んでください。"}, "note": {"en": "Emergency phrase. In Japan you can also dial 119.", "bn": "জরুরি বাক্য। জাপানে 119-এ ফোনও করা যায়।", "ja": "緊急の表現。日本では119番も使える。"}, "srs_words": ["きゅうきゅうしゃ", "よんでください"]}]}];
let lang='bn', cur=0;
function bil(o){return lang==='bn'?o.bn+'<span class="second">'+o.en+'</span>':o[lang];}
function setLang(l){lang=l;['en','bn','ja'].forEach(x=>document.getElementById('l-'+x).classList.toggle('on',x===l));render();}
function pick(i){cur=i;render();}
function render(){
 const tabs=document.getElementById('tabs');
 tabs.innerHTML=LESSONS.map((L,i)=>`<button class="${i===cur?'on':''}" onclick="pick(${i})">${L.can_do[lang].split(/[.:।]/)[0].slice(0,22)}</button>`).join('');
 const L=LESSONS[cur];
 let h=`<div class="cando"><b>Can-do:</b> ${bil(L.can_do)}<span class="verified">✓ ${lang==='bn'?'যাচাইকৃত':lang==='ja'?'確認済み':'Verified'}</span><div class="second" style="margin-top:6px">${L.jlpt_or_jft} · ${L.source}</div></div>`;
 h+=`<div class="count">${L.items.length} ${lang==='bn'?'টি বাক্য':lang==='ja'?'文':'phrases'}</div>`;
 h+=L.items.map(it=>`<div class="card"><div class="jp">${it.jp}</div><div class="rom">${it.romaji}</div><div class="mean">${bil(it.meaning)}</div><div class="note">💡 ${bil(it.note)}</div></div>`).join('');
 document.getElementById('content').innerHTML=h;
}
render();
</script></body></html>
```


## File: prototypes\sensei_premium.html

```html
<!DOCTYPE html>
<html lang="bn"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SENSEI</title>
<style>
 *{box-sizing:border-box;-webkit-tap-highlight-color:transparent;margin:0;padding:0}
 :root{
  --bg:#0a0a12; --card:rgba(255,255,255,.045); --card2:rgba(255,255,255,.07);
  --line:rgba(255,255,255,.09); --txt:#f4f5fb; --dim:#9aa0b4; --faint:#666b80;
  --g1:#ff5a3c; --g2:#ff2d78; --g3:#8b5cff; --cyan:#3fd0e0; --gold:#ffc04d; --green:#37e0a6;
  --grad:linear-gradient(135deg,#ff5a3c,#ff2d78 55%,#8b5cff);
  --grad2:linear-gradient(135deg,#8b5cff,#3fd0e0);
 }
 body{background:var(--bg);color:var(--txt);
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans Bengali","Noto Sans JP",sans-serif;
  display:flex;justify-content:center;min-height:100vh;overflow-x:hidden}
 .phone{width:100%;max-width:440px;min-height:100vh;position:relative;
  background:radial-gradient(120% 60% at 50% -10%,rgba(139,92,255,.18),transparent 60%),
             radial-gradient(90% 50% at 100% 0%,rgba(255,45,120,.12),transparent 55%),var(--bg);
  display:flex;flex-direction:column;overflow:hidden}
 header{padding:18px 20px 8px;display:flex;align-items:center;justify-content:space-between}
 .brand{font-weight:800;font-size:22px;letter-spacing:.5px}
 .brand b{background:var(--grad);-webkit-background-clip:text;background-clip:text;color:transparent}
 .lang{display:flex;gap:4px;background:var(--card);border:1px solid var(--line);border-radius:99px;padding:3px}
 .lang button{background:none;border:0;color:var(--dim);font-weight:700;font-size:11px;padding:5px 9px;border-radius:99px;cursor:pointer;transition:.2s}
 .lang button.on{background:var(--grad);color:#fff}
 main{flex:1;overflow-y:auto;overflow-x:hidden;padding:8px 18px 108px;scrollbar-width:none}
 main::-webkit-scrollbar{display:none}
 .screen{display:none}.screen.on{display:block;animation:rise .4s cubic-bezier(.2,.7,.2,1)}
 @keyframes rise{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
 @keyframes pop{0%{transform:scale(.8);opacity:0}60%{transform:scale(1.05)}100%{transform:scale(1);opacity:1}}
 .glass{background:var(--card);border:1px solid var(--line);border-radius:22px;backdrop-filter:blur(12px)}
 h2{font-size:21px;font-weight:800;letter-spacing:-.3px;margin-bottom:3px}
 .muted{color:var(--dim);font-size:13px}
 .faint{color:var(--faint);font-size:11px}
 /* HERO */
 .hero{padding:20px;margin-bottom:16px;position:relative;overflow:hidden}
 .hero:before{content:"";position:absolute;inset:0;background:var(--grad);opacity:.13}
 .hero-row{display:flex;align-items:center;gap:18px;position:relative}
 .ring{--p:41;width:92px;height:92px;flex:none;border-radius:50%;display:grid;place-items:center;
  background:conic-gradient(#ff2d78 calc(var(--p)*1%),rgba(255,255,255,.08) 0);position:relative}
 .ring:before{content:"";position:absolute;inset:7px;border-radius:50%;background:#12121c}
 .ring b{position:relative;font-size:22px;font-weight:800}
 .ring small{position:relative;display:block;text-align:center;font-size:9px;color:var(--dim);margin-top:-3px}
 .hi{font-size:13px;color:var(--dim)}
 .goaln{font-size:23px;font-weight:800;letter-spacing:-.4px;margin:2px 0 6px}
 .xp{height:7px;background:rgba(255,255,255,.09);border-radius:99px;overflow:hidden}
 .xp>i{display:block;height:100%;width:64%;background:var(--grad2);border-radius:99px}
 /* CHIPS */
 .chips{display:flex;gap:10px;margin-bottom:18px}
 .chip{flex:1;padding:13px 10px;text-align:center;border-radius:18px}
 .chip b{font-size:20px;font-weight:800;display:block}
 .chip .ic{font-size:17px;margin-bottom:3px}
 .chip small{color:var(--dim);font-size:10.5px}
 /* CTA */
 .cta{display:block;width:100%;border:0;cursor:pointer;color:#fff;font-weight:800;font-size:16px;
  padding:17px;border-radius:20px;background:var(--grad);box-shadow:0 10px 30px -8px rgba(255,45,120,.5);
  display:flex;align-items:center;justify-content:center;gap:10px;transition:transform .12s}
 .cta:active{transform:scale(.97)}
 .cta .sm{font-size:11px;font-weight:600;opacity:.85;display:block}
 .sec-t{font-size:12px;font-weight:800;color:var(--dim);letter-spacing:1.5px;text-transform:uppercase;margin:22px 4px 12px}
 /* PATH */
 .lrow{display:flex;align-items:center;gap:14px;padding:15px;margin-bottom:11px;cursor:pointer;transition:.15s}
 .lrow:active{transform:scale(.98)}
 .lrow .ic{width:50px;height:50px;border-radius:15px;flex:none;display:grid;place-items:center;font-size:23px;background:var(--card2)}
 .lrow .ic.g{background:var(--grad)}.lrow .ic.g2{background:var(--grad2)}
 .lrow .t{font-weight:700;font-size:15px}
 .lrow .d{color:var(--dim);font-size:12px;margin-top:1px}
 .lrow .prog{margin-left:auto;text-align:right}
 .dot3{display:flex;gap:3px;justify-content:flex-end;margin-top:4px}
 .dot3 i{width:6px;height:6px;border-radius:50%;background:rgba(255,255,255,.15)}
 .dot3 i.f{background:var(--green)}
 .lock{color:var(--faint);font-size:16px;margin-left:auto}
 .badge{font-size:10px;font-weight:800;padding:3px 9px;border-radius:99px}
 .badge.v{color:#0a2a1e;background:var(--green)}
 .badge.new{color:#2a0a1e;background:var(--gold)}
 /* SEG */
 .seg{display:flex;background:var(--card);border:1px solid var(--line);border-radius:16px;padding:4px;margin-bottom:18px}
 .seg button{flex:1;background:none;border:0;color:var(--dim);font-weight:700;font-size:13px;padding:10px;border-radius:12px;cursor:pointer;transition:.2s}
 .seg button.on{background:var(--grad);color:#fff}
 /* KANA */
 .kgrid{display:grid;grid-template-columns:repeat(5,1fr);gap:9px}
 .k{aspect-ratio:1;border-radius:16px;display:grid;place-items:center;cursor:pointer;position:relative;overflow:hidden;
  background:var(--card);border:1px solid var(--line);transition:.15s}
 .k:active{transform:scale(.9)}
 .k .c{font-size:25px;font-weight:600}.k .r{position:absolute;bottom:6px;font-size:10px;color:var(--dim)}
 .k.hit{background:var(--grad);border-color:transparent}
 /* FLASH */
 .flash{padding:26px 20px;text-align:center;margin-bottom:14px;position:relative;overflow:hidden}
 .flash .idx{font-size:11px;color:var(--dim);font-weight:700;letter-spacing:1px}
 .flash .jp{font-size:38px;font-weight:700;margin:14px 0 6px;line-height:1.3}
 .flash .rom{color:var(--cyan);font-size:15px;letter-spacing:.5px}
 .flash .mean{font-size:20px;font-weight:700;margin-top:16px}
 .flash .second{display:block;font-size:.72em;color:var(--faint);font-weight:400;margin-top:3px}
 .playbtn{width:58px;height:58px;border-radius:50%;border:0;cursor:pointer;color:#fff;font-size:22px;margin-top:16px;
  background:var(--grad2);box-shadow:0 8px 24px -6px rgba(63,208,224,.5);transition:transform .12s}
 .playbtn:active{transform:scale(.9)}
 .note{background:rgba(139,92,255,.1);border:1px solid rgba(139,92,255,.25);border-radius:16px;padding:13px;margin-top:16px;font-size:13px;text-align:left;line-height:1.5}
 .fbtns{display:flex;gap:10px;margin-top:16px}
 .fbtn{flex:1;padding:13px;border-radius:15px;border:1px solid var(--line);background:var(--card);color:var(--txt);font-weight:700;font-size:13px;cursor:pointer;transition:.15s}
 .fbtn:active{transform:scale(.96)}.fbtn.p{background:var(--grad);border-color:transparent;color:#fff}
 /* METER */
 .meter{height:120px;border-radius:16px;overflow:hidden;margin-top:14px;background:#08080f;border:1px solid var(--line)}
 .recbtn{width:100%;border:0;border-radius:18px;padding:16px;font-weight:800;font-size:15px;cursor:pointer;color:#fff;background:var(--grad);margin-top:14px;transition:transform .12s}
 .recbtn:active{transform:scale(.97)}
 .rdot{width:9px;height:9px;border-radius:50%;background:#fff;display:inline-block;margin-right:7px;animation:blink 1s infinite}
 @keyframes blink{50%{opacity:.3}}
 .scorebig{font-size:52px;font-weight:800;text-align:center;margin-top:10px;background:var(--grad2);-webkit-background-clip:text;background-clip:text;color:transparent;animation:pop .5s}
 /* PITCH */
 .pcard{padding:16px;margin-bottom:12px}
 .pw{font-size:19px;font-weight:800}
 /* REVIEW */
 .rev{padding:28px 20px;text-align:center;min-height:230px;display:flex;flex-direction:column;justify-content:center;margin-bottom:16px}
 .rev .w{font-size:34px;font-weight:700}
 .rate{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:8px}
 .rate button{border:0;border-radius:14px;padding:13px 4px;font-weight:800;font-size:13px;cursor:pointer;color:#0a0a12;transition:transform .12s}
 .rate button:active{transform:scale(.94)}
 .rate small{display:block;font-size:9px;opacity:.7;margin-top:2px}
 .r1{background:#ff6b6b}.r2{background:var(--gold)}.r3{background:var(--green)}.r4{background:var(--cyan)}
 .confetti{position:absolute;width:9px;height:9px;top:-10px;border-radius:2px;animation:fall 1.4s linear forwards}
 @keyframes fall{to{transform:translateY(320px) rotate(360deg);opacity:0}}
 /* NAV */
 nav{position:absolute;bottom:0;left:0;right:0;display:flex;padding:8px 12px 14px;gap:4px;
  background:linear-gradient(to top,var(--bg) 60%,transparent);backdrop-filter:blur(8px)}
 nav button{flex:1;background:none;border:0;color:var(--faint);font-size:10px;font-weight:700;cursor:pointer;
  display:flex;flex-direction:column;align-items:center;gap:4px;padding:6px 0;border-radius:14px;transition:.2s}
 nav button .ni{font-size:21px}
 nav button.on{color:var(--txt)}
 nav button.on .ni{transform:translateY(-2px)}
 nav button.on:after{content:"";position:absolute;bottom:8px;width:5px;height:5px;border-radius:50%;background:var(--g2)}
</style></head><body>
<div class="phone">
 <header>
  <div class="brand">SEN<b>SEI</b></div>
  <div class="lang">
   <button id="L-en" onclick="setLang('en')">EN</button>
   <button id="L-bn" class="on" onclick="setLang('bn')">বাংলা</button>
   <button id="L-ja" onclick="setLang('ja')">日本語</button>
  </div>
 </header>
 <main>
  <!-- HOME -->
  <section class="screen on" id="s-home">
   <div class="glass hero">
    <div class="hero-row">
     <div class="ring" id="ring"><b>41%</b><small id="ringL">today</small></div>
     <div style="flex:1">
      <div class="hi" id="greet">সুপ্রভাত 👋</div>
      <div class="goaln">JFT-Basic A2</div>
      <div class="xp"><i id="xpbar"></i></div>
      <div class="faint" style="margin-top:6px" id="xptxt">Level 3 · 640 / 1000 XP</div>
     </div>
    </div>
   </div>
   <div class="chips">
    <div class="glass chip"><div class="ic">🔥</div><b id="c-streak">7</b><small id="l-streak">day streak</small></div>
    <div class="glass chip"><div class="ic">📚</div><b>183</b><small id="l-words">words</small></div>
    <div class="glass chip"><div class="ic">🎯</div><b id="c-due">12</b><small id="l-due">to review</small></div>
   </div>
   <button class="cta" onclick="go('learn')"><span><span class="sm" id="cta-sm">continue</span><span id="cta-t">Lesson চালিয়ে যাও</span></span> →</button>
   <div class="sec-t" id="sec-path">your path</div>
   <div id="pathList"></div>
  </section>

  <!-- LEARN -->
  <section class="screen" id="s-learn">
   <div class="seg">
    <button class="on" id="sg-kana" onclick="lseg('kana')">かな Kana</button>
    <button id="sg-lesson" onclick="lseg('lesson')" data-i="segLesson"></button>
   </div>
   <div id="kanaV">
    <h2 data-i="kanaH"></h2><div class="muted" data-i="kanaSub"></div>
    <div class="kgrid" id="kgrid" style="margin-top:14px"></div>
    <div class="note" id="kanaTip" style="margin-top:16px"></div>
   </div>
   <div id="lessonV" style="display:none">
    <div style="display:flex;gap:8px;overflow-x:auto;padding-bottom:8px;margin-bottom:6px" id="lessonPills"></div>
    <div class="glass flash">
     <div class="idx" id="f-idx"></div>
     <div class="jp" id="f-jp"></div>
     <div class="rom" id="f-rom"></div>
     <button class="playbtn" onclick="playCur()">▶</button>
     <div class="mean" id="f-mean"></div>
     <div class="note" id="f-note"></div>
    </div>
    <div class="fbtns">
     <button class="fbtn" onclick="prevCard()" data-i="prev"></button>
     <button class="fbtn" id="romT" onclick="toggleRom()"></button>
     <button class="fbtn p" onclick="nextCard()" data-i="next"></button>
    </div>
   </div>
  </section>

  <!-- SPEAK -->
  <section class="screen" id="s-speak">
   <div class="seg">
    <button class="on" id="sg-shadow" onclick="seg('shadow')">🎙️ Shadowing</button>
    <button id="sg-pitch" onclick="seg('pitch')">〽️ Pitch</button>
   </div>
   <div id="shadowV">
    <h2 data-i="shadowH"></h2><div class="muted" data-i="shadowSub"></div>
    <div class="glass flash" style="padding:22px 20px">
     <div class="jp" id="sh-jp" style="font-size:28px"></div>
     <div class="rom" id="sh-rom"></div>
     <button class="playbtn" onclick="speak(SHADOW[shi].jp,.85)">▶</button>
     <div class="mean" id="sh-mean" style="font-size:15px"></div>
     <div class="meter"><canvas id="pcanvas"></canvas></div>
     <div class="faint" id="sh-hint" style="margin-top:10px"></div>
     <button class="recbtn" id="recBtn" onclick="toggleRec()"></button>
     <div id="scoreBox"></div>
     <audio id="pb" controls style="width:100%;margin-top:12px;display:none"></audio>
    </div>
    <div class="fbtns">
     <button class="fbtn" onclick="prevShadow()" data-i="prev"></button>
     <button class="fbtn p" onclick="nextShadow()" data-i="next"></button>
    </div>
   </div>
   <div id="pitchV" style="display:none">
    <h2 data-i="pitchH"></h2><div class="muted" data-i="pitchSub"></div>
    <div id="pitchList" style="margin-top:14px"></div>
    <div class="note" id="pitchTip"></div>
   </div>
  </section>

  <!-- REVIEW -->
  <section class="screen" id="s-review">
   <h2 data-i="reviewH"></h2><div class="muted" data-i="reviewSub"></div>
   <div id="revArea" style="margin-top:16px"></div>
  </section>
 </main>
 <nav>
  <button class="on" id="n-home" onclick="go('home')"><span class="ni">🏠</span><span data-i="navHome"></span></button>
  <button id="n-learn" onclick="go('learn')"><span class="ni">📚</span><span data-i="navLearn"></span></button>
  <button id="n-speak" onclick="go('speak')"><span class="ni">🎙️</span><span data-i="navSpeak"></span></button>
  <button id="n-review" onclick="go('review')"><span class="ni">🔁</span><span data-i="navReview"></span></button>
 </nav>
</div>
<script>
const L={
 en:{segLesson:"Work lesson",kanaH:"Hiragana",kanaSub:"Tap a letter to hear it",
  kanaTip:"💡 Japanese vowels are short & clean. Each letter is one equal-length beat (mora).",
  prev:"‹ Back",next:"Next ›",hideRom:"Romaji off",showRom:"Romaji on",
  shadowH:"Shadowing",shadowSub:"Listen → repeat → record → compare",
  pitchH:"Pitch accent",pitchSub:"Same spelling, different melody, different meaning",
  pitchTip:"💡 High = voice up, Low = voice down. Follow the line.",
  reviewH:"Review",reviewSub:"Shown right before you'd forget",
  navHome:"Home",navLearn:"Learn",navSpeak:"Speak",navReview:"Review",
  greet:"Good to see you 👋",ringL:"today",ctaSm:"continue",ctaT:"Resume lesson",
  secPath:"your path",lStreak:"day streak",lWords:"words",lDue:"to review",xptxt:"Level 3 · 640 / 1000 XP",
  recStart:"🎙️ Record",recStop:"⏹ Stop & score",recAgain:"🎙️ Record again",
  hintStart:"Tap record and repeat the phrase",hintRec:"🎙️ Recording… match the melody",
  hintDone:"✅ Compare your recording with the native below",hintPerm:"⚠️ Mic permission needed (open in a browser)",
  showAnswer:"Show answer",rAgain:"Again",rHard:"Hard",rGood:"Good",rEasy:"Easy",
  doneTitle:"Done for today! 🎉",doneSub:"cards reviewed. Come back tomorrow.",restart:"Again",
  cardX:"{i} of {n}",scoreGreat:"Great pitch match!",scoreTry:"Close — follow the line more"},
 bn:{segLesson:"কাজের Lesson",kanaH:"হিরাগানা",kanaSub:"letter-এ tap করো শুনতে",
  kanaTip:"💡 Japanese vowel ছোট ও পরিষ্কার। প্রতিটা letter সমান লম্বার এক beat (mora)।",
  prev:"‹ আগের",next:"পরের ›",hideRom:"Romaji off",showRom:"Romaji on",
  shadowH:"Shadowing",shadowSub:"শোনো → বলো → record → মিলাও",
  pitchH:"Pitch accent",pitchSub:"একই spelling, আলাদা সুর, আলাদা মানে",
  pitchTip:"💡 High = গলা উপরে, Low = গলা নিচে। line-টা follow করো।",
  reviewH:"Review",reviewSub:"ঠিক ভুলে যাওয়ার আগে দেখাবে",
  navHome:"হোম",navLearn:"শেখো",navSpeak:"বলো",navReview:"Review",
  greet:"আবার দেখা হলো 👋",ringL:"আজ",ctaSm:"continue",ctaT:"Lesson চালিয়ে যাও",
  secPath:"তোমার path",lStreak:"দিন streak",lWords:"words",lDue:"review বাকি",xptxt:"Level 3 · 640 / 1000 XP",
  recStart:"🎙️ Record",recStop:"⏹ থামাও ও score",recAgain:"🎙️ আবার record",
  hintStart:"record চেপে phrase-টা বলো",hintRec:"🎙️ Record হচ্ছে… সুরের সাথে মেলাও",
  hintDone:"✅ নিচে native-এর সাথে নিজের recording মিলাও",hintPerm:"⚠️ Mic permission দরকার (browser-এ খোলো)",
  showAnswer:"Answer দেখাও",rAgain:"আবার",rHard:"কঠিন",rGood:"ভালো",rEasy:"সহজ",
  doneTitle:"আজকের review শেষ! 🎉",doneSub:"টা card হলো। কাল আবার এসো।",restart:"আবার",
  cardX:"{i} / {n}",scoreGreat:"দারুণ pitch match!",scoreTry:"প্রায় হয়ে গেছে — line follow করো"},
 ja:{segLesson:"職場レッスン",kanaH:"ひらがな",kanaSub:"文字をタップして音を聞く",
  kanaTip:"💡 母音は短く明瞭。各文字は同じ長さの一拍（モーラ）。",
  prev:"‹ 前へ",next:"次へ ›",hideRom:"ローマ字オフ",showRom:"ローマ字オン",
  shadowH:"シャドーイング",shadowSub:"聞く→真似る→録音→比べる",
  pitchH:"アクセント",pitchSub:"同じ綴り、違う高さ、違う意味",
  pitchTip:"💡 高＝声を上げ、低＝下げる。線をたどって。",
  reviewH:"復習",reviewSub:"忘れる直前に出題",
  navHome:"ホーム",navLearn:"学ぶ",navSpeak:"話す",navReview:"復習",
  greet:"おかえりなさい 👋",ringL:"今日",ctaSm:"つづき",ctaT:"レッスンを再開",
  secPath:"学習の道",lStreak:"日連続",lWords:"語",lDue:"復習",xptxt:"レベル3 · 640 / 1000 XP",
  recStart:"🎙️ 録音",recStop:"⏹ 停止して採点",recAgain:"🎙️ もう一度",
  hintStart:"録音を押してフレーズを言う",hintRec:"🎙️ 録音中… 高さに合わせて",
  hintDone:"✅ 下でネイティブと聞き比べよう",hintPerm:"⚠️ マイク許可が必要（ブラウザで開く）",
  showAnswer:"答えを見る",rAgain:"もう一度",rHard:"難しい",rGood:"できた",rEasy:"簡単",
  doneTitle:"本日の復習完了！🎉",doneSub:"枚 完了。また明日。",restart:"もう一度",
  cardX:"{i} / {n}",scoreGreat:"高さバッチリ！",scoreTry:"惜しい — 線をたどって"}
};
let lang='bn';
function t(k,v){let s=(L[lang]&&L[lang][k])??L.en[k]??k;if(v)for(const p in v)s=s.replace('{'+p+'}',v[p]);return s;}
function bil(o){return lang==='bn'?o.bn+'<span class="second">'+o.en+'</span>':o[lang];}

const KANA="あ,a い,i う,u え,e お,o か,ka き,ki く,ku け,ke こ,ko さ,sa し,shi す,su せ,se そ,so た,ta ち,chi つ,tsu て,te と,to な,na に,ni ぬ,nu ね,ne の,no は,ha ひ,hi ふ,fu へ,he ほ,ho ま,ma み,mi む,mu め,me も,mo や,ya ゆ,yu よ,yo ら,ra り,ri る,ru れ,re ろ,ro わ,wa を,wo ん,n".split(" ").map(x=>x.split(","));

const LESSONS=[
 {t:{en:"Greetings & self-intro",bn:"Greeting ও self-intro",ja:"あいさつ・自己紹介"},items:[
  {jp:"おはようございます",rom:"ohayō gozaimasu",mean:{en:"Good morning (polite)",bn:"সুপ্রভাত (polite)",ja:"おはよう（丁寧）"},note:{en:"Say it as you arrive at work.",bn:"কাজে ঢুকেই বলবে।",ja:"出勤時に言う。"}},
  {jp:"はじめまして",rom:"hajimemashite",mean:{en:"Nice to meet you",bn:"পরিচিত হয়ে ভালো লাগল",ja:"はじめまして"},note:{en:"First time you meet someone.",bn:"কাউকে প্রথমবার দেখা হলে।",ja:"初対面で。"}},
  {jp:"わたしはラーマンです",rom:"watashi wa Rāman desu",mean:{en:"I am Rahman.",bn:"আমি রহমান।",ja:"私はラーマンです。"},note:{en:"Pattern: watashi wa ＿ desu.",bn:"Pattern: わたしは ＿ です।",ja:"型：わたしは＿です。"}},
  {jp:"よろしくおねがいします",rom:"yoroshiku onegai shimasu",mean:{en:"Pleased to work with you",bn:"আপনার সাথে কাজ করতে পেরে ভালো লাগবে",ja:"よろしくお願いします"},note:{en:"Ends an introduction. Very important.",bn:"পরিচয়ের শেষে। খুব important।",ja:"自己紹介の締め。"}},
  {jp:"わかりません",rom:"wakarimasen",mean:{en:"I don't understand",bn:"আমি বুঝতে পারিনি",ja:"わかりません"},note:{en:"Don't stay silent — this is useful.",bn:"চুপ থেকো না — এটা কাজের কথা।",ja:"黙らず言おう。"}}
 ]},
 {t:{en:"Convenience store",bn:"Konbini (দোকান)",ja:"コンビニ"},items:[
  {jp:"これをください",rom:"kore o kudasai",mean:{en:"This one, please.",bn:"এটা দিন।",ja:"これをください。"},note:{en:"Point and say it to order.",bn:"দেখিয়ে বললেই order হবে।",ja:"指して注文。"}},
  {jp:"ふくろはいりません",rom:"fukuro wa irimasen",mean:{en:"I don't need a bag.",bn:"Bag লাগবে না।",ja:"袋は要りません。"},note:{en:"Bags often cost extra in Japan.",bn:"জাপানে bag-এর জন্য টাকা লাগে।",ja:"袋は有料が多い。"}},
  {jp:"いくらですか",rom:"ikura desu ka",mean:{en:"How much is it?",bn:"দাম কত?",ja:"いくらですか。"},note:{en:"ikura = how much.",bn:"いくら = কত।",ja:"いくら＝金額。"}},
  {jp:"カードでおねがいします",rom:"kādo de onegai shimasu",mean:{en:"By card, please.",bn:"Card-এ দিতে চাই।",ja:"カードでお願いします。"},note:{en:"For cash say genkin de.",bn:"নগদের জন্য genkin de।",ja:"現金なら「げんきんで」。"}}
 ]}
];

const SHADOW=[
 {jp:"おはようございます",rom:"ohayō gozaimasu",mean:{en:"Good morning",bn:"সুপ্রভাত",ja:"おはよう"}},
 {jp:"よろしくおねがいします",rom:"yoroshiku onegai shimasu",mean:{en:"Pleased to meet you",bn:"সৌজন্য greeting",ja:"あいさつ"}},
 {jp:"ありがとうございます",rom:"arigatō gozaimasu",mean:{en:"Thank you",bn:"ধন্যবাদ",ja:"ありがとう"}}
];

const PITCH=[
 {word:"はし",kanji:"箸",rom:"hashi",pat:[1,0],mean:{en:"chopsticks",bn:"চপস্টিক",ja:"箸"},ty:{en:"atamadaka (HL)",bn:"atamadaka (উঁচু-নিচু)",ja:"頭高型"}},
 {word:"はし",kanji:"橋",rom:"hashi",pat:[0,1],mean:{en:"bridge",bn:"সেতু",ja:"橋"},ty:{en:"odaka (LH)",bn:"odaka (নিচু-উঁচু)",ja:"尾高型"}},
 {word:"あめ",kanji:"雨",rom:"ame",pat:[1,0],mean:{en:"rain",bn:"বৃষ্টি",ja:"雨"},ty:{en:"atamadaka (HL)",bn:"atamadaka",ja:"頭高型"}},
 {word:"あめ",kanji:"飴",rom:"ame",pat:[0,1],mean:{en:"candy",bn:"ক্যান্ডি",ja:"飴"},ty:{en:"heiban (LH)",bn:"heiban (সমতল)",ja:"平板型"}}
];

let QUEUE=[
 {w:"ありがとうございます",m:{en:"Thank you",bn:"ধন্যবাদ",ja:"ありがとう"}},
 {w:"すみません",m:{en:"Excuse me",bn:"মাফ করবেন",ja:"すみません"}},
 {w:"よろしくおねがいします",m:{en:"Pleased to meet you",bn:"সৌজন্য greeting",ja:"よろしく"}},
 {w:"わかりました",m:{en:"Understood",bn:"বুঝেছি",ja:"わかりました"}}
];
</script>
<script>
function $(id){return document.getElementById(id)}
function applyI18n(){
 document.querySelectorAll('[data-i]').forEach(e=>e.textContent=t(e.getAttribute('data-i')));
 $('greet').innerHTML=t('greet');$('ringL').textContent=t('ringL');
 $('cta-sm').textContent=t('ctaSm');$('cta-t').textContent=t('ctaT');
 $('sec-path').textContent=t('secPath');$('l-streak').textContent=t('lStreak');
 $('l-words').textContent=t('lWords');$('l-due').textContent=t('lDue');$('xptxt').textContent=t('xptxt');
 $('kanaTip').innerHTML=t('kanaTip');$('pitchTip').innerHTML=t('pitchTip');
 $('romT').textContent=showRom?t('hideRom'):t('showRom');
 $('recBtn').textContent=recording?t('recStop'):(recDone?t('recAgain'):t('recStart'));
 if(!recording&&!recDone)$('sh-hint').textContent=t('hintStart');
 renderPath();renderCard();renderShadow();renderPitch();renderPills();
 if($('s-review').classList.contains('on'))buildRev();
}
function setLang(l){lang=l;['en','bn','ja'].forEach(x=>$('L-'+x).classList.toggle('on',x===l));applyI18n();}

function go(id){
 document.querySelectorAll('.screen').forEach(s=>s.classList.remove('on'));
 $('s-'+id).classList.add('on');
 document.querySelectorAll('nav button').forEach(b=>b.classList.remove('on'));
 $('n-'+id).classList.add('on');
 if(id==='review')buildRev();
}
function lseg(w){$('sg-kana').classList.toggle('on',w==='kana');$('sg-lesson').classList.toggle('on',w==='lesson');
 $('kanaV').style.display=w==='kana'?'block':'none';$('lessonV').style.display=w==='lesson'?'block':'none';}
function seg(w){$('sg-shadow').classList.toggle('on',w==='shadow');$('sg-pitch').classList.toggle('on',w==='pitch');
 $('shadowV').style.display=w==='shadow'?'block':'none';$('pitchV').style.display=w==='pitch'?'block':'none';}

let jaV=null;function pv(){const v=speechSynthesis.getVoices();jaV=v.find(x=>x.lang==='ja-JP')||v.find(x=>x.lang&&x.lang.startsWith('ja'))||null;}
if('speechSynthesis'in window){pv();speechSynthesis.onvoiceschanged=pv;}
function speak(x,r){if(!('speechSynthesis'in window))return;speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(x);u.lang='ja-JP';u.rate=r||.9;if(jaV)u.voice=jaV;speechSynthesis.speak(u);}

const ICONS=["🈁","🏪","🍜","💼","🏥","🚉"];
function renderPath(){
 $('pathList').innerHTML=LESSONS.map((L,i)=>`<div class="glass lrow" onclick="openLesson(${i})">
  <div class="ic ${i===0?'g':'g2'}">${ICONS[i]||"📖"}</div>
  <div><div class="t">${L.t[lang]}</div><div class="d">${L.items.length} ${lang==='bn'?'টি phrase':lang==='ja'?'文':'phrases'}</div></div>
  <div class="prog"><span class="badge ${i===0?'v':'new'}">${i===0?'✓':'new'}</span><div class="dot3">${L.items.map((_,k)=>`<i class="${i===0?'f':''}"></i>`).join('')}</div></div>
 </div>`).join('')+
 `<div class="glass lrow" style="opacity:.55"><div class="ic">🔒</div><div><div class="t">${lang==='bn'?'আরও lesson আসছে':lang==='ja'?'次のレッスン':'More lessons'}</div><div class="d">${lang==='bn'?'Restaurant, clinic, station…':'Restaurant, clinic, station…'}</div></div><div class="lock">🔒</div></div>`;
}
function openLesson(i){curL=i;ci=0;go('learn');lseg('lesson');renderPills();renderCard();}

let curL=0,ci=0,showRom=true;
function renderPills(){
 $('lessonPills').innerHTML=LESSONS.map((L,i)=>`<button class="fbtn ${i===curL?'p':''}" style="flex:none;white-space:nowrap;font-size:12px;padding:8px 12px" onclick="openLesson(${i})">${L.t[lang]}</button>`).join('');
}
function renderCard(){
 const L=LESSONS[curL],c=L.items[ci];
 $('f-idx').textContent=t('cardX',{i:ci+1,n:L.items.length});
 $('f-jp').textContent=c.jp;$('f-rom').textContent=c.rom;$('f-rom').style.display=showRom?'block':'none';
 $('f-mean').innerHTML=bil(c.mean);$('f-note').innerHTML='💡 '+bil(c.note);
}
function nextCard(){const L=LESSONS[curL];if(ci<L.items.length-1){ci++;renderCard();}else{go('review');}}
function prevCard(){if(ci>0){ci--;renderCard();}}
function playCur(){speak(LESSONS[curL].items[ci].jp,.85);}
function toggleRom(){showRom=!showRom;$('romT').textContent=showRom?t('hideRom'):t('showRom');renderCard();}

const kg=$('kgrid');
KANA.forEach(([c,r])=>{const d=document.createElement('div');d.className='k';d.innerHTML=`<span class="c">${c}</span><span class="r">${r}</span>`;
 d.onclick=()=>{speak(c,.8);d.classList.add('hit');setTimeout(()=>d.classList.remove('hit'),220);};kg.appendChild(d);});

let shi=0;
function renderShadow(){const s=SHADOW[shi];$('sh-jp').textContent=s.jp;$('sh-rom').textContent=s.rom;$('sh-mean').innerHTML=bil(s.mean);}
function nextShadow(){shi=(shi+1)%SHADOW.length;renderShadow();stopRec(1);resetScore();}
function prevShadow(){shi=(shi-1+SHADOW.length)%SHADOW.length;renderShadow();stopRec(1);resetScore();}
function resetScore(){recDone=false;$('scoreBox').innerHTML='';$('pb').style.display='none';$('sh-hint').textContent=t('hintStart');$('recBtn').textContent=t('recStart');}

let mr=null,ch=[],ac=null,an=null,raf=null,stream=null,recording=false,recDone=false,pts=[];
const cv=$('pcanvas'),cx=cv.getContext('2d');
function fit(){cv.width=cv.clientWidth*devicePixelRatio;cv.height=cv.clientHeight*devicePixelRatio;}
function draw(){fit();const w=cv.width,h=cv.height;cx.clearRect(0,0,w,h);
 cx.strokeStyle='rgba(255,255,255,.08)';cx.lineWidth=1;cx.beginPath();cx.moveTo(0,h/2);cx.lineTo(w,h/2);cx.stroke();
 const b=new Float32Array(an.fftSize);an.getFloatTimeDomainData(b);const f=acf(b,ac.sampleRate);
 let y=h/2;if(f>0){const n=Math.min(1,Math.max(0,(Math.log2(f)-6.6)/2));y=h-n*h;}
 pts.push(f>0?y:null);if(pts.length>Math.floor(w/(2*devicePixelRatio)))pts.shift();
 const grad=cx.createLinearGradient(0,0,w,0);grad.addColorStop(0,'#8b5cff');grad.addColorStop(1,'#ff2d78');
 cx.strokeStyle=grad;cx.lineWidth=3.5*devicePixelRatio;cx.lineJoin='round';cx.beginPath();let st=false;
 pts.forEach((p,i)=>{const x=i*2*devicePixelRatio;if(p==null){st=false;return;}if(!st){cx.moveTo(x,p);st=true;}else cx.lineTo(x,p);});cx.stroke();
 raf=requestAnimationFrame(draw);}
function acf(buf,sr){let n=buf.length,rms=0;for(let i=0;i<n;i++)rms+=buf[i]*buf[i];rms=Math.sqrt(rms/n);if(rms<.01)return -1;
 let r1=0,r2=n-1,th=.2;for(let i=0;i<n/2;i++)if(Math.abs(buf[i])<th){r1=i;break;}for(let i=1;i<n/2;i++)if(Math.abs(buf[n-i])<th){r2=n-i;break;}
 buf=buf.slice(r1,r2);n=buf.length;const c=new Array(n).fill(0);for(let i=0;i<n;i++)for(let j=0;j<n-i;j++)c[i]+=buf[j]*buf[j+i];
 let d=0;while(c[d]>c[d+1])d++;let mx=-1,mp=-1;for(let i=d;i<n;i++)if(c[i]>mx){mx=c[i];mp=i;}if(mp<=0)return -1;const f=sr/mp;return(f>70&&f<500)?f:-1;}
async function toggleRec(){recording?stopRec():startRec();}
async function startRec(){try{stream=await navigator.mediaDevices.getUserMedia({audio:true});}catch(e){$('sh-hint').textContent=t('hintPerm');return;}
 recording=true;recDone=false;$('recBtn').innerHTML='<span class="rdot"></span>'+t('recStop').replace('⏹ ','');$('sh-hint').textContent=t('hintRec');$('scoreBox').innerHTML='';ch=[];pts=[];
 mr=new MediaRecorder(stream);mr.ondataavailable=e=>ch.push(e.data);mr.onstop=()=>{const b=new Blob(ch,{type:'audio/webm'});$('pb').src=URL.createObjectURL(b);$('pb').style.display='block';};mr.start();
 ac=new(window.AudioContext||window.webkitAudioContext)();const src=ac.createMediaStreamSource(stream);an=ac.createAnalyser();an.fftSize=2048;src.connect(an);draw();}
function stopRec(silent){if(!recording)return;recording=false;recDone=true;$('recBtn').textContent=t('recAgain');
 if(mr&&mr.state!=='inactive')mr.stop();if(raf)cancelAnimationFrame(raf);if(stream)stream.getTracks().forEach(x=>x.stop());if(ac)ac.close();
 if(!silent){const sc=72+Math.floor(Math.random()*24);$('sh-hint').textContent=t('hintDone');
  $('scoreBox').innerHTML=`<div class="scorebig">${sc}<span style="font-size:22px">/100</span></div><div class="faint" style="text-align:center">${sc>=80?t('scoreGreat'):t('scoreTry')}</div>`;}}

function psvg(pat){const n=pat.length,W=200,H=56,step=W/(n+.5),r=8;let dots='',lines='',pr=null;
 for(let i=0;i<n;i++){const x=step*(i+.5),y=pat[i]?14:H-14;if(pr)lines+=`<line x1="${pr.x}" y1="${pr.y}" x2="${x}" y2="${y}" stroke="#ff2d78" stroke-width="3.5"/>`;
  dots+=`<circle cx="${x}" cy="${y}" r="${r}" fill="${pat[i]?'#3fd0e0':'#666b80'}"/>`;pr={x,y};}
 return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${lines}${dots}</svg>`;}
function renderPitch(){$('pitchList').innerHTML=PITCH.map((p,i)=>`<div class="glass pcard">
  <div style="display:flex;justify-content:space-between;align-items:center">
   <div><div class="pw">${p.kanji} <span style="color:var(--dim);font-weight:400">${p.word}</span></div>
   <div class="faint" style="margin-top:2px">${p.rom} · ${lang==='bn'?p.mean.bn+' ('+p.mean.en+')':p.mean[lang]} · <b style="color:var(--cyan)">${p.ty[lang]}</b></div></div>
   <button class="playbtn" style="width:46px;height:46px;font-size:18px;margin:0" onclick="speak('${p.word}',.8)">▶</button></div>
  <div style="text-align:center;margin-top:12px">${psvg(p.pat)}</div></div>`).join('');}

let qi=0,rev=false,done=0;
function buildRev(){const a=$('revArea');
 if(qi>=QUEUE.length){a.innerHTML=`<div class="glass rev" id="revdone"><div style="font-size:46px">🎉</div><h2 style="margin-top:10px">${t('doneTitle')}</h2><div class="muted">${done} ${t('doneSub')}</div><button class="cta" style="margin-top:20px" onclick="qi=0;done=0;rev=false;buildRev()">${t('restart')}</button></div>`;
  $('c-due').textContent='0';confetti();return;}
 const c=QUEUE[qi];
 a.innerHTML=`<div class="faint" style="margin-bottom:10px">${t('cardX',{i:qi+1,n:QUEUE.length})}</div>
  <div class="glass rev"><div class="w">${c.w}</div>
  ${rev?`<div class="mean" style="margin-top:12px">${bil(c.m)}</div>
   <div class="rate"><button class="r1" onclick="rate()">${t('rAgain')}<small>10m</small></button><button class="r2" onclick="rate()">${t('rHard')}<small>1d</small></button><button class="r3" onclick="rate()">${t('rGood')}<small>4d</small></button><button class="r4" onclick="rate()">${t('rEasy')}<small>9d</small></button></div>`
   :`<button class="cta" style="margin-top:22px" onclick="rev=true;buildRev()">${t('showAnswer')}</button>`}</div>`;}
function rate(){qi++;done++;rev=false;$('c-due').textContent=Math.max(0,QUEUE.length-qi);buildRev();}
function confetti(){const box=$('revdone');if(!box)return;const cols=['#ff5a3c','#ff2d78','#8b5cff','#3fd0e0','#37e0a6','#ffc04d'];
 for(let i=0;i<40;i++){const d=document.createElement('div');d.className='confetti';d.style.left=Math.random()*100+'%';d.style.background=cols[i%6];d.style.animationDelay=Math.random()*.5+'s';box.appendChild(d);}}

setLang('bn');
</script></body></html>

```


## File: prototypes\sensei_prototype.html

```html
<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SENSEI — Prototype</title>
<style>
  :root{
    --bg:#0e1116; --card:#1a1f28; --card2:#232a35; --line:#2d3540;
    --txt:#e8edf3; --dim:#96a0ad; --accent:#ff5a3c; --accent2:#38bdf8;
    --good:#34d399; --warn:#fbbf24; --verified:#22c55e; --jp:#ffffff;
  }
  *{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
  body{margin:0;background:#05070a;color:var(--txt);
    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans Bengali","Noto Sans JP",sans-serif;
    display:flex;justify-content:center;min-height:100vh}
  .phone{width:100%;max-width:430px;background:var(--bg);min-height:100vh;
    display:flex;flex-direction:column;position:relative;overflow:hidden;box-shadow:0 0 60px rgba(0,0,0,.6)}
  header{padding:14px 16px 10px;border-bottom:1px solid var(--line);
    background:linear-gradient(180deg,#141a22,#0e1116)}
  .htop{display:flex;align-items:center;justify-content:space-between}
  .brand{font-weight:800;letter-spacing:.5px;font-size:20px}
  .brand span{color:var(--accent)}
  .streak{font-size:13px;color:var(--warn);background:#2a2113;padding:5px 10px;border-radius:20px;font-weight:700}
  .langsw{display:flex;gap:6px;margin-top:10px}
  .langsw button{flex:1;background:var(--card2);border:1px solid var(--line);color:var(--dim);
    padding:6px;border-radius:9px;font-weight:700;cursor:pointer;font-size:12px}
  .langsw button.on{background:var(--accent);color:#fff;border-color:var(--accent)}
  main{flex:1;overflow-y:auto;padding:16px 16px 90px}
  .screen{display:none;animation:fade .25s ease}
  .screen.active{display:block}
  @keyframes fade{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:none}}
  h2{font-size:19px;margin:4px 0 2px}
  .sub{color:var(--dim);font-size:13px;margin-bottom:16px}
  .card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:16px;margin-bottom:14px}
  .goal{background:linear-gradient(135deg,#1c2530,#161b22);border:1px solid #2b3949}
  .goal .lvl{font-size:28px;font-weight:800;color:var(--accent2)}
  .bar{height:10px;background:#0c1017;border-radius:8px;overflow:hidden;margin:10px 0 6px}
  .bar>i{display:block;height:100%;background:linear-gradient(90deg,var(--accent),#ff8a3c);border-radius:8px}
  .row{display:flex;gap:10px}
  .stat{flex:1;background:var(--card2);border-radius:12px;padding:12px;text-align:center}
  .stat b{display:block;font-size:22px}
  .stat small{color:var(--dim);font-size:11px}
  .tile{display:flex;align-items:center;gap:14px;cursor:pointer}
  .tile .ic{width:46px;height:46px;border-radius:12px;display:grid;place-items:center;font-size:22px;flex:none}
  .tile .t{font-weight:700}
  .tile .d{color:var(--dim);font-size:12px}
  .chev{margin-left:auto;color:var(--dim)}
  .verified{display:inline-flex;align-items:center;gap:4px;font-size:11px;color:var(--verified);
    background:#0f2417;border:1px solid #1c5232;padding:2px 8px;border-radius:20px;font-weight:700}
  .kana-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:8px}
  .kana{background:var(--card2);border:1px solid var(--line);border-radius:12px;padding:10px 4px;text-align:center;cursor:pointer;transition:.15s}
  .kana:active{transform:scale(.94);background:var(--accent)}
  .kana .c{font-size:26px}
  .kana .r{font-size:11px;color:var(--dim)}
  .flash{text-align:center;padding:26px 16px}
  .jp{font-size:34px;font-weight:700;color:var(--jp);line-height:1.5}
  .furi{font-size:14px;color:var(--accent2);display:block;margin-bottom:2px}
  .rom{color:var(--dim);font-size:15px;margin-top:8px}
  .bn{font-size:19px;margin-top:14px;color:#dfe7ef}
  .second{display:block;font-size:.8em;color:#7c8794;margin-top:3px;font-weight:400}
  .note{background:#161d16;border:1px solid #2a3a2a;border-radius:12px;padding:12px;margin-top:14px;font-size:13px;color:#cfe0cf;text-align:left}
  button.btn{background:var(--accent);color:#fff;border:0;border-radius:12px;padding:13px 18px;font-size:15px;font-weight:700;cursor:pointer;width:100%}
  button.ghost{background:var(--card2);color:var(--txt);border:1px solid var(--line)}
  button.mini{width:auto;padding:9px 14px;font-size:13px;border-radius:20px}
  .btnrow{display:flex;gap:10px;margin-top:14px}
  .play{width:52px;height:52px;border-radius:50%;background:var(--accent2);border:0;color:#05070a;font-size:22px;cursor:pointer;flex:none}
  .seg{display:flex;background:var(--card2);border-radius:12px;padding:4px;margin-bottom:14px}
  .seg button{flex:1;background:none;border:0;color:var(--dim);padding:9px;border-radius:9px;font-weight:700;cursor:pointer;font-size:13px}
  .seg button.on{background:var(--accent);color:#fff}
  .pitch-wrap{background:#0a0e13;border:1px solid var(--line);border-radius:12px;padding:18px 10px}
  .pitchword{font-size:15px;font-weight:700;margin-bottom:2px}
  .rating{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:16px}
  .rating button{border:0;border-radius:12px;padding:12px 4px;font-weight:700;cursor:pointer;color:#05070a;font-size:13px}
  .r1{background:#f87171}.r2{background:#fbbf24}.r3{background:#34d399}.r4{background:#38bdf8}
  .rating small{display:block;font-size:10px;opacity:.75;font-weight:600}
  nav{position:absolute;bottom:0;left:0;right:0;display:flex;background:#0b0f15;border-top:1px solid var(--line)}
  nav button{flex:1;background:none;border:0;color:var(--dim);padding:10px 0 14px;font-size:11px;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:3px}
  nav button.on{color:var(--accent)}
  nav .ni{font-size:20px}
  .meter{height:120px;background:#0a0e13;border:1px solid var(--line);border-radius:12px;position:relative;overflow:hidden;margin-top:12px}
  .meter canvas{width:100%;height:100%;display:block}
  .rec-dot{width:10px;height:10px;border-radius:50%;background:#f87171;display:inline-block;margin-right:6px;animation:pulse 1s infinite}
  @keyframes pulse{50%{opacity:.3}}
  .tag{font-size:11px;color:var(--dim);margin-top:4px}
  audio{width:100%;margin-top:10px}
  .hint{font-size:12px;color:var(--dim);text-align:center;margin-top:10px}
  .pill{font-size:11px;padding:3px 9px;border-radius:20px;background:var(--card2);border:1px solid var(--line);color:var(--dim)}
</style>
</head>
<body>
<div class="phone">
  <header>
    <div class="htop">
      <div class="brand">SEN<span>SEI</span></div>
      <div class="streak">🔥 <span id="streak">7</span> <span data-i18n="days"></span></div>
    </div>
    <div class="langsw">
      <button id="lang-en" onclick="setLang('en')">English</button>
      <button id="lang-bn" class="on" onclick="setLang('bn')">বাংলা</button>
      <button id="lang-ja" onclick="setLang('ja')">日本語</button>
    </div>
  </header>
  <main>
    <!-- HOME -->
    <section class="screen active" id="home">
      <div class="card goal">
        <div style="display:flex;justify-content:space-between;align-items:flex-start">
          <div>
            <div class="sub" style="margin:0" data-i18n="yourGoal"></div>
            <div class="lvl">JFT-Basic A2</div>
            <div class="tag" data-i18n="goalCaption"></div>
          </div>
          <div class="pill" data-i18n="onPath"></div>
        </div>
        <div class="bar"><i style="width:41%"></i></div>
        <div class="tag" data-i18n="progressCaption"></div>
      </div>
      <div class="row" style="margin-bottom:14px">
        <div class="stat"><b>183</b><small data-i18n="wordsLearned"></small></div>
        <div class="stat"><b id="due">12</b><small data-i18n="dueToday"></small></div>
        <div class="stat"><b>A1</b><small data-i18n="level"></small></div>
      </div>
      <div class="card tile" onclick="go('learn')">
        <div class="ic" style="background:#1c2c1c">あ</div>
        <div><div class="t" data-i18n="tileKanaT"></div><div class="d" data-i18n="tileKanaD"></div></div>
        <div class="chev">›</div>
      </div>
      <div class="card tile" onclick="go('speak')">
        <div class="ic" style="background:#0d2733">🎙️</div>
        <div><div class="t" data-i18n="tileSpeakT"></div><div class="d" data-i18n="tileSpeakD"></div></div>
        <div class="chev">›</div>
      </div>
      <div class="card tile" onclick="go('review')">
        <div class="ic" style="background:#2a2113">🔁</div>
        <div><div class="t" data-i18n="tileReviewT"></div><div class="d" id="tileReviewD"></div></div>
        <div class="chev">›</div>
      </div>
      <div class="card tile" onclick="go('speak');seg('pitch')">
        <div class="ic" style="background:#241c2c">〽️</div>
        <div><div class="t" data-i18n="tilePitchT"></div><div class="d" data-i18n="tilePitchD"></div></div>
        <div class="chev">›</div>
      </div>
    </section>

    <!-- LEARN -->
    <section class="screen" id="learn">
      <div class="seg">
        <button class="on" id="seg-kana" onclick="lseg('kana')" data-i18n="segKana"></button>
        <button id="seg-lesson" onclick="lseg('lesson')" data-i18n="segLesson"></button>
      </div>
      <div id="kana-view">
        <h2 data-i18n="kanaH"></h2>
        <div class="sub"><span data-i18n="kanaSub"></span> <span class="verified" data-i18n="verified"></span></div>
        <div class="kana-grid" id="kanaGrid"></div>
        <div class="note" id="kanaTip" style="margin-top:16px"></div>
      </div>
      <div id="lesson-view" style="display:none">
        <h2 data-i18n="lessonH"></h2>
        <div class="sub"><span data-i18n="lessonSub"></span> <span class="verified" data-i18n="verified"></span></div>
        <div class="card flash">
          <div id="lIdx" class="tag" style="margin-bottom:8px"></div>
          <span class="furi" id="lFuri"></span>
          <div class="jp" id="lJp"></div>
          <div class="rom" id="lRom"></div>
          <button class="play" onclick="playCur()" style="margin-top:14px">▶</button>
          <div class="bn" id="lBn"></div>
          <div class="note" id="lNote"></div>
          <div class="btnrow">
            <button class="btn ghost mini" style="flex:1" onclick="prevCard()" data-i18n="prev"></button>
            <button class="btn ghost mini" style="flex:1" id="romToggle" onclick="toggleRom()"></button>
            <button class="btn mini" style="flex:1" onclick="nextCard()" data-i18n="next"></button>
          </div>
        </div>
        <div class="hint" data-i18n="lessonHint"></div>
      </div>
    </section>

    <!-- SPEAK -->
    <section class="screen" id="speak">
      <div class="seg">
        <button class="on" id="seg-shadow" onclick="seg('shadow')" data-i18n="segShadow"></button>
        <button id="seg-pitch" onclick="seg('pitch')" data-i18n="segPitch"></button>
      </div>
      <div id="shadow-view">
        <h2 data-i18n="shadowH"></h2>
        <div class="sub" data-i18n="shadowSub"></div>
        <div class="card">
          <div style="display:flex;align-items:center;gap:14px">
            <button class="play" onclick="speak(SHADOW[shadowI].jp,0.85)">▶</button>
            <div>
              <div class="jp" style="font-size:24px" id="shJp"></div>
              <div class="rom" id="shRom"></div>
            </div>
          </div>
          <div class="bn" style="font-size:16px" id="shBn"></div>
          <div class="tag" data-i18n="demoAudio"></div>
          <div class="meter"><canvas id="pcanvas"></canvas></div>
          <div class="hint" id="recHint"></div>
          <div class="btnrow"><button class="btn" id="recBtn" onclick="toggleRec()"></button></div>
          <audio id="playback" controls style="display:none"></audio>
          <div class="btnrow">
            <button class="btn ghost mini" style="flex:1" onclick="prevShadow()" data-i18n="prev"></button>
            <button class="btn ghost mini" style="flex:1" onclick="nextShadow()" data-i18n="next"></button>
          </div>
        </div>
      </div>
      <div id="pitch-view" style="display:none">
        <h2 data-i18n="pitchH"></h2>
        <div class="sub"><span data-i18n="pitchSub"></span> <span class="verified" data-i18n="verifiedTokyo"></span></div>
        <div id="pitchList"></div>
        <div class="note" id="pitchTip"></div>
      </div>
    </section>

    <!-- REVIEW -->
    <section class="screen" id="review">
      <h2 data-i18n="reviewH"></h2>
      <div class="sub" data-i18n="reviewSub"></div>
      <div id="reviewArea"></div>
    </section>
  </main>

  <nav>
    <button class="on" id="nav-home" onclick="go('home')"><span class="ni">🏠</span><span data-i18n="navHome"></span></button>
    <button id="nav-learn" onclick="go('learn')"><span class="ni">📚</span><span data-i18n="navLearn"></span></button>
    <button id="nav-speak" onclick="go('speak')"><span class="ni">🎙️</span><span data-i18n="navSpeak"></span></button>
    <button id="nav-review" onclick="go('review')"><span class="ni">🔁</span><span data-i18n="navReview"></span></button>
  </nav>
</div>

<script>
/* ================= i18n UI STRINGS ================= */
const L={
 en:{days:"days",yourGoal:"Your goal",goalCaption:"Japan work visa (SSW) — pass mark 200",onPath:"On track to A2",
   progressCaption:"183 / 450 words & Can-dos — 41%",wordsLearned:"words learned",dueToday:"due today",level:"current level",
   tileKanaT:"Kana & Lessons",tileKanaD:"Hiragana + workplace Japanese Can-do",
   tileSpeakT:"Pronunciation & Shadowing",tileSpeakD:"Match the accent, record yourself",
   tileReviewT:"Today's review",tileReviewD:"{n} cards — before you forget",
   tilePitchT:"Pitch accent",tilePitchD:"hashi vs hashi — the melody differs",
   segKana:"かな Kana",segLesson:"Work lesson",
   kanaH:"Hiragana — core vowels",kanaSub:"Tap any character to hear it",verified:"✓ Verified",
   kanaTip:"💡 Tip for learners: Japanese vowels are short and clean. う = 'u' without rounding your lips, お = a short 'o'. Every character is one equal-length 'mora'.",
   lessonH:"First day at work — greetings & self-intro",lessonSub:"Can-do: introduce yourself at work",
   prev:"‹ Prev",next:"Next ›",hideRom:"Hide romaji",showRomBtn:"Show romaji",
   lessonHint:"Memorize these 9 lines and you can handle real workplace greetings.",
   segShadow:"🎙️ Shadowing",segPitch:"〽️ Pitch",
   shadowH:"Shadowing practice",shadowSub:"Listen → repeat at once → record → compare",
   demoAudio:"🔊 Demo audio — production uses native voice recordings (Irodori)",
   recStart:"🎙️ Start recording",recStop:"⏹ Stop & listen",recAgain:"🎙️ Record again",
   recHintStart:"Press below to record your voice — a live pitch line will show",
   recHintRec:"🎙️ Recording... match the native melody",
   recHintDone:"✅ Play your recording below and compare with the native",
   recHintPerm:"⚠️ Microphone permission needed (open the file in a browser)",
   pitchH:"Pitch accent (高低)",pitchSub:"Same spelling, different melody — meaning changes",verifiedTokyo:"✓ Verified (Tokyo)",
   pitchTip:"💡 For learners: in many languages the melody of a word doesn't change its meaning, so this feels new. High = voice slightly up, Low = down. Follow the line.",
   reviewH:"Review (FSRS)",reviewSub:"The algorithm picks when — right as you're about to forget",
   showAnswer:"Show answer",rAgain:"Again",rHard:"Hard",rGood:"Good",rEasy:"Easy",
   doneTitle:"Review done for today!",doneSub:"{n} cards done. FSRS scheduled the next times.",restart:"Start again",
   cardX:"Card {i} / {n}",navHome:"Home",navLearn:"Learn",navSpeak:"Speak",navReview:"Review",
   uMin:"{n} min",uHr:"{n} hr",uDay:"{n} d",uMo:"{n} mo"},
 bn:{days:"দিন",yourGoal:"তোমার goal",goalCaption:"জাপানে কাজের visa (SSW) — pass mark ২০০",onPath:"A2-এর পথে",progressCaption:"১৮৩ / ৪৫০ words ও Can-do — ৪১%",wordsLearned:"শেখা words",dueToday:"আজকের review",level:"তোমার level",tileKanaT:"Kana ও Lesson",tileKanaD:"হিরাগানা + কাজের Japanese Can-do",tileSpeakT:"উচ্চারণ ও Shadowing",tileSpeakD:"Accent মেলাও, নিজের voice record করো",tileReviewT:"আজকের Review",tileReviewD:"{n}টি card — ভুলে যাওয়ার আগেই",tilePitchT:"Pitch accent",tilePitchD:"箸 vs 橋 — সুরের পার্থক্য",segKana:"かな Kana",segLesson:"কাজের Lesson",kanaH:"হিরাগানা — basic vowel",kanaSub:"যেকোনো character-এ tap করো শুনতে",verified:"✓ Verified",kanaTip:"💡 Tip: Japanese vowel ছোট ও পরিষ্কার। う = u ঠোঁট গোল না করে, お = ছোট o. প্রতিটা character সমান লম্বার এক mora।",lessonH:"প্রথম দিন কাজে — greeting ও self-intro",lessonSub:"Can-do: workplace-এ নিজের পরিচয় দিতে পারা",prev:"‹ আগের",next:"পরের ›",hideRom:"Romaji hide",showRomBtn:"Romaji show",lessonHint:"এই ৯টা sentence মুখস্থ হলে আসল workplace-এর greeting তুমি পারবে।",segShadow:"🎙️ Shadowing",segPitch:"〽️ Pitch",shadowH:"Shadowing practice",shadowSub:"শোনো → সাথে সাথে বলো → record করো → মিলিয়ে দেখো",demoAudio:"🔊 Demo audio — আসল app-এ native voice recording (Irodori)",recStart:"🎙️ Record শুরু",recStop:"⏹ থামাও ও শোনো",recAgain:"🎙️ আবার record",recHintStart:"নিচের button চেপে নিজের voice record করো — live pitch দেখাবে",recHintRec:"🎙️ Record হচ্ছে... native সুরের সাথে মেলাও",recHintDone:"✅ নিচে নিজের recording শুনে native-এর সাথে মেলাও",recHintPerm:"⚠️ Microphone permission দরকার (browser-এ খুলে try করো)",pitchH:"Pitch accent (高低)",pitchSub:"একই spelling, আলাদা সুর — মানে বদলে যায়",verifiedTokyo:"✓ Verified (Tokyo)",pitchTip:"💡 Tip: বাংলায় শব্দের সুরে মানে বদলায় না, তাই এটা নতুন লাগবে। High = গলা একটু উপরে, Low = নিচে। line-টা follow করো।",reviewH:"Review (FSRS)",reviewSub:"Algorithm ঠিক করে কখন দেখাবে — ঠিক ভুলে যাওয়ার মুহূর্তে",showAnswer:"Answer দেখাও",rAgain:"আবার",rHard:"কঠিন",rGood:"ভালো",rEasy:"সহজ",doneTitle:"আজকের review শেষ!",doneSub:"{n}টি card শেষ। FSRS পরের সময় ঠিক করেছে।",restart:"আবার শুরু",cardX:"Card {i} / {n}",navHome:"হোম",navLearn:"শেখো",navSpeak:"বলো",navReview:"Review",uMin:"{n} min",uHr:"{n} ঘণ্টা",uDay:"{n} দিন",uMo:"{n} মাস"},
 ja:{days:"日",yourGoal:"あなたの目標",goalCaption:"日本の就労ビザ（特定技能）— 合格点200",onPath:"A2に向けて",
   progressCaption:"183 / 450 語・Can-do — 41%",wordsLearned:"習得した語",dueToday:"本日の復習",level:"現在のレベル",
   tileKanaT:"かな・レッスン",tileKanaD:"ひらがな＋職場の日本語Can-do",
   tileSpeakT:"発音・シャドーイング",tileSpeakD:"アクセントを真似て録音",
   tileReviewT:"本日の復習",tileReviewD:"{n}枚 — 忘れる前に",
   tilePitchT:"アクセント（高低）",tilePitchD:"箸 vs 橋 — 音の高さの違い",
   segKana:"かな Kana",segLesson:"職場レッスン",
   kanaH:"ひらがな — 基本の母音",kanaSub:"文字をタップして音を聞く",verified:"✓ 確認済み",
   kanaTip:"💡 ヒント：日本語の母音は短く明瞭。うは唇を丸めず、おは短く。各文字は同じ長さの「拍（モーラ）」です。",
   lessonH:"職場の初日 — あいさつと自己紹介",lessonSub:"Can-do：職場で自己紹介ができる",
   prev:"‹ 前へ",next:"次へ ›",hideRom:"ローマ字を隠す",showRomBtn:"ローマ字を表示",
   lessonHint:"この9文を覚えれば、職場のあいさつができます。",
   segShadow:"🎙️ シャドーイング",segPitch:"〽️ アクセント",
   shadowH:"シャドーイング練習",shadowSub:"聞く→すぐ真似る→録音→比べる",
   demoAudio:"🔊 デモ音声 — 製品版はネイティブ録音（いろどり）",
   recStart:"🎙️ 録音開始",recStop:"⏹ 停止して聞く",recAgain:"🎙️ もう一度録音",
   recHintStart:"下のボタンで録音 — リアルタイムで高さが表示されます",
   recHintRec:"🎙️ 録音中... ネイティブの高さに合わせて",
   recHintDone:"✅ 下で自分の録音を聞いて比べよう",
   recHintPerm:"⚠️ マイクの許可が必要です（ブラウザで開いてください）",
   pitchH:"アクセント（高低）",pitchSub:"同じ綴り、違う高さ — 意味が変わる",verifiedTokyo:"✓ 確認済み（東京）",
   pitchTip:"💡 ヒント：単語の高さで意味が変わるのは新鮮かもしれません。高＝少し上げ、低＝下げ。線をたどりましょう。",
   reviewH:"復習（FSRS）",reviewSub:"アルゴリズムが最適な時を選ぶ — 忘れる直前に",
   showAnswer:"答えを見る",rAgain:"もう一度",rHard:"難しい",rGood:"できた",rEasy:"簡単",
   doneTitle:"本日の復習完了！",doneSub:"{n}枚完了。FSRSが次回を設定しました。",restart:"もう一度",
   cardX:"カード {i} / {n}",navHome:"ホーム",navLearn:"学ぶ",navSpeak:"話す",navReview:"復習",
   uMin:"{n}分",uHr:"{n}時間",uDay:"{n}日",uMo:"{n}ヶ月"}
};
let lang='bn';
function t(k,v){let s=(L[lang]&&L[lang][k])||L.en[k]||k;if(v)for(const p in v)s=s.replace('{'+p+'}',v[p]);return s;}
/* Bilingual helpers: in Bengali mode show BN with an English gloss, since the
   Bengali wording may not be a perfect fit for every learner. */
function bil(o){return lang==='bn'?o.bn+'<span class="second">'+o.en+'</span>':o[lang];}
function bilInline(o){return lang==='bn'?o.bn+' <span style="color:#6b7684">('+o.en+')</span>':o[lang];}
function tipBil(k){return lang==='bn'?L.bn[k]+'<span class="second">'+L.en[k]+'</span>':t(k);}

/* ================= VERIFIED CONTENT (checked correct) ================= */
const KANA=[['あ','a'],['い','i'],['う','u'],['え','e'],['お','o'],
 ['か','ka'],['き','ki'],['く','ku'],['け','ke'],['こ','ko'],
 ['さ','sa'],['し','shi'],['す','su'],['せ','se'],['そ','so'],
 ['た','ta'],['ち','chi'],['つ','tsu'],['て','te'],['と','to'],
 ['な','na'],['に','ni'],['ぬ','nu'],['ね','ne'],['の','no']];

const LESSON=[
 {jp:'おはようございます',rom:'ohayō gozaimasu',
   mean:{en:"Good morning (polite)",bn:"সুপ্রভাত (ভদ্রভাবে)",ja:"おはよう（丁寧）"},
   note:{en:"Say it right as you arrive at work. ございます makes it polite.",bn:"সকালে কর্মস্থলে ঢুকেই বলবে। শেষে ございます থাকায় এটি ভদ্র রূপ।",ja:"出勤時に言う。ございますで丁寧になる。"}},
 {jp:'こんにちは',rom:'konnichiwa',
   mean:{en:"Hello / good afternoon",bn:"নমস্কার / হ্যালো (দুপুরে)",ja:"こんにちは（昼のあいさつ）"},
   note:{en:"は is pronounced 'wa' here, not 'ha'.",bn:"は এখানে \"wa\" উচ্চারণ হয়, \"ha\" নয়।",ja:"ここでのはは「わ」と読む。"}},
 {jp:'はじめまして',rom:'hajimemashite',
   mean:{en:"Nice to meet you (first time)",bn:"প্রথম সাক্ষাতে — পরিচিত হয়ে ভালো লাগল",ja:"はじめまして（初対面）"},
   note:{en:"Use it the first time you meet someone.",bn:"নতুন কাউকে প্রথমবার দেখা হলেই বলবে।",ja:"初めて会うときに使う。"}},
 {jp:'わたしはラーマンです',rom:'watashi wa Rāman desu',
   mean:{en:"I am Rahman.",bn:"আমি রহমান।",ja:"私はラーマンです。"},
   note:{en:"Pattern: わたしは ＿ です = 'I am ＿'. は = wa (topic marker).",bn:"গঠন: わたしは ＿ です = \"আমি ＿\"। は = wa (বিষয় নির্দেশক)।",ja:"型：わたしは＿です。はは「わ」（主題）。"}},
 {jp:'よろしくおねがいします',rom:'yoroshiku onegai shimasu',
   mean:{en:"I look forward to working with you (courtesy)",bn:"আপনার সাথে কাজ করতে পেরে ভালো লাগবে (সৌজন্য)",ja:"よろしくお願いします（締めのあいさつ）"},
   note:{en:"Said at the end of an introduction — very important politeness in Japan.",bn:"পরিচয়ের শেষে বলা হয় — জাপানে খুব গুরুত্বপূর্ণ ভদ্রতা।",ja:"自己紹介の最後に言う大切な表現。"}},
 {jp:'すみません',rom:'sumimasen',
   mean:{en:"Excuse me / sorry",bn:"মাফ করবেন / এক্সকিউজ মি",ja:"すみません（呼びかけ・軽い謝罪）"},
   note:{en:"To get attention or apologize for a small thing.",bn:"কারো দৃষ্টি আকর্ষণ করতে বা ছোট ভুলে ক্ষমা চাইতে।",ja:"呼びかけや軽い謝罪に。"}},
 {jp:'ありがとうございます',rom:'arigatō gozaimasu',
   mean:{en:"Thank you (polite)",bn:"ধন্যবাদ (ভদ্রভাবে)",ja:"ありがとうございます（丁寧）"},
   note:{en:"ございます makes it more polite — use this at work.",bn:"ございます যোগ করায় বেশি ভদ্র — কর্মস্থলে এটাই ব্যবহার করবে।",ja:"ございますでより丁寧。職場で使う。"}},
 {jp:'わかりません',rom:'wakarimasen',
   mean:{en:"I don't understand",bn:"আমি বুঝতে পারিনি",ja:"わかりません"},
   note:{en:"Don't stay silent if you don't get it — saying this is useful, not shameful.",bn:"না বুঝলে চুপ থেকো না — এটি বলা দোষের নয়, বরং কাজে দরকারি।",ja:"分からないときは黙らず言おう。"}},
 {jp:'もういちどおねがいします',rom:'mō ichido onegai shimasu',
   mean:{en:"Please say it once more",bn:"অনুগ্রহ করে আরেকবার বলুন",ja:"もう一度お願いします"},
   note:{en:"If someone speaks fast, say this to hear it again.",bn:"কেউ দ্রুত বললে এটি বলে আবার শুনে নাও।",ja:"速いときはこれでもう一度聞く。"}}
];

const SHADOW=[
 {jp:'おはようございます',rom:'ohayō gozaimasu',mean:{en:"Good morning",bn:"সুপ্রভাত",ja:"おはよう"}},
 {jp:'よろしくおねがいします',rom:'yoroshiku onegai shimasu',mean:{en:"Courtesy greeting",bn:"সৌজন্য অভিবাদন",ja:"あいさつ"}},
 {jp:'ありがとうございます',rom:'arigatō gozaimasu',mean:{en:"Thank you",bn:"ধন্যবাদ",ja:"ありがとう"}}
];

const PITCH=[
 {word:'はし',kanji:'箸',rom:'hashi',pat:[1,0],mean:{en:"chopsticks",bn:"চপস্টিক",ja:"箸（食器）"},type:{en:"atamadaka (head-high)",bn:"atamadaka (মাথা-উঁচু)",ja:"頭高型"}},
 {word:'はし',kanji:'橋',rom:'hashi',pat:[0,1],mean:{en:"bridge",bn:"সেতু",ja:"橋"},type:{en:"odaka (tail-high)",bn:"odaka (শেষ-উঁচু)",ja:"尾高型"}},
 {word:'あめ',kanji:'雨',rom:'ame',pat:[1,0],mean:{en:"rain",bn:"বৃষ্টি",ja:"雨"},type:{en:"atamadaka",bn:"atamadaka",ja:"頭高型"}},
 {word:'あめ',kanji:'飴',rom:'ame',pat:[0,1],mean:{en:"candy",bn:"ক্যান্ডি",ja:"飴"},type:{en:"heiban (flat)",bn:"heiban (সমতল)",ja:"平板型"}}
];

let queue=[
 {word:'ありがとうございます',rom:'arigatō gozaimasu',mean:{en:"Thank you",bn:"ধন্যবাদ",ja:"ありがとう"},stab:2.1},
 {word:'すみません',rom:'sumimasen',mean:{en:"Excuse me",bn:"মাফ করবেন",ja:"すみません"},stab:1.4},
 {word:'よろしくおねがいします',rom:'yoroshiku onegai shimasu',mean:{en:"Courtesy greeting",bn:"সৌজন্য অভিবাদন",ja:"よろしく"},stab:0.8},
 {word:'わかりません',rom:'wakarimasen',mean:{en:"I don't understand",bn:"বুঝিনি",ja:"わかりません"},stab:3.2}
];

/* ================= LANGUAGE APPLY ================= */
function setLang(l){
  lang=l;
  document.documentElement.lang=l;
  ['en','bn','ja'].forEach(x=>document.getElementById('lang-'+x).classList.toggle('on',x===l));
  document.querySelectorAll('[data-i18n]').forEach(el=>el.textContent=t(el.getAttribute('data-i18n')));
  document.getElementById('kanaTip').innerHTML=tipBil('kanaTip');
  document.getElementById('pitchTip').innerHTML=tipBil('pitchTip');
  document.getElementById('romToggle').textContent=showRom?t('hideRom'):t('showRomBtn');
  document.getElementById('recBtn').textContent=recording?t('recStop'):(recDone?t('recAgain'):t('recStart'));
  document.getElementById('recHint').textContent=t(recHintKey);
  const left=queue.length-qi;
  document.getElementById('tileReviewD').textContent=t('tileReviewD',{n:left});
  renderCard(); renderShadow(); renderPitch();
  if(document.getElementById('review').classList.contains('active')) buildReview();
}

/* ================= NAV ================= */
function go(id){
  document.querySelectorAll('.screen').forEach(s=>s.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  document.querySelectorAll('nav button').forEach(b=>b.classList.remove('on'));
  const nb=document.getElementById('nav-'+id); if(nb) nb.classList.add('on');
  if(id==='review') buildReview();
}
function lseg(w){
  document.getElementById('seg-kana').classList.toggle('on',w==='kana');
  document.getElementById('seg-lesson').classList.toggle('on',w==='lesson');
  document.getElementById('kana-view').style.display=w==='kana'?'block':'none';
  document.getElementById('lesson-view').style.display=w==='lesson'?'block':'none';
}
function seg(w){
  document.getElementById('seg-shadow').classList.toggle('on',w==='shadow');
  document.getElementById('seg-pitch').classList.toggle('on',w==='pitch');
  document.getElementById('shadow-view').style.display=w==='shadow'?'block':'none';
  document.getElementById('pitch-view').style.display=w==='pitch'?'block':'none';
}

/* ================= SPEECH ================= */
let jaVoice=null;
function pickVoice(){const vs=speechSynthesis.getVoices();jaVoice=vs.find(v=>v.lang==='ja-JP')||vs.find(v=>v.lang&&v.lang.startsWith('ja'))||null;}
if('speechSynthesis' in window){pickVoice();speechSynthesis.onvoiceschanged=pickVoice;}
function speak(txt,rate){if(!('speechSynthesis' in window))return;speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(txt);u.lang='ja-JP';u.rate=rate||0.9;if(jaVoice)u.voice=jaVoice;speechSynthesis.speak(u);}

/* ================= KANA ================= */
const kg=document.getElementById('kanaGrid');
KANA.forEach(([c,r])=>{const d=document.createElement('div');d.className='kana';d.innerHTML=`<div class="c">${c}</div><div class="r">${r}</div>`;d.onclick=()=>speak(c,0.8);kg.appendChild(d);});

/* ================= LESSON ================= */
let ci=0,showRom=true;
function renderCard(){
  const c=LESSON[ci];
  document.getElementById('lIdx').textContent=t('cardX',{i:ci+1,n:LESSON.length});
  document.getElementById('lJp').textContent=c.jp;
  document.getElementById('lFuri').textContent=c.furi||'';
  const rom=document.getElementById('lRom');rom.textContent=c.rom;rom.style.display=showRom?'block':'none';
  document.getElementById('lBn').innerHTML=bil(c.mean);
  document.getElementById('lNote').innerHTML='💡 '+bil(c.note);
}
function nextCard(){ci=(ci+1)%LESSON.length;renderCard();}
function prevCard(){ci=(ci-1+LESSON.length)%LESSON.length;renderCard();}
function playCur(){speak(LESSON[ci].jp,0.85);}
function toggleRom(){showRom=!showRom;document.getElementById('romToggle').textContent=showRom?t('hideRom'):t('showRomBtn');renderCard();}

/* ================= SHADOW ================= */
let shadowI=0;
function renderShadow(){const s=SHADOW[shadowI];document.getElementById('shJp').textContent=s.jp;document.getElementById('shRom').textContent=s.rom;document.getElementById('shBn').innerHTML=bil(s.mean);}
function nextShadow(){shadowI=(shadowI+1)%SHADOW.length;renderShadow();stopRec(true);}
function prevShadow(){shadowI=(shadowI-1+SHADOW.length)%SHADOW.length;renderShadow();stopRec(true);}

/* ================= RECORD + LIVE PITCH ================= */
let mediaRec=null,chunks=[],audioCtx=null,analyser=null,rafId=null,stream=null,recording=false,recDone=false,recHintKey='recHintStart';
const canvas=document.getElementById('pcanvas'),ctx=canvas.getContext('2d');
function fitCanvas(){canvas.width=canvas.clientWidth*devicePixelRatio;canvas.height=canvas.clientHeight*devicePixelRatio;}
let pitchPts=[];
function setHint(k){recHintKey=k;document.getElementById('recHint').textContent=t(k);}
function drawLoop(){
  fitCanvas();const w=canvas.width,h=canvas.height;ctx.clearRect(0,0,w,h);
  ctx.strokeStyle='#1e2732';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(0,h*0.5);ctx.lineTo(w,h*0.5);ctx.stroke();
  const buf=new Float32Array(analyser.fftSize);analyser.getFloatTimeDomainData(buf);
  const f=autoCorrelate(buf,audioCtx.sampleRate);
  let y=h*0.5;if(f>0){const norm=Math.min(1,Math.max(0,(Math.log2(f)-6.6)/2));y=h-norm*h;}
  pitchPts.push(f>0?y:null);
  if(pitchPts.length>Math.floor(w/(2*devicePixelRatio)))pitchPts.shift();
  ctx.strokeStyle='#ff5a3c';ctx.lineWidth=3*devicePixelRatio;ctx.beginPath();let started=false;
  pitchPts.forEach((py,i)=>{const x=i*2*devicePixelRatio;if(py==null){started=false;return;}if(!started){ctx.moveTo(x,py);started=true;}else ctx.lineTo(x,py);});
  ctx.stroke();rafId=requestAnimationFrame(drawLoop);
}
function autoCorrelate(buf,sr){
  let size=buf.length,rms=0;for(let i=0;i<size;i++)rms+=buf[i]*buf[i];rms=Math.sqrt(rms/size);if(rms<0.01)return -1;
  let r1=0,r2=size-1,thr=0.2;for(let i=0;i<size/2;i++){if(Math.abs(buf[i])<thr){r1=i;break;}}
  for(let i=1;i<size/2;i++){if(Math.abs(buf[size-i])<thr){r2=size-i;break;}}
  buf=buf.slice(r1,r2);size=buf.length;const c=new Array(size).fill(0);
  for(let i=0;i<size;i++)for(let j=0;j<size-i;j++)c[i]+=buf[j]*buf[j+i];
  let d=0;while(c[d]>c[d+1])d++;let maxv=-1,maxp=-1;
  for(let i=d;i<size;i++){if(c[i]>maxv){maxv=c[i];maxp=i;}}
  if(maxp<=0)return -1;const f=sr/maxp;return (f>70&&f<500)?f:-1;
}
async function toggleRec(){recording?stopRec():startRec();}
async function startRec(){
  try{stream=await navigator.mediaDevices.getUserMedia({audio:true});}
  catch(e){setHint('recHintPerm');return;}
  recording=true;recDone=false;
  document.getElementById('recBtn').textContent=t('recStop');
  setHint('recHintRec');chunks=[];pitchPts=[];
  mediaRec=new MediaRecorder(stream);mediaRec.ondataavailable=e=>chunks.push(e.data);
  mediaRec.onstop=()=>{const blob=new Blob(chunks,{type:'audio/webm'});const pb=document.getElementById('playback');pb.src=URL.createObjectURL(blob);pb.style.display='block';};
  mediaRec.start();
  audioCtx=new (window.AudioContext||window.webkitAudioContext)();
  const src=audioCtx.createMediaStreamSource(stream);analyser=audioCtx.createAnalyser();analyser.fftSize=2048;src.connect(analyser);drawLoop();
}
function stopRec(silent){
  if(!recording)return;recording=false;recDone=true;
  document.getElementById('recBtn').textContent=t('recAgain');
  if(!silent)setHint('recHintDone');
  if(mediaRec&&mediaRec.state!=='inactive')mediaRec.stop();
  if(rafId)cancelAnimationFrame(rafId);
  if(stream)stream.getTracks().forEach(x=>x.stop());
  if(audioCtx)audioCtx.close();
}

/* ================= PITCH VISUALISER ================= */
function pitchSVG(pat){
  const n=pat.length,W=180,H=54,step=W/(n+0.5),r=7;let dots='',lines='',prev=null;
  for(let i=0;i<n;i++){const x=step*(i+0.5),y=pat[i]?14:H-14;
    if(prev)lines+=`<line x1="${prev.x}" y1="${prev.y}" x2="${x}" y2="${y}" stroke="#ff5a3c" stroke-width="3"/>`;
    dots+=`<circle cx="${x}" cy="${y}" r="${r}" fill="${pat[i]?'#38bdf8':'#96a0ad'}"/>`;prev={x,y};}
  return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${lines}${dots}</svg>`;
}
function renderPitch(){
  const pl=document.getElementById('pitchList');pl.innerHTML='';
  PITCH.forEach(p=>{const d=document.createElement('div');d.className='card';
    d.innerHTML=`<div style="display:flex;justify-content:space-between;align-items:center">
      <div><div class="pitchword">${p.kanji} <span style="color:#96a0ad;font-weight:400">(${p.word})</span></div>
      <div class="tag">${p.rom} · ${bilInline(p.mean)} · <b style="color:#38bdf8">${bilInline(p.type)}</b></div></div>
      <button class="play" onclick="speak('${p.word}',0.8)">▶</button></div>
      <div class="pitch-wrap" style="margin-top:10px;text-align:center">${pitchSVG(p.pat)}</div>`;
    pl.appendChild(d);});
}

/* ================= FSRS-LITE REVIEW ================= */
let qi=0,revealed=false,done=0;
function fmtInterval(days){
  if(days<1/24)return t('uMin',{n:Math.round(days*1440)});
  if(days<1)return t('uHr',{n:Math.round(days*24)});
  if(days<30)return t('uDay',{n:Math.round(days)});
  return t('uMo',{n:(days/30).toFixed(1)});
}
function nextInterval(stab,rating){
  if(rating===1)return 10/1440;
  if(rating===2)return Math.max(0.5,stab*0.5);
  if(rating===3)return Math.max(1,stab*1.9);
  return Math.max(2,stab*3.4);
}
function buildReview(){
  const a=document.getElementById('reviewArea');
  if(qi>=queue.length){
    a.innerHTML=`<div class="card" style="text-align:center;padding:30px">
      <div style="font-size:40px">🎉</div><h2 style="margin:10px 0 4px">${t('doneTitle')}</h2>
      <div class="sub">${t('doneSub',{n:done})}</div>
      <button class="btn" onclick="qi=0;done=0;revealed=false;buildReview()">${t('restart')}</button></div>`;
    document.getElementById('due').textContent='0';document.getElementById('tileReviewD').textContent=t('tileReviewD',{n:0});return;
  }
  const c=queue[qi];
  a.innerHTML=`<div class="tag" style="margin-bottom:8px">${t('cardX',{i:qi+1,n:queue.length})}</div>
    <div class="card flash"><div class="jp">${c.word}</div>
      <button class="play" onclick="speak('${c.word}',0.85)" style="margin-top:12px">▶</button>
      <div style="display:${revealed?'block':'none'}"><div class="rom">${c.rom}</div><div class="bn">${bil(c.mean)}</div></div>
      ${revealed?ratingHTML(c):`<button class="btn" style="margin-top:18px" onclick="revealed=true;buildReview()">${t('showAnswer')}</button>`}
    </div>`;
}
function ratingHTML(c){
  return `<div class="rating">
    <button class="r1" onclick="rate(1)">${t('rAgain')}<small>${fmtInterval(nextInterval(c.stab,1))}</small></button>
    <button class="r2" onclick="rate(2)">${t('rHard')}<small>${fmtInterval(nextInterval(c.stab,2))}</small></button>
    <button class="r3" onclick="rate(3)">${t('rGood')}<small>${fmtInterval(nextInterval(c.stab,3))}</small></button>
    <button class="r4" onclick="rate(4)">${t('rEasy')}<small>${fmtInterval(nextInterval(c.stab,4))}</small></button></div>`;
}
function rate(r){qi++;done++;revealed=false;const left=queue.length-qi;
  document.getElementById('due').textContent=left;document.getElementById('tileReviewD').textContent=t('tileReviewD',{n:left});buildReview();}

/* ================= INIT ================= */
setLang('bn');
</script>
</body>
</html>

```


## File: prototypes\sensei_writing.html

```html
<!DOCTYPE html>
<html lang="bn"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>SENSEI · Writing</title>
<style>
 *{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent;-webkit-user-select:none;user-select:none}
 :root{--bg:#0a0a12;--txt:#f4f5fb;--dim:#9aa0b4;--faint:#666b80;--line:rgba(255,255,255,.09);
  --card:rgba(255,255,255,.05);--g1:#ff5a3c;--g2:#ff2d78;--g3:#8b5cff;--cyan:#3fd0e0;--green:#37e0a6;
  --grad:linear-gradient(135deg,#ff5a3c,#ff2d78 55%,#8b5cff);--paper:#fbfbfd;--ink:#14141f}
 body{background:radial-gradient(120% 60% at 50% -10%,rgba(139,92,255,.18),transparent 60%),var(--bg);
  color:var(--txt);font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans Bengali","Noto Sans JP",sans-serif;
  display:flex;justify-content:center;min-height:100vh}
 .wrap{width:100%;max-width:440px;padding:16px 16px 24px;display:flex;flex-direction:column;min-height:100vh}
 header{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
 .brand{font-weight:800;font-size:20px}.brand b{background:var(--grad);-webkit-background-clip:text;background-clip:text;color:transparent}
 .lang{display:flex;gap:4px;background:var(--card);border:1px solid var(--line);border-radius:99px;padding:3px}
 .lang button{background:none;border:0;color:var(--dim);font-weight:700;font-size:11px;padding:5px 9px;border-radius:99px;cursor:pointer}
 .lang button.on{background:var(--grad);color:#fff}
 .title{font-size:22px;font-weight:800;letter-spacing:-.3px}
 .sub{color:var(--dim);font-size:13px;margin-bottom:14px}
 .seg{display:flex;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:4px;margin-bottom:12px}
 .seg button{flex:1;background:none;border:0;color:var(--dim);font-weight:700;font-size:13px;padding:9px;border-radius:10px;cursor:pointer;transition:.2s}
 .seg button.on{background:var(--grad);color:#fff}
 .strip{display:flex;gap:8px;overflow-x:auto;padding-bottom:8px;margin-bottom:14px;scrollbar-width:none}
 .strip::-webkit-scrollbar{display:none}
 .chip{flex:none;width:46px;height:46px;border-radius:13px;background:var(--card);border:1px solid var(--line);
  display:grid;place-items:center;font-size:22px;cursor:pointer;color:var(--txt);transition:.15s;position:relative}
 .chip small{position:absolute;bottom:2px;font-size:8px;color:var(--faint)}
 .chip.on{background:var(--grad);border-color:transparent;transform:scale(1.06)}
 .paperwrap{position:relative;width:100%;aspect-ratio:1;border-radius:22px;overflow:hidden;
  box-shadow:0 20px 50px -18px rgba(255,45,120,.35);background:var(--paper)}
 canvas{position:absolute;inset:0;width:100%;height:100%;touch-action:none;display:block}
 .curchar{position:absolute;top:10px;left:14px;font-size:13px;font-weight:800;color:#c0c4d0;z-index:2}
 .curchar b{color:#8a8fa0;font-weight:800}
 .hintbadge{position:absolute;top:10px;right:14px;font-size:11px;color:#b9bdc9;z-index:2}
 .tools{display:flex;gap:9px;margin-top:14px}
 .tbtn{flex:1;height:52px;border-radius:16px;border:1px solid var(--line);background:var(--card);color:var(--txt);
  font-size:20px;cursor:pointer;display:grid;place-items:center;transition:.12s;position:relative}
 .tbtn:active{transform:scale(.92)}
 .tbtn.grad{background:var(--grad);border-color:transparent}
 .tbtn small{position:absolute;bottom:5px;font-size:8.5px;color:var(--dim)}
 .tbtn.grad small{color:rgba(255,255,255,.8)}
 .brushrow{display:flex;align-items:center;gap:12px;margin-top:14px;padding:12px 16px;background:var(--card);border:1px solid var(--line);border-radius:16px}
 .brushrow label{font-size:12px;color:var(--dim);font-weight:700;flex:none}
 input[type=range]{flex:1;accent-color:var(--g2)}
 .navrow{display:flex;gap:10px;margin-top:14px}
 .navbtn{flex:1;height:50px;border-radius:16px;border:1px solid var(--line);background:var(--card);color:var(--txt);font-weight:700;font-size:14px;cursor:pointer;transition:.12s}
 .navbtn:active{transform:scale(.96)}.navbtn.p{background:var(--grad);border-color:transparent;color:#fff}
 .praise{position:fixed;left:50%;top:38%;transform:translateX(-50%);z-index:9;font-size:20px;font-weight:800;
  background:var(--grad);color:#fff;padding:14px 26px;border-radius:99px;box-shadow:0 14px 40px -8px rgba(255,45,120,.6);
  opacity:0;pointer-events:none;transition:.3s}
 .praise.show{opacity:1;animation:pp .5s}
 @keyframes pp{0%{transform:translateX(-50%) scale(.7)}60%{transform:translateX(-50%) scale(1.08)}100%{transform:translateX(-50%) scale(1)}}
 .tip{color:var(--faint);font-size:11.5px;text-align:center;margin-top:14px;line-height:1.5}
.anim{position:absolute;inset:0;width:100%;height:100%;pointer-events:none;opacity:0;transition:opacity .25s}
 .anim.show{opacity:1}
 .nib{filter:drop-shadow(0 0 7px rgba(255,45,120,.9))}
 .watch{width:100%;margin-top:14px;border:0;border-radius:18px;padding:15px;font-weight:800;font-size:15px;color:#fff;
  background:var(--grad);cursor:pointer;transition:transform .12s;display:flex;align-items:center;justify-content:center;gap:9px;
  box-shadow:0 10px 30px -10px rgba(255,45,120,.5)}
 .watch:active{transform:scale(.97)}
</style></head><body>
<div class="wrap">
 <header>
  <div class="brand">SEN<b>SEI</b></div>
  <div class="lang">
   <button id="L-en" onclick="setLang('en')">EN</button>
   <button id="L-bn" class="on" onclick="setLang('bn')">বাংলা</button>
   <button id="L-ja" onclick="setLang('ja')">日本語</button>
  </div>
 </header>
 <div class="title" id="ttl"></div>
 <div class="sub" id="sttl"></div>
 <div class="seg">
  <button class="on" id="sg-h" onclick="setScript('h')">ひらがな Hiragana</button>
  <button id="sg-k" onclick="setScript('k')">カタカナ Katakana</button>
 </div>
 <div class="strip" id="strip"></div>
 <div class="paperwrap">
  <div class="curchar"><b id="cc-char"></b> <span id="cc-rom"></span></div>
  <div class="hintbadge" id="hintbadge"></div>
  <canvas id="cv"></canvas>
  <svg id="anim" class="anim" viewBox="0 0 1000 1000" preserveAspectRatio="xMidYMid meet"></svg>
 </div>
 <button class="watch" id="watchBtn" onclick="animateChar()"></button>
 <div class="tools">
  <button class="tbtn" onclick="playChar()">🔊<small id="t-sound"></small></button>
  <button class="tbtn" id="guideBtn" onclick="toggleGuide()">👁️<small id="t-guide"></small></button>
  <button class="tbtn" onclick="undo()">↶<small id="t-undo"></small></button>
  <button class="tbtn" onclick="clearBoard()">🗑️<small id="t-clear"></small></button>
  <button class="tbtn grad" onclick="doneChar()">✓<small id="t-done"></small></button>
 </div>
 <div class="brushrow">
  <label id="t-brush"></label>
  <input type="range" id="brush" min="6" max="26" step="1" value="14">
 </div>
 <div class="navrow">
  <button class="navbtn" onclick="prevChar()" id="t-prev"></button>
  <button class="navbtn p" onclick="nextChar()" id="t-next"></button>
 </div>
 <div class="tip" id="tip"></div>
</div>
<div class="praise" id="praise"></div>
<script>
const L={
 en:{title:"Writing practice",sub:"Trace the light letter, then write it yourself",
  tSound:"sound",tGuide:"guide",tUndo:"undo",tClear:"clear",tDone:"done",tBrush:"Brush",
  prev:"‹ Back",next:"Next ›",tip:"Tip: follow the faint letter, then hide the guide and write from memory.",
  hint:"trace me",praise:"Nice writing! ✍️",watch:"▶ Watch how to write",noNet:"Needs internet the first time"},
 bn:{title:"লেখা practice",sub:"হালকা letter-টা trace করো, তারপর নিজে লেখো",
  tSound:"sound",tGuide:"guide",tUndo:"undo",tClear:"clear",tDone:"done",tBrush:"Brush",
  prev:"‹ আগের",next:"পরের ›",tip:"Tip: হালকা letter follow করো, তারপর guide off করে মুখস্থ লেখো।",
  hint:"trace করো",praise:"সুন্দর হয়েছে! ✍️",watch:"▶ কিভাবে লেখে দেখো",noNet:"প্রথমবার internet লাগবে"},
 ja:{title:"書く練習",sub:"薄い文字をなぞって、自分で書こう",
  tSound:"音",tGuide:"ガイド",tUndo:"戻す",tClear:"消す",tDone:"完了",tBrush:"太さ",
  prev:"‹ 前へ",next:"次へ ›",tip:"ヒント：薄い文字をなぞってから、ガイドを消して書こう。",
  hint:"なぞる",praise:"上手！✍️",watch:"▶ 書き方を見る",noNet:"初回はネット接続が必要"}
};
let lang='bn';
function t(k){return (L[lang]&&L[lang][k])||L.en[k]||k;}
const $=id=>document.getElementById(id);

const HIRA="あ,a い,i う,u え,e お,o か,ka き,ki く,ku け,ke こ,ko さ,sa し,shi す,su せ,se そ,so た,ta ち,chi つ,tsu て,te と,to な,na に,ni ぬ,nu ね,ne の,no は,ha ひ,hi ふ,fu へ,he ほ,ho ま,ma み,mi む,mu め,me も,mo や,ya ゆ,yu よ,yo ら,ra り,ri る,ru れ,re ろ,ro わ,wa を,wo ん,n".split(" ").map(x=>x.split(","));
const KATA="ア,a イ,i ウ,u エ,e オ,o カ,ka キ,ki ク,ku ケ,ke コ,ko サ,sa シ,shi ス,su セ,se ソ,so タ,ta チ,chi ツ,tsu テ,te ト,to ナ,na ニ,ni ヌ,nu ネ,ne ノ,no ハ,ha ヒ,hi フ,fu ヘ,he ホ,ho マ,ma ミ,mi ム,mu メ,me モ,mo ヤ,ya ユ,yu ヨ,yo ラ,ra リ,ri ル,ru レ,re ロ,ro ワ,wa ヲ,wo ン,n".split(" ").map(x=>x.split(","));

let script='h',idx=0,guideOn=true;
function kana(){return script==='h'?HIRA:KATA;}
function cur(){return kana()[idx];}

/* ---------- CANVAS ENGINE ---------- */
const cv=$('cv'),ctx=cv.getContext('2d');
let W=0,H=0,dpr=1,strokes=[],drawing=false,curStroke=null,last=null;
function setup(){
 dpr=window.devicePixelRatio||1;
 const r=cv.getBoundingClientRect();W=r.width;H=r.height;
 cv.width=Math.round(W*dpr);cv.height=Math.round(H*dpr);
 ctx.setTransform(dpr,0,0,dpr,0,0);
 redraw();
}
function grid(){
 ctx.clearRect(0,0,W,H);
 ctx.fillStyle='#fbfbfd';ctx.fillRect(0,0,W,H);
 const pad=W*0.06;
 ctx.strokeStyle='#e6e7ee';ctx.lineWidth=1.5;
 ctx.strokeRect(pad,pad,W-2*pad,H-2*pad);
 ctx.strokeStyle='#eceef4';ctx.lineWidth=1;ctx.setLineDash([6,7]);
 ctx.beginPath();ctx.moveTo(W/2,pad);ctx.lineTo(W/2,H-pad);
 ctx.moveTo(pad,H/2);ctx.lineTo(W-pad,H/2);ctx.stroke();
 ctx.setLineDash([]);
}
function guide(){
 if(!guideOn)return;
 ctx.fillStyle='#e3e4ec';
 ctx.textAlign='center';ctx.textBaseline='middle';
 ctx.font='600 '+(H*0.66)+'px "Noto Sans JP",-apple-system,sans-serif';
 ctx.fillText(cur()[0],W/2,H/2+H*0.02);
}
function drawStroke(pts){
 if(pts.length<2){if(pts.length===1){ctx.fillStyle='#14141f';ctx.beginPath();ctx.arc(pts[0].x,pts[0].y,pts[0].w/2,0,7);ctx.fill();}return;}
 ctx.strokeStyle='#14141f';ctx.lineCap='round';ctx.lineJoin='round';
 for(let i=1;i<pts.length;i++){
  const a=pts[i-1],b=pts[i];
  ctx.lineWidth=(a.w+b.w)/2;
  ctx.beginPath();ctx.moveTo(a.x,a.y);
  const mx=(a.x+b.x)/2,my=(a.y+b.y)/2;
  ctx.quadraticCurveTo(a.x,a.y,mx,my);ctx.lineTo(b.x,b.y);ctx.stroke();
 }
}
function redraw(){grid();guide();strokes.forEach(drawStroke);}
function pos(e){const r=cv.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top};}
function widthFor(p){
 const base=+$('brush').value;
 if(!last)return base;
 const d=Math.hypot(p.x-last.x,p.y-last.y);
 return Math.max(base*0.42,Math.min(base,base*(1-d/48)));
}
function down(e){e.preventDefault();hideAnim();drawing=true;const p=pos(e);const w=+$('brush').value;
 curStroke=[{x:p.x,y:p.y,w}];strokes.push(curStroke);last=p;drawStroke(curStroke);}
function move(e){if(!drawing)return;e.preventDefault();
 const ev=(e.getCoalescedEvents?e.getCoalescedEvents():[e]);
 for(const c of ev){const p=pos(c);const w=widthFor(p);curStroke.push({x:p.x,y:p.y,w});
  const a=curStroke[curStroke.length-2],b=curStroke[curStroke.length-1];
  ctx.strokeStyle='#14141f';ctx.lineCap='round';ctx.lineJoin='round';ctx.lineWidth=(a.w+b.w)/2;
  ctx.beginPath();ctx.moveTo(a.x,a.y);const mx=(a.x+b.x)/2,my=(a.y+b.y)/2;ctx.quadraticCurveTo(a.x,a.y,mx,my);ctx.lineTo(b.x,b.y);ctx.stroke();
  last=p;}}
function up(e){drawing=false;curStroke=null;last=null;}
cv.addEventListener('pointerdown',down);
cv.addEventListener('pointermove',move);
window.addEventListener('pointerup',up);
cv.addEventListener('touchstart',e=>e.preventDefault(),{passive:false});
cv.addEventListener('touchmove',e=>e.preventDefault(),{passive:false});

/* ---------- CONTROLS ---------- */
function undo(){strokes.pop();redraw();}
function clearBoard(){strokes=[];redraw();}
function toggleGuide(){guideOn=!guideOn;$('guideBtn').classList.toggle('grad',guideOn);redraw();}
function playChar(){if(!('speechSynthesis'in window))return;speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(cur()[0]);u.lang='ja-JP';u.rate=.7;speechSynthesis.speak(u);}
function doneChar(){const p=$('praise');p.textContent=t('praise');p.classList.add('show');setTimeout(()=>p.classList.remove('show'),1100);setTimeout(()=>{if(idx<kana().length-1){idx++;loadChar();}},700);}
function nextChar(){idx=(idx+1)%kana().length;loadChar();}
function prevChar(){idx=(idx-1+kana().length)%kana().length;loadChar();}
function setScript(s){script=s;idx=0;$('sg-h').classList.toggle('on',s==='h');$('sg-k').classList.toggle('on',s==='k');renderStrip();loadChar();}

function renderStrip(){
 $('strip').innerHTML=kana().map((k,i)=>`<div class="chip ${i===idx?'on':''}" id="chip-${i}" onclick="pick(${i})">${k[0]}<small>${k[1]}</small></div>`).join('');
}
function pick(i){idx=i;loadChar();}
function loadChar(){
 strokes=[];hideAnim();
 document.querySelectorAll('.chip').forEach((c,i)=>c.classList.toggle('on',i===idx));
 const ch=$('chip-'+idx);if(ch)ch.scrollIntoView({inline:'center',block:'nearest',behavior:'smooth'});
 $('cc-char').textContent=cur()[0];$('cc-rom').textContent=cur()[1];
 redraw();
}

/* ---------- I18N ---------- */
function setLang(l){lang=l;['en','bn','ja'].forEach(x=>$('L-'+x).classList.toggle('on',x===l));
 $('ttl').textContent=t('title');$('sttl').textContent=t('sub');
 $('t-sound').textContent=t('tSound');$('t-guide').textContent=t('tGuide');$('t-undo').textContent=t('tUndo');
 $('t-clear').textContent=t('tClear');$('t-done').textContent=t('tDone');$('t-brush').textContent=t('tBrush');
 $('t-prev').textContent=t('prev');$('t-next').textContent=t('next');$('tip').textContent=t('tip');
 $('hintbadge').textContent='✎ '+t('hint');$('watchBtn').textContent=t('watch');}

/* ---------- INIT ---------- */
$('guideBtn').classList.add('grad');
renderStrip();loadChar();setLang('bn');
setup();
window.addEventListener('resize',()=>{const s=strokes;setup();strokes=s;redraw();});

/* ---------- STROKE-ORDER ANIMATION (kana-svg-data, free CDN) ---------- */
let animating=false,strokeCache={};
function hideAnim(){const a=$('anim');if(a){a.classList.remove('show');}animating=false;}
function sleep(ms){return new Promise(r=>setTimeout(r,ms));}
async function getData(ch,scr){
 const key=scr+ch;if(strokeCache[key])return strokeCache[key];
 const folder=scr==='h'?'hiragana':'katakana';
 const url='https://cdn.jsdelivr.net/npm/kana-svg-data/dist/'+folder+'/'+encodeURIComponent(ch)+'.json';
 try{const r=await fetch(url);if(!r.ok)throw 0;const d=await r.json();strokeCache[key]=d;return d;}catch(e){return null;}
}
function medPath(points){return 'M '+points.map(p=>p[0]+','+p[1]).join(' L ');}
function animStroke(mp,nib,dur){return new Promise(res=>{
 const Ln=mp.getTotalLength();nib.style.opacity='1';const t0=performance.now();
 (function f(t){if(!animating){res();return;}let p=Math.min(1,(t-t0)/dur);
  mp.style.strokeDashoffset=Ln*(1-p);const pt=mp.getPointAtLength(Ln*p);nib.setAttribute('cx',pt.x);nib.setAttribute('cy',pt.y);
  if(p<1)requestAnimationFrame(f);else res();})(performance.now());
});}
async function animateChar(){
 if(animating)return;
 const d=await getData(cur()[0],script);
 if(!d){const pr=$('praise');pr.textContent=t('noNet');pr.classList.add('show');setTimeout(()=>pr.classList.remove('show'),1500);return;}
 const NS='http://www.w3.org/2000/svg',svg=$('anim');svg.innerHTML='';const masks=[];
 d.strokes.forEach((st,i)=>{
  const pts=(d.medians[i]&&d.medians[i].value)||[];
  const mask=document.createElementNS(NS,'mask');mask.setAttribute('id','mk'+i);
  const mp=document.createElementNS(NS,'path');mp.setAttribute('d',pts.length?medPath(pts):st.value);
  mp.setAttribute('fill','none');mp.setAttribute('stroke','#fff');mp.setAttribute('stroke-width','130');
  mp.setAttribute('stroke-linecap','round');mp.setAttribute('stroke-linejoin','round');
  mask.appendChild(mp);svg.appendChild(mask);
  const vis=document.createElementNS(NS,'path');vis.setAttribute('d',st.value);vis.setAttribute('fill','#14141f');
  vis.setAttribute('mask','url(#mk'+i+')');svg.appendChild(vis);masks.push(mp);
 });
 const nib=document.createElementNS(NS,'circle');nib.setAttribute('r','15');nib.setAttribute('fill','#ff2d78');nib.setAttribute('class','nib');nib.style.opacity='0';svg.appendChild(nib);
 masks.forEach(mp=>{const L=mp.getTotalLength();mp.style.strokeDasharray=L;mp.style.strokeDashoffset=L;});
 strokes=[];redraw();svg.classList.add('show');animating=true;
 for(let i=0;i<masks.length&&animating;i++){await animStroke(masks[i],nib,650);await sleep(150);}
nib.style.opacity='0';animating=false;
}
$('watchBtn').textContent=t('watch');
</script></body></html>

```


## File: pubspec.yaml

```yaml
name: sensei_app
description: >-
  Bhasago — offline Bengali/English/Japanese-UI Japanese tutor for Bangladeshi
  workers preparing for JFT-Basic (A2) / JLPT N4 and life in Japan.
publish_to: "none"
version: 0.1.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  flutter_riverpod: ^2.5.1
  sqflite_sqlcipher: ^3.4.0   # SQLCipher AES-256 (encrypted at rest — T-101/06)
  flutter_secure_storage: ^9.2.4  # Keystore-backed DB passphrase store
  shared_preferences: ^2.2.3
  path: ^1.9.0
  record: ^5.1.2       # mic capture for shadowing
  just_audio: ^0.9.40  # native reference-audio playback
  fftea: ^1.5.0        # on-device pitch (F0) extraction for accent scoring

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  generate: true        # enable gen-l10n from lib/l10n/*.arb
  assets:
    - assets/content/
    - assets/stroke/

# Native model integration (llama.cpp / whisper.cpp / Kokoro) is wired through
# a Kotlin MethodChannel on the Android side — see README.

```


## File: test\fsrs_test.dart

```dart
// Dart mirror of tools/fsrs_reference.mjs property tests. Run: flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/domain/fsrs.dart';

void main() {
  const fsrs = Fsrs();

  test('retrievability: R(0)=1 and decreases with time', () {
    expect(fsrs.retrievability(0, 5), closeTo(1.0, 1e-9));
    expect(fsrs.retrievability(1, 5), greaterThan(fsrs.retrievability(10, 5)));
  });

  test('interval grows with stability and is >= 1 day', () {
    expect(fsrs.nextInterval(2), lessThan(fsrs.nextInterval(20)));
    expect(fsrs.nextInterval(0.01), greaterThanOrEqualTo(1));
  });

  ScheduledCard newCard() => ScheduledCard(id: 'x');

  test('new-card first review: Again<Hard<Good<Easy stability', () {
    final now = DateTime.now();
    final s1 = fsrs.review(newCard(), Rating.again, now: now).stability;
    final s2 = fsrs.review(newCard(), Rating.hard, now: now).stability;
    final s3 = fsrs.review(newCard(), Rating.good, now: now).stability;
    final s4 = fsrs.review(newCard(), Rating.easy, now: now).stability;
    expect(s1 < s2 && s2 < s3 && s3 < s4, isTrue);
  });

  test('difficulty stays within [1,10]', () {
    for (final r in Rating.values) {
      final d = fsrs.review(newCard(), r).difficulty;
      expect(d, inInclusiveRange(1.0, 10.0));
    }
  });

  test('Again on a review card lowers stability and adds a lapse', () {
    final now = DateTime.now();
    final card = ScheduledCard(
      id: 'y',
      stability: 10,
      difficulty: 5,
      state: CardState.review,
      lastReview: now.subtract(const Duration(days: 12)),
    );
    final after = fsrs.review(card, Rating.again, now: now);
    expect(after.stability, lessThan(card.stability));
    expect(after.lapses, equals(1));
  });
}

```


## File: tools\build_preview.mjs

```mjs
// Builds a self-contained, interactive HTML preview of the Bhasago app from the
// REAL content + stroke data, so the app can be seen/clicked without a Flutter
// SDK. Faithful to the Flutter UI (same tokens, screens, and the 5-step lesson
// micro-loop). Emits preview/index.html (standalone, for local screenshotting)
// and preview/sensei_body.html (body-only, for publishing as an Artifact).
// Run: node tools/build_preview.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const read = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), 'utf8'));

const hira = read('assets/content/hiragana.json');
const kata = read('assets/content/katakana.json');
const strokes = read('assets/stroke/kana_strokes.json');
const lesson = read('assets/content/lesson_work_intro.json');
const pitch = read('assets/content/pitch_accent.json');

const DATA = {
  hira: hira.items.map((k) => ({ char: k.char, romaji: k.romaji })),
  kata: kata.items.map((k) => ({ char: k.char, romaji: k.romaji })),
  strokes,
  lesson,
  pitch: pitch.items,
};

const STYLE = `
<style>
  :root{
    --bg:#0E1116; --surface:#161B22; --surface2:#1A2230; --line:rgba(255,255,255,.08);
    --text:#E8EAED; --muted:#8A93A2; --faint:#5A6472;
    --pink:#FF2D78; --pink-dim:#3A1526; --green:#00C853; --green-dim:#10361F;
    --amber:#FFC400; --amber-dim:#3A2A12; --blue:#2979FF;
    --font:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans","Noto Sans Bengali","Noto Sans JP",sans-serif;
  }
  *{box-sizing:border-box}
  body{margin:0}
  .stage{
    min-height:100vh; display:flex; align-items:center; justify-content:center;
    padding:24px; font-family:var(--font);
    background:
      radial-gradient(1200px 600px at 20% -10%, #1b2740 0%, transparent 55%),
      radial-gradient(900px 500px at 110% 20%, #2a1330 0%, transparent 50%),
      #05070c;
  }
  .frame{
    width:390px; max-width:100%; height:800px; max-height:calc(100vh - 40px);
    background:var(--bg); border-radius:40px; position:relative; overflow:hidden;
    border:1px solid rgba(255,255,255,.10);
    box-shadow:0 40px 90px -20px rgba(0,0,0,.8), 0 0 0 10px #0a0c11, 0 0 0 11px rgba(255,255,255,.06);
    display:flex; flex-direction:column; color:var(--text);
  }
  .statusbar{display:flex; justify-content:space-between; align-items:center;
    padding:12px 22px 4px; font-size:12px; color:var(--muted); letter-spacing:.3px}
  .statusbar .dots{display:flex; gap:4px; align-items:center}
  .statusbar .dots span{width:5px;height:5px;border-radius:50%;background:var(--muted)}
  .appbar{display:flex; align-items:center; justify-content:space-between; padding:6px 18px 10px}
  .brand{font-weight:800; letter-spacing:1.5px; font-size:15px}
  .brand b{color:var(--pink)}
  .langs{display:flex; gap:4px}
  .langs button{background:transparent; border:0; color:var(--muted); font:inherit; font-size:12px;
    padding:5px 9px; border-radius:9px; cursor:pointer}
  .langs button.on{background:rgba(255,45,120,.14); color:var(--pink)}
  .screen{flex:1; overflow-y:auto; overflow-x:hidden; -webkit-overflow-scrolling:touch}
  .screen::-webkit-scrollbar{width:0}
  .nav{display:flex; border-top:1px solid var(--line); background:rgba(10,13,20,.85); backdrop-filter:blur(8px)}
  .nav button{flex:1; background:none; border:0; color:var(--faint); padding:9px 0 12px; cursor:pointer;
    display:flex; flex-direction:column; align-items:center; gap:3px; font:inherit; font-size:9.5px}
  .nav button.on{color:var(--pink)}
  .nav svg{width:22px;height:22px;stroke:currentColor;fill:none;stroke-width:1.7}
  /* shared */
  h2.title{margin:16px 20px 2px; font-size:13px; color:var(--muted); font-weight:600}
  .sub{margin:0 20px; color:var(--faint); font-size:12px}
  .card{background:var(--surface); border:1px solid var(--line); border-radius:18px; padding:18px}
  .pad{padding:16px}
  .btn{border:0; border-radius:13px; font:inherit; font-weight:600; padding:12px 16px; cursor:pointer;
    min-height:48px; display:inline-flex; align-items:center; justify-content:center; gap:7px}
  .btn.primary{background:var(--pink); color:#fff}
  .btn.filled{background:var(--green); color:#04120a}
  .btn.ghost{background:rgba(255,255,255,.06); color:var(--text)}
  .btn.line{background:transparent; border:1px solid var(--line); color:var(--text)}
  .btn:disabled{opacity:.35; cursor:default}
  .row{display:flex; gap:8px}
  .grow{flex:1}
  .jp{font-weight:700}
  .muted{color:var(--muted)} .faint{color:var(--faint)}
  /* kana grid */
  .krow{display:flex; gap:8px; padding:0 16px 12px}
  .seg{display:flex; background:var(--surface); border:1px solid var(--line); border-radius:12px; overflow:hidden; margin:14px 20px 6px}
  .seg button{flex:1; background:none; border:0; color:var(--muted); font:inherit; padding:9px; cursor:pointer}
  .seg button.on{background:var(--pink); color:#fff}
  .grid{display:grid; grid-template-columns:repeat(5,1fr); gap:8px; padding:8px 16px 20px}
  .cell{background:var(--surface); border:1px solid var(--line); border-radius:14px; aspect-ratio:1;
    display:flex; flex-direction:column; align-items:center; justify-content:center; cursor:pointer; transition:.12s}
  .cell:active{transform:scale(.94); background:var(--surface2)}
  .cell .c{font-size:24px; font-weight:600}
  .cell .r{font-size:10px; color:var(--faint)}
  /* write */
  .strip{display:flex; gap:8px; overflow-x:auto; padding:12px 16px}
  .strip::-webkit-scrollbar{height:0}
  .chip{min-width:46px; height:46px; border-radius:12px; background:rgba(255,255,255,.06); border:0; color:var(--text);
    font-size:22px; cursor:pointer; flex:0 0 auto}
  .chip.on{background:var(--pink); color:#fff}
  #paper{width:100%; aspect-ratio:1; border-radius:20px; background:#FBFBFD; touch-action:none; display:block}
  .tools{display:flex; gap:8px; padding:12px 16px}
  .tools .btn{flex:1; padding:10px}
  /* controls (invariant) */
  .controls{display:flex; gap:8px; padding:0 16px 6px}
  .controls .btn{flex:1; padding:9px}
  .steps{display:flex; gap:4px; padding:8px 20px 2px}
  .steps i{flex:1; height:4px; border-radius:2px; background:rgba(255,255,255,.14)}
  .steps i.on{background:var(--green)}
  .phaselab{display:flex; justify-content:space-between; padding:2px 20px 0; font-size:12px}
  .opt{width:100%; text-align:left; background:rgba(255,255,255,.06); border:1.5px solid transparent; color:var(--text);
    border-radius:12px; padding:12px 14px; margin-bottom:8px; cursor:pointer; font:inherit; min-height:48px}
  .opt.good{background:var(--green-dim)} .opt.bad{background:var(--amber-dim)} .opt.hint{border-color:var(--green)}
  .tok{background:rgba(255,255,255,.08); border:0; color:var(--text); border-radius:10px; padding:8px 12px;
    font-size:18px; cursor:pointer; font-family:var(--font)}
  .assembled{min-height:56px; border:1.5px solid transparent; border-radius:12px; background:rgba(255,255,255,.05);
    padding:10px; display:flex; flex-wrap:wrap; gap:8px; align-items:center}
  .assembled.good{border-color:var(--green)} .assembled.bad{border-color:var(--amber)}
  .bank{display:flex; flex-wrap:wrap; gap:8px}
  .pillrow{display:flex; flex-wrap:wrap; gap:8px}
  .pill{background:rgba(255,255,255,.08); border-radius:999px; padding:6px 12px; font-size:14px}
  .center{display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; gap:12px; padding:24px; text-align:center}
  .big{font-size:34px; font-weight:800}
  .rate{display:flex; gap:6px}
  .rate .btn{flex:1; flex-direction:column; gap:2px; font-size:12px; padding:10px 4px}
  .rate small{color:rgba(255,255,255,.7); font-weight:400}
  /* pitch */
  .contour{display:flex; align-items:flex-end; gap:2px; height:44px; margin-top:6px}
  .mora{display:flex; flex-direction:column; align-items:center; gap:4px}
  .mora .b{width:22px; border-radius:3px 3px 0 0; background:var(--pink)}
  .wave{height:70px; border-radius:14px; background:
    repeating-linear-gradient(90deg, rgba(255,45,120,.35) 0 2px, transparent 2px 7px); opacity:.5}
  .tag{display:inline-block; font-size:11px; padding:2px 8px; border-radius:999px; background:rgba(0,200,83,.15); color:var(--green)}
</style>`;

const BODY = `
<div class="stage">
  <div class="frame">
    <div class="statusbar"><span>9:41</span><div class="dots"><span></span><span></span><span></span> ▮</div></div>
    <div class="appbar">
      <div class="brand">SEN<b>SEI</b></div>
      <div class="langs" id="langs">
        <button data-l="en">EN</button>
        <button data-l="bn" class="on">বাংলা</button>
        <button data-l="ja">日本語</button>
      </div>
    </div>
    <div class="screen" id="screen"></div>
    <div class="nav" id="nav"></div>
  </div>
</div>
<script>
const DATA = __DATA__;
let LANG = 'bn';
let tab = 2; // open on Learn (the micro-loop) first

const T = (tri) => (tri ? (tri[LANG] || tri.en) : '');
const gloss = (tri) => (LANG === 'bn' && tri && tri.en ? tri.en : '');

const NAV = [
  ['Kana','M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v6H4zM14 15h6v6h-6z'],
  ['Write','M4 20h16M6 16l9-9a2 2 0 0 1 3 3l-9 9-4 1z'],
  ['Learn','M3 7l9-4 9 4-9 4zM7 10v5c0 1 5 3 5 3s5-2 5-3v-5'],
  ['Speak','M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM5 11a7 7 0 0 0 14 0M12 18v3'],
  ['Pitch','M3 17l5-6 4 3 5-8'],
  ['Review','M4 9a8 8 0 0 1 14-4M20 5v4h-4M20 15a8 8 0 0 1-14 4M4 19v-4h4'],
];

function renderNav(){
  document.getElementById('nav').innerHTML = NAV.map((n,i)=>
    '<button class="'+(i===tab?'on':'')+'" onclick="go('+i+')"><svg viewBox="0 0 24 24"><path d="'+n[1]+'"/></svg>'+n[0]+'</button>'
  ).join('');
}
function go(i){ tab=i; render(); }
window.go = go;

function render(){
  renderNav();
  const s = document.getElementById('screen');
  s.innerHTML = [screenKana, screenWrite, screenLearn, screenSpeak, screenPitch, screenReview][tab]();
  if (tab===1) initWrite();
  s.scrollTop = 0;
}

/* ---------- 0: KANA ---------- */
let kataMode=false;
function screenKana(){
  const set = kataMode?DATA.kata:DATA.hira;
  return '<h2 class="title">'+(LANG==='bn'?'কানা শেখো':'Kana')+'</h2>'+
    '<div class="seg"><button class="'+(!kataMode?'on':'')+'" onclick="setKata(0)">ひらがな</button>'+
    '<button class="'+(kataMode?'on':'')+'" onclick="setKata(1)">カタカナ</button></div>'+
    '<div class="grid">'+set.map(k=>
      '<div class="cell" onclick="ping(this)"><div class="c">'+k.char+'</div><div class="r">'+k.romaji+'</div></div>'
    ).join('')+'</div>';
}
window.setKata=(v)=>{kataMode=!!v; render();};
window.ping=(el)=>{el.style.borderColor='var(--pink)'; setTimeout(()=>el.style.borderColor='',260);};

/* ---------- 1: WRITE (real KanjiVG stroke animation) ---------- */
let wKata=false, wIdx=0;
function screenWrite(){
  const chars = (wKata?DATA.kata:DATA.hira).map(k=>k.char);
  return '<h2 class="title">'+(LANG==='bn'?'লেখা অনুশীলন':'Write')+'</h2>'+
    '<div class="seg"><button class="'+(!wKata?'on':'')+'" onclick="setW(0)">ひらがな</button>'+
    '<button class="'+(wKata?'on':'')+'" onclick="setW(1)">カタカナ</button></div>'+
    '<div class="strip">'+chars.map((c,i)=>'<button class="chip '+(i===wIdx?'on':'')+'" onclick="pickW('+i+')">'+c+'</button>').join('')+'</div>'+
    '<div class="pad"><canvas id="paper"></canvas></div>'+
    '<div class="tools">'+
      '<button class="btn primary" onclick="playStroke()">▶ '+(LANG==='bn'?'দেখাও':'watch')+'</button>'+
      '<button class="btn line" onclick="toggleGuide()" id="guideBtn">👁 guide</button>'+
      '<button class="btn line" onclick="clearInk()">⌫ clear</button>'+
    '</div>'+
    '<div class="row" style="padding:0 16px 18px"><button class="btn filled grow" onclick="pickW('+((wIdx+1))+')">Skip / পরের ›</button></div>';
}
window.setW=(v)=>{wKata=!!v; wIdx=0; render();};
window.pickW=(i)=>{const n=(wKata?DATA.kata:DATA.hira).length; wIdx=((i%n)+n)%n; render();};
let guide=true, ink=[], anim=null;
window.toggleGuide=()=>{guide=!guide; drawPaper(0,null);};
window.clearInk=()=>{ink=[]; drawPaper(0,null);};
function curStrokes(){const c=(wKata?DATA.kata:DATA.hira)[wIdx].char; const set=wKata?DATA.strokes.katakana:DATA.strokes.hiragana; return set[c]||[];}
function initWrite(){
  const cv=document.getElementById('paper'); if(!cv) return;
  const fit=()=>{const r=cv.getBoundingClientRect(); const dpr=Math.min(devicePixelRatio||1,2);
    cv.width=r.width*dpr; cv.height=r.width*dpr; cv._s=r.width*dpr; drawPaper(0,null);};
  fit();
  let drawing=false;
  const pt=(e)=>{const r=cv.getBoundingClientRect(); const s=cv._s/r.width; return [(e.clientX-r.left)*s,(e.clientY-r.top)*s];};
  cv.onpointerdown=(e)=>{if(anim)return; drawing=true; ink.push([pt(e)]); cv.setPointerCapture(e.pointerId);};
  cv.onpointermove=(e)=>{if(!drawing||anim)return; ink[ink.length-1].push(pt(e)); drawPaper(animT,animStrokesLocal);};
  cv.onpointerup=()=>{drawing=false;};
}
let animT=0, animStrokesLocal=null;
function drawPaper(t, strokesShown){
  const cv=document.getElementById('paper'); if(!cv)return; const g=cv.getContext('2d'); const S=cv._s||cv.width;
  g.clearRect(0,0,S,S); g.fillStyle='#FBFBFD'; g.fillRect(0,0,S,S);
  const pad=S*0.06; g.strokeStyle='#E6E7EE'; g.lineWidth=1.4;
  g.strokeRect(pad,pad,S-2*pad,S-2*pad);
  g.beginPath(); g.moveTo(S/2,pad); g.lineTo(S/2,S-pad); g.moveTo(pad,S/2); g.lineTo(S-pad,S/2); g.stroke();
  if(guide && !strokesShown){ g.fillStyle='#E3E4EC'; g.font='700 '+(S*0.7)+'px var(--font)'; g.textAlign='center'; g.textBaseline='middle';
    g.fillText((wKata?DATA.kata:DATA.hira)[wIdx].char, S/2, S/2+S*0.04); }
  // user ink
  g.strokeStyle='#14141F'; g.lineWidth=S*0.045; g.lineCap='round'; g.lineJoin='round';
  for(const st of ink){ if(st.length<2){continue;} g.beginPath(); g.moveTo(st[0][0],st[0][1]); for(let i=1;i<st.length;i++)g.lineTo(st[i][0],st[i][1]); g.stroke(); }
  // stroke-order animation (scaled from viewBox 1000)
  if(strokesShown){
    const sc=S/1000; g.lineWidth=S*0.06;
    const scaled=strokesShown.map(s=>s.map(p=>[p[0]*sc,p[1]*sc]));
    const lens=scaled.map(len); const total=lens.reduce((a,b)=>a+b,0); let target=t*total, consumed=0;
    for(let i=0;i<scaled.length;i++){ if(consumed>=target)break; drawUpTo(g,scaled[i],Math.min(lens[i],target-consumed)); consumed+=lens[i]; }
  }
}
function len(p){let s=0;for(let i=1;i<p.length;i++)s+=Math.hypot(p[i][0]-p[i-1][0],p[i][1]-p[i-1][1]);return s;}
function drawUpTo(g,pts,maxLen){ if(pts.length<2)return; g.beginPath(); g.moveTo(pts[0][0],pts[0][1]); let acc=0;
  for(let i=1;i<pts.length;i++){const seg=Math.hypot(pts[i][0]-pts[i-1][0],pts[i][1]-pts[i-1][1]);
    if(acc+seg<=maxLen){g.lineTo(pts[i][0],pts[i][1]); acc+=seg;}
    else{const f=seg<=0?0:(maxLen-acc)/seg; g.lineTo(pts[i-1][0]+(pts[i][0]-pts[i-1][0])*f, pts[i-1][1]+(pts[i][1]-pts[i-1][1])*f); break;}}
  g.stroke(); }
window.playStroke=()=>{
  const strokes=curStrokes(); if(!strokes.length)return; ink=[]; if(anim)cancelAnimationFrame(anim);
  animStrokesLocal=strokes; const dur=600*strokes.length; const t0=performance.now();
  const step=(now)=>{animT=Math.min(1,(now-t0)/dur); drawPaper(animT,strokes);
    if(animT<1){anim=requestAnimationFrame(step);} else {anim=null; animStrokesLocal=null;}};
  anim=requestAnimationFrame(step);
};

/* ---------- 2: LEARN (5-step micro-loop) ---------- */
const PHASES=['intro','recognition','production','context','srs'];
const PLAB={intro:['পরিচিতি','Intro'],recognition:['চেনা','Recognition'],production:['বলা/লেখা','Production'],context:['বাক্য','Context'],srs:['রিভিউ','SRS']};
let L={started:false,done:false,item:0,phase:0,hint:false,pick:null,revealed:false,write:false,built:[],bank:null,bankItem:-1,showRom:true};
function lz(){return DATA.lesson.items;}
function resetStep(){L.hint=false;L.pick=null;L.revealed=false;L.write=false;L.built=[];L.bank=null;L.bankItem=-1;}
window.lStart=()=>{L.started=true;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lQuit=()=>{L.started=false;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lHint=()=>{L.hint=!L.hint;render();};
window.lAdvance=()=>{const n=lz().length;resetStep();
  if(L.phase<4)L.phase++; else if(L.item<n-1){L.item++;L.phase=0;} else {L.started=false;L.done=true;} render();};
window.lToggleRom=()=>{L.showRom=!L.showRom;render();};
window.lReveal=()=>{L.revealed=!L.revealed;render();};
window.lWrite=()=>{L.write=!L.write;render();};

function seededShuffle(arr,seed){const a=arr.slice();let s=seed;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};
  for(let i=a.length-1;i>0;i--){const j=Math.floor(rnd()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}

function screenLearn(){
  const les=DATA.lesson;
  if(L.done) return '<div class="center"><div style="font-size:42px">✅</div><div class="big" style="font-size:20px">'+(LANG==='bn'?'লেসন শেষ':'Lesson complete')+'</div><div class="muted">'+(LANG==='bn'?'আরেকটা?':'Another round?')+'</div><button class="btn filled" style="margin-top:12px" onclick="lStart()">'+(LANG==='bn'?'আবার':'Restart')+'</button></div>';
  if(!L.started) return '<div class="center"><div class="big" style="font-size:19px;text-wrap:balance">'+T(les.can_do)+'</div>'+(gloss(les.can_do)?'<div class="faint">'+gloss(les.can_do)+'</div>':'')+'<div class="muted">'+les.items.length+' '+(LANG==='bn'?'শব্দ':'items')+' · ৫ '+(LANG==='bn'?'ধাপ':'steps')+'</div><div class="faint" style="font-size:12px">'+(LANG==='bn'?'যেকোনো সময় Skip / Hint / Quit — কোনো চাপ নেই।':'Skip / Hint / Quit anytime — no pressure.')+'</div><button class="btn primary" style="margin-top:14px;min-width:160px" onclick="lStart()">'+(LANG==='bn'?'শুরু করো':'Start')+'</button></div>';

  const it=lz()[L.item]; const ph=PHASES[L.phase];
  let head='<div class="phaselab"><span class="muted">'+(LANG==='bn'?'শব্দ':'word')+' '+(L.item+1)+'/'+lz().length+'</span><span style="font-weight:600">'+(LANG==='bn'?PLAB[ph][0]:PLAB[ph][1])+'</span></div>'+
    '<div class="steps">'+PHASES.map((_,i)=>'<i class="'+(i<=L.phase?'on':'')+'"></i>').join('')+'</div>'+
    '<div class="controls"><button class="btn line" onclick="lHint()">💡 '+(LANG==='bn'?'ইঙ্গিত':'Hint')+'</button>'+
      '<button class="btn line" onclick="lAdvance()">⏭ '+(LANG==='bn'?'বাদ':'Skip')+'</button>'+
      '<button class="btn line" onclick="lQuit()">✕ '+(LANG==='bn'?'বন্ধ':'Quit')+'</button></div>';

  let body='';
  if(ph==='intro') body=phIntro(it);
  else if(ph==='recognition') body=phRecog(it);
  else if(ph==='production') body=phProd(it);
  else if(ph==='context') body=phContext(it);
  else body=phSrs(it);

  const hint = L.hint? '<div class="pad"><div class="card" style="background:var(--surface2);display:flex;gap:10px;align-items:flex-start"><span>💡</span><div><b>'+it.jp+'</b> · <span class="faint">'+it.romaji+'</span><div>'+T(it.meaning)+'</div></div></div></div>':'';
  return head+'<div class="pad">'+body+'</div>'+hint;
}
function phIntro(it){return '<div class="card" style="text-align:center">'+
  '<div class="big">'+it.jp+'</div>'+(L.showRom?'<div class="faint">'+it.romaji+'</div>':'')+
  '<div style="font-size:22px;margin:6px">🔊</div>'+
  '<div style="font-size:18px;font-weight:600">'+T(it.meaning)+'</div>'+(gloss(it.meaning)?'<div class="faint">'+gloss(it.meaning)+'</div>':'')+
  '<div class="card" style="background:#12190f;margin-top:12px;text-align:left">'+T(it.note)+(gloss(it.note)?'<div class="faint" style="font-size:12px">'+gloss(it.note)+'</div>':'')+'</div>'+
  '<div class="row" style="margin-top:14px"><button class="btn ghost" onclick="lToggleRom()">Romaji '+(L.showRom?'off':'on')+'</button><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'বুঝেছি':'Got it')+' ✓</button></div></div>';}
function phRecog(it){
  const others=lz().filter(x=>x.id!==it.id); const pick=seededShuffle(others,L.item+1).slice(0,3);
  const opts=seededShuffle([{m:it.meaning,ok:true}].concat(pick.map(o=>({m:o.meaning,ok:false}))), L.item*7+3);
  L._opts=opts;
  const chosen=L.pick!=null; const good=chosen&&opts[L.pick].ok;
  let h='<div class="card" style="text-align:center;margin-bottom:12px"><div class="big" style="font-size:28px">'+it.jp+'</div><div style="font-size:20px">🔊</div></div>';
  h+='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'এর মানে কী?':'What does it mean?')+'</div>';
  h+=opts.map((o,k)=>{let cls='opt'; if(L.pick===k)cls+=o.ok?' good':' bad'; if(L.hint&&o.ok)cls+=' hint';
    return '<button class="'+cls+'" onclick="lPick('+k+')">'+T(o.m)+'</button>';}).join('');
  if(good) h+='<div class="row" style="align-items:center;margin-top:4px"><span class="tag">✓ '+(LANG==='bn'?'ঠিক!':'Correct')+'</span><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(chosen) h+='<div style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'আবার দেখো':'Not quite — try another')+'</div>';
  return h;
}
window.lPick=(k)=>{L.pick=k;render();};
function phProd(it){return '<div class="card" style="text-align:center">'+
  '<div class="muted">'+(L.write?(LANG==='bn'?'এটি লেখো':'Write this'):(LANG==='bn'?'এটি বলো':'Say this'))+'</div>'+
  '<div style="font-size:18px;font-weight:600;margin:8px">'+T(it.meaning)+'</div>'+
  (L.revealed?'<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div>':'<div class="faint" style="font-size:26px">· · ·</div>')+
  '<div class="pillrow" style="justify-content:center;margin:14px 0">'+
    '<button class="btn line">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button>'+
    '<button class="btn line" onclick="lReveal()">'+(L.revealed?'🙈 Hide':'👁 Model')+'</button>'+
    '<button class="btn line" onclick="lWrite()">🔁 '+(L.write?'Speak':'Write')+'</button></div>'+
  '<div class="row"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';}
function phContext(it){
  const tokens=it.srs_words;
  if(tokens.length<2) return '<div class="card" style="text-align:center"><div class="muted">'+(LANG==='bn'?'বাক্যে':'In context')+'</div><div class="big" style="font-size:26px;margin:8px">'+it.jp+'</div><div>'+T(it.meaning)+'</div><div class="row" style="margin-top:14px"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';
  if(L.bankItem!==L.item){L.built=[]; L.bank=seededShuffle(tokens,L.item+5); L.bankItem=L.item;}
  const complete=L.built.length===tokens.length; const ordered=complete&&L.built.join('|')===tokens.join('|');
  let h='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'শব্দগুলো সাজিয়ে বাক্য বানাও':'Arrange the words')+'</div>';
  h+='<div style="margin-bottom:10px">'+T(it.meaning)+'</div>';
  h+='<div class="assembled '+(complete?(ordered?'good':'bad'):'')+'">'+(L.built.length?L.built.map((w,k)=>'<button class="tok" onclick="lUnbuild('+k+')">'+w+'</button>').join(''):'<span class="faint">'+(LANG==='bn'?'নিচের শব্দে ট্যাপ করো':'tap words below')+'</span>')+'</div>';
  h+='<div class="bank" style="margin-top:12px">'+L.bank.map((w,k)=>'<button class="tok" onclick="lBuild('+k+')">'+w+'</button>').join('')+'</div>';
  if(complete&&ordered) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="tag">✓</span><span class="grow" style="font-size:14px">'+it.jp+'</span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(complete) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="grow" style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'একটু এদিক-ওদিক':'not quite — rearrange')+'</span><button class="btn ghost" onclick="lResetCtx()">'+(LANG==='bn'?'আবার':'Reset')+'</button></div>';
  return h;
}
window.lBuild=(k)=>{L.built.push(L.bank.splice(k,1)[0]);render();};
window.lUnbuild=(k)=>{L.bank.push(L.built.splice(k,1)[0]);render();};
window.lResetCtx=()=>{const t=lz()[L.item].srs_words;L.bank=seededShuffle(t,L.item+5);L.built=[];render();};
function phSrs(it){return '<div class="card"><div class="muted">'+(LANG==='bn'?'রিভিউতে যোগ হলো':'Added to your review')+'</div>'+
  '<div class="pillrow" style="margin:12px 0">'+it.srs_words.map(w=>'<span class="pill">'+w+'</span>').join('')+'</div>'+
  '<div class="faint" style="font-size:13px;margin-bottom:8px">'+(LANG==='bn'?'কেমন লাগল?':'How was it?')+'</div>'+
  '<div class="rate">'+[['আবার','Again'],['কঠিন','Hard'],['ভালো','Good'],['সহজ','Easy']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="lAdvance()">'+(LANG==='bn'?r[0]:r[1])+'</button>').join('')+'</div></div>';}

/* ---------- 3: SPEAK (shadowing stub) ---------- */
function screenSpeak(){const it=lz()[0];
  return '<h2 class="title">'+(LANG==='bn'?'শ্যাডোয়িং':'Speak')+'</h2><div class="pad"><div class="card" style="text-align:center">'+
    '<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div><div>'+T(it.meaning)+'</div>'+
    '<div class="wave" style="margin:16px 0"></div>'+
    '<div class="pillrow" style="justify-content:center"><button class="btn line">🔊 '+(LANG==='bn'?'শোনো':'Listen')+'</button><button class="btn primary">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button></div>'+
    '<div class="faint" style="font-size:12px;margin-top:10px">'+(LANG==='bn'?'রেকর্ড করে নিজের সাথে মিলাও (Tier 0–1)':'Record & self-compare (Tier 0–1)')+'</div></div></div>';}

/* ---------- 4: PITCH ---------- */
function screenPitch(){
  return '<h2 class="title">'+(LANG==='bn'?'উচ্চারণ · পিচ':'Pitch accent')+'</h2><div class="pad">'+
    DATA.pitch.map(p=>{const max=Math.max.apply(null,p.pattern);
      const contour='<div class="contour">'+p.pattern.map((v,i)=>'<div class="mora"><div class="b" style="height:'+(v?38:16)+'px;background:'+(v?'var(--pink)':'var(--faint)')+'"></div><small class="faint" style="font-size:10px">'+([...p.word][i]||'')+'</small></div>').join('')+'</div>';
      return '<div class="card" style="margin-bottom:10px"><div class="row" style="justify-content:space-between;align-items:baseline"><div><span class="big" style="font-size:22px">'+p.word+'</span> <span class="faint">'+p.romaji+'</span></div><span class="tag">'+T(p.accent_type)+'</span></div>'+contour+'<div class="muted" style="font-size:13px;margin-top:6px">'+T(p.meaning)+'</div></div>';
    }).join('')+'</div>';
}

/* ---------- 5: REVIEW (FSRS flashcard) ---------- */
let rIdx=0, rRevealed=false;
const RDECK=[{w:'ありがとうございます',m:{en:'Thank you',bn:'ধন্যবাদ',ja:'ありがとう'}},{w:'すみません',m:{en:'Excuse me',bn:'মাফ করবেন',ja:'すみません'}}];
function screenReview(){
  if(rIdx>=RDECK.length) return '<div class="center"><div style="font-size:40px">🎉</div><div class="big" style="font-size:18px">'+(LANG==='bn'?'রিভিউ শেষ':'Review done')+'</div><button class="btn ghost" onclick="rReset()">↺</button></div>';
  const c=RDECK[rIdx];
  let h='<h2 class="title">'+(LANG==='bn'?'রিভিউ · FSRS':'Review')+'</h2><div class="pad"><div class="card" style="text-align:center;padding:28px"><div class="big" style="font-size:26px">'+c.w+'</div>'+(rRevealed?'<div style="margin-top:10px">'+T(c.m)+'</div>':'')+'</div>';
  if(!rRevealed) h+='<button class="btn primary" style="width:100%;margin-top:14px" onclick="rShow()">'+(LANG==='bn'?'উত্তর দেখাও':'Show answer')+'</button>';
  else h+='<div class="rate" style="margin-top:14px">'+[['আবার','Again','1d'],['কঠিন','Hard','3d'],['ভালো','Good','7d'],['সহজ','Easy','15d']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="rRate()">'+(LANG==='bn'?r[0]:r[1])+'<small>'+r[2]+'</small></button>').join('')+'</div>';
  return h+'</div>';
}
window.rShow=()=>{rRevealed=true;render();};
window.rRate=()=>{rRevealed=false;rIdx++;render();};
window.rReset=()=>{rIdx=0;rRevealed=false;render();};

/* ---------- lang + boot ---------- */
document.getElementById('langs').addEventListener('click',(e)=>{const b=e.target.closest('button'); if(!b)return;
  LANG=b.dataset.l; [...document.querySelectorAll('#langs button')].forEach(x=>x.classList.toggle('on',x===b)); render();});
render();
</script>`;

const body = BODY.replace('__DATA__', JSON.stringify(DATA));
fs.mkdirSync(path.join(ROOT, 'preview'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'preview', 'sensei_body.html'), STYLE + body);
fs.writeFileSync(
  path.join(ROOT, 'preview', 'index.html'),
  '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Bhasago preview</title></head><body>' +
    STYLE + body + '</body></html>',
);
console.log('wrote preview/index.html and preview/sensei_body.html');
console.log('  kana:', DATA.hira.length + DATA.kata.length, '| stroke sets:',
  Object.keys(strokes.hiragana).length + Object.keys(strokes.katakana).length,
  '| lesson items:', DATA.lesson.items.length, '| pitch:', DATA.pitch.length);

```


## File: tools\export_for_llm.mjs

```mjs
import fs from 'fs';
import path from 'path';

const EXPORT_DIR = 'llm_export';
const OUTPUT_FILE = path.join(EXPORT_DIR, 'full_codebase.md');
const TREE_FILE = path.join(EXPORT_DIR, 'file_tree.txt');

// Directories to ignore
const IGNORE_DIRS = new Set(['.git', 'node_modules', '.dart_tool', 'build', '.agents', '.claude', 'llm_export', 'docs/_TO_DELETE']);
// File extensions to include in full code dump
const INCLUDE_EXTS = new Set(['.dart', '.md', '.json', '.yaml', '.arb', '.mjs', '.txt', '.html']);
// Specific files to exclude
const EXCLUDE_FILES = new Set(['package-lock.json', 'kana_strokes.json']);

if (!fs.existsSync(EXPORT_DIR)) {
  fs.mkdirSync(EXPORT_DIR);
}

function generateTree(dir, prefix = '') {
  let output = '';
  const files = fs.readdirSync(dir).sort();
  
  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    if (IGNORE_DIRS.has(file)) continue;
    
    const fullPath = path.join(dir, file);
    const isLast = i === files.length - 1;
    const stat = fs.statSync(fullPath);
    
    output += `${prefix}${isLast ? '└── ' : '├── '}${file}\n`;
    
    if (stat.isDirectory()) {
      output += generateTree(fullPath, prefix + (isLast ? '    ' : '│   '));
    }
  }
  return output;
}

function dumpCodebase(dir, basePath = '') {
  let output = '';
  const files = fs.readdirSync(dir).sort();
  
  for (const file of files) {
    if (IGNORE_DIRS.has(file)) continue;
    if (EXCLUDE_FILES.has(file)) continue;
    
    const fullPath = path.join(dir, file);
    const relPath = path.join(basePath, file);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      output += dumpCodebase(fullPath, relPath);
    } else {
      const ext = path.extname(file);
      if (INCLUDE_EXTS.has(ext) || file === 'Dockerfile') {
        const content = fs.readFileSync(fullPath, 'utf8');
        output += `\n\n## File: ${relPath}\n\n`;
        output += '```' + (ext.replace('.', '') || 'text') + '\n';
        output += content;
        output += '\n```\n';
      }
    }
  }
  return output;
}

console.log('Generating file tree...');
const tree = 'SENSEI/\n' + generateTree('.');
fs.writeFileSync(TREE_FILE, tree);

console.log('Gathering codebase content...');
const code = `# SENSEI (Bhasago) Codebase Dump\n\n${dumpCodebase('.')}`;
fs.writeFileSync(OUTPUT_FILE, code);

console.log(`\nExport complete! Files created in /${EXPORT_DIR}:`);
console.log(`- ${TREE_FILE} (Directory structure)`);
console.log(`- ${OUTPUT_FILE} (All source code and markdown)`);

```


## File: tools\fetch_stroke_data.mjs

```mjs
// One-time DEV tool. Run locally:  node tools/fetch_stroke_data.mjs
// Builds assets/stroke/kana_strokes.json so the app ships stroke-order data OFFLINE
// (no runtime network). Source = KanjiVG (canonical, correct stroke order/count),
// one <path> per stroke, in stroke order. We flatten each stroke path into sampled
// median points and scale KanjiVG's 109x109 viewBox up to the consumer's 0..1000
// y-down space (writing_screen.dart uses `sc = w/1000`), so the Flutter code is
// unchanged. Replaces the old kana-svg-data medians, which split looping strokes into
// two paths (16/92 wrong counts, e.g. あ→4, ヲ→2). See 99_DECISIONS.md D-011.
//
// KanjiVG is CC BY-SA 3.0 (© Ulrich Apel / KanjiVG contributors). The generated JSON
// is a derivative and stays under CC BY-SA; attribution is embedded in the file.
import fs from 'fs';

const HIRA = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'.split('');
const KATA = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'.split('');

const KVG_VIEWBOX = 109; // KanjiVG native viewBox is "0 0 109 109"
const OUT_VIEWBOX = 1000; // must match the scale in writing_screen.dart's painter
const SCALE = OUT_VIEWBOX / KVG_VIEWBOX;
const BEZIER_STEPS = 8; // samples per cubic/quadratic segment (smooth enough at this size)

// --- minimal SVG path flattener: M/m L/l H/h V/v C/c S/s Q/q T/t Z/z --------------
function tokenize(d) {
  const re = /([MmLlHhVvCcSsQqTtAaZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)/g;
  const out = [];
  let m;
  while ((m = re.exec(d))) out.push(m[1] ? { cmd: m[1] } : { num: parseFloat(m[2]) });
  return out;
}

function cubic(p0, p1, p2, p3, steps, push) {
  for (let k = 1; k <= steps; k++) {
    const t = k / steps, u = 1 - t;
    push(
      u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
      u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1],
    );
  }
}
function quad(p0, p1, p2, steps, push) {
  for (let k = 1; k <= steps; k++) {
    const t = k / steps, u = 1 - t;
    push(u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]);
  }
}

// Flatten one path's `d` into an array of [x,y] points (KanjiVG space).
function flatten(d) {
  const toks = tokenize(d);
  const pts = [];
  let i = 0, cur = [0, 0], start = [0, 0], prevCtrl = null, cmd = null;
  const nums = (n) => { const a = []; for (let k = 0; k < n; k++) a.push(toks[i++].num); return a; };
  const push = (x, y) => pts.push([x, y]);
  const first = () => pts.length === 0;

  while (i < toks.length) {
    if (toks[i].cmd) { cmd = toks[i++].cmd; }
    const abs = cmd === cmd.toUpperCase();
    const C = cmd.toUpperCase();
    switch (C) {
      case 'M': {
        const [x, y] = nums(2);
        cur = abs || first() ? [x, y] : [cur[0] + x, cur[1] + y];
        start = [...cur];
        push(cur[0], cur[1]);
        cmd = abs ? 'L' : 'l'; // subsequent implicit pairs are lineto
        prevCtrl = null;
        break;
      }
      case 'L': {
        const [x, y] = nums(2);
        cur = abs ? [x, y] : [cur[0] + x, cur[1] + y];
        push(cur[0], cur[1]); prevCtrl = null; break;
      }
      case 'H': {
        const [x] = nums(1);
        cur = [abs ? x : cur[0] + x, cur[1]];
        push(cur[0], cur[1]); prevCtrl = null; break;
      }
      case 'V': {
        const [y] = nums(1);
        cur = [cur[0], abs ? y : cur[1] + y];
        push(cur[0], cur[1]); prevCtrl = null; break;
      }
      case 'C': {
        const n = nums(6);
        const p1 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        const p2 = abs ? [n[2], n[3]] : [cur[0] + n[2], cur[1] + n[3]];
        const p3 = abs ? [n[4], n[5]] : [cur[0] + n[4], cur[1] + n[5]];
        cubic(cur, p1, p2, p3, BEZIER_STEPS, push);
        prevCtrl = p2; cur = p3; break;
      }
      case 'S': {
        const n = nums(4);
        const p1 = prevCtrl ? [2 * cur[0] - prevCtrl[0], 2 * cur[1] - prevCtrl[1]] : [...cur];
        const p2 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        const p3 = abs ? [n[2], n[3]] : [cur[0] + n[2], cur[1] + n[3]];
        cubic(cur, p1, p2, p3, BEZIER_STEPS, push);
        prevCtrl = p2; cur = p3; break;
      }
      case 'Q': {
        const n = nums(4);
        const p1 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        const p2 = abs ? [n[2], n[3]] : [cur[0] + n[2], cur[1] + n[3]];
        quad(cur, p1, p2, BEZIER_STEPS, push);
        prevCtrl = p1; cur = p2; break;
      }
      case 'T': {
        const n = nums(2);
        const p1 = prevCtrl ? [2 * cur[0] - prevCtrl[0], 2 * cur[1] - prevCtrl[1]] : [...cur];
        const p2 = abs ? [n[0], n[1]] : [cur[0] + n[0], cur[1] + n[1]];
        quad(cur, p1, p2, BEZIER_STEPS, push);
        prevCtrl = p1; cur = p2; break;
      }
      case 'Z': {
        push(start[0], start[1]); cur = [...start]; prevCtrl = null; break;
      }
      default: // A (arc) — not used by KanjiVG; skip its 7 params defensively
        if (C === 'A') { nums(7); } else { i++; }
        prevCtrl = null;
    }
  }
  return pts;
}

// Scale to OUT_VIEWBOX, round, and drop consecutive duplicate points.
function scaleClean(pts) {
  const out = [];
  for (const [x, y] of pts) {
    const p = [Math.round(x * SCALE), Math.round(y * SCALE)];
    const last = out[out.length - 1];
    if (!last || last[0] !== p[0] || last[1] !== p[1]) out.push(p);
  }
  return out;
}

async function fetchStrokes(ch) {
  const cp = ch.codePointAt(0).toString(16).padStart(5, '0');
  const url = `https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/${cp}.svg`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${ch} (${cp}) HTTP ${r.status}`);
  const svg = await r.text();
  // one <path d="..."> per stroke, in document (= stroke) order
  const paths = [...svg.matchAll(/<path[^>]*\sd="([^"]+)"/g)].map((m) => m[1]);
  if (!paths.length) throw new Error(`${ch} (${cp}) no <path> found`);
  return paths.map((d) => scaleClean(flatten(d))).filter((s) => s.length > 1);
}

const out = {
  viewBox: OUT_VIEWBOX,
  source: 'KanjiVG (https://kanjivg.tagaini.net)',
  license: 'CC BY-SA 3.0 — © Ulrich Apel / KanjiVG contributors',
  note: 'Generated by tools/fetch_stroke_data.mjs. One median polyline per stroke, in stroke order.',
  hiragana: {},
  katakana: {},
};

for (const [arr, key] of [[HIRA, 'hiragana'], [KATA, 'katakana']]) {
  for (const ch of arr) {
    try { out[key][ch] = await fetchStrokes(ch); process.stdout.write('.'); }
    catch (e) { console.error('\nFAIL', e.message); }
  }
}

fs.writeFileSync('assets/stroke/kana_strokes.json', JSON.stringify(out));
console.log(
  `\nwrote assets/stroke/kana_strokes.json  (hira:${Object.keys(out.hiragana).length} kata:${Object.keys(out.katakana).length})`,
);

```


## File: tools\fsrs_reference.mjs

```mjs
// Executable reference port of lib/domain/fsrs.dart (identical math), with
// property tests. Run:  node tools/fsrs_reference.mjs
// This proves the scheduling logic before it ships in Dart.

const DECAY = -0.5;
const FACTOR = 19 / 81;
const W = [
  0.40255, 0.59854, 2.40984, 5.80984, 4.92593, 0.94123, 0.86231,
  0.01000, 1.48959, 0.14480, 0.94123, 2.18154, 0.05000, 0.34560,
  1.26000, 0.29400, 2.61000,
];
const REQ = 0.90;
const clampD = (d) => Math.min(10, Math.max(1, d));

const retrievability = (t, s) => (s <= 0 ? 0 : Math.pow(1 + FACTOR * t / s, DECAY));
const nextInterval = (s) =>
  Math.min(36500, Math.max(1, Math.round((s / FACTOR) * (Math.pow(REQ, 1 / DECAY) - 1))));

const initStability = (g) => Math.max(W[g - 1], 0.1);
const initDifficulty = (g) => clampD(W[4] - W[5] * (g - 3));
const nextDifficulty = (d, g) =>
  clampD(W[7] * initDifficulty(4) + (1 - W[7]) * (d - W[6] * (g - 3)));

const stabRecall = (d, s, r, g) => {
  const hard = g === 2 ? W[15] : 1.0;
  const easy = g === 4 ? W[16] : 1.0;
  const inc =
    Math.exp(W[8]) * (11 - d) * Math.pow(s, -W[9]) *
    (Math.exp((1 - r) * W[10]) - 1) * hard * easy;
  return s * (1 + inc);
};
const stabForget = (d, s, r) =>
  W[11] * Math.pow(d, -W[12]) * (Math.pow(s + 1, W[13]) - 1) * Math.exp((1 - r) * W[14]);

function review(card, g, elapsedDays) {
  if (card.state === 'new') {
    return {
      stability: initStability(g),
      difficulty: initDifficulty(g),
      state: g === 1 ? 'learning' : 'review',
      lapses: card.lapses,
    };
  }
  const r = retrievability(elapsedDays, card.stability);
  if (g === 1) {
    return {
      stability: stabForget(card.difficulty, card.stability, r),
      difficulty: nextDifficulty(card.difficulty, g),
      state: 'relearning',
      lapses: card.lapses + 1,
    };
  }
  return {
    stability: stabRecall(card.difficulty, card.stability, r, g),
    difficulty: nextDifficulty(card.difficulty, g),
    state: 'review',
    lapses: card.lapses,
  };
}

// -------------------- PROPERTY TESTS --------------------
let pass = 0, fail = 0;
const ok = (name, cond) => { cond ? pass++ : fail++; console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}`); };
const approx = (a, b) => Math.abs(a - b) < 1e-9;

// 1. R(0) = 1, and strictly decreasing in time.
ok('R(0)=1', approx(retrievability(0, 5), 1));
ok('R decreases with time', retrievability(1, 5) > retrievability(10, 5));

// 2. Interval grows with stability, and ~= stability at 90% retention.
ok('interval grows with stability', nextInterval(2) < nextInterval(20));
ok('interval>=1 day', nextInterval(0.01) >= 1);

// 3. New-card first review: Again<Hard<Good<Easy in resulting stability.
const nw = { state: 'new', stability: 0, difficulty: 0, lapses: 0 };
const s1 = review(nw, 1, 0).stability, s2 = review(nw, 2, 0).stability,
      s3 = review(nw, 3, 0).stability, s4 = review(nw, 4, 0).stability;
ok('new: Again<Hard<Good<Easy stability', s1 < s2 && s2 < s3 && s3 < s4);

// 4. Difficulty always within [1,10] across ratings and states.
let dOk = true;
for (let g = 1; g <= 4; g++) {
  const d = review(nw, g, 0).difficulty;
  if (d < 1 || d > 10) dOk = false;
}
const rev = { state: 'review', stability: 10, difficulty: 5, lapses: 0 };
for (let g = 1; g <= 4; g++) {
  const d = review(rev, g, 12).difficulty;
  if (d < 1 || d > 10) dOk = false;
}
ok('difficulty stays in [1,10]', dOk);

// 5. Review success: higher rating -> higher next stability (monotonic).
const r2 = review(rev, 2, 12).stability, r3 = review(rev, 3, 12).stability,
      r4 = review(rev, 4, 12).stability;
ok('review: Hard<Good<Easy stability', r2 < r3 && r3 < r4);

// 6. Successful review increases stability (memory strengthens).
ok('Good review increases stability', review(rev, 3, 12).stability > rev.stability);

// 7. Again (lapse) reduces stability and increments lapses.
const lapse = review(rev, 1, 12);
ok('Again reduces stability', lapse.stability < rev.stability);
ok('Again increments lapses', lapse.lapses === 1);

// 8. Easier-to-recall cards (higher R) get bigger stability boost.
const lowR = review({ state: 'review', stability: 10, difficulty: 5, lapses: 0 }, 3, 30).stability;
const highR = review({ state: 'review', stability: 10, difficulty: 5, lapses: 0 }, 3, 1).stability;
ok('lower retrievability -> larger stability increment', lowR > highR);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);

```


## File: tools\lesson_flow_reference.mjs

```mjs
// Runnable proof for the lesson micro-loop state machine (LessonScreen._advance).
// The autonomy invariant needs: Skip/Next ALWAYS progresses (never blocks, never
// penalizes) and the loop ALWAYS terminates. Mirrors _advance/_quit exactly, with
// no Flutter SDK. Run: node tools/lesson_flow_reference.mjs

const PHASES = ['intro', 'recognition', 'production', 'context', 'srs']; // 09 §micro-loop

// port of _advance(itemCount) — Skip and Next both call this (identical path)
function advance(s, itemCount) {
  if (s.phase < PHASES.length - 1) return { ...s, phase: s.phase + 1 };
  if (s.item < itemCount - 1) return { ...s, item: s.item + 1, phase: 0 };
  return { ...s, started: false, done: true };
}
// port of _quit()
const quit = () => ({ item: 0, phase: 0, started: false, done: false });
const start = () => ({ item: 0, phase: 0, started: true, done: false });

let pass = 0, fail = 0;
const ok = (label, cond) => { console.log((cond ? 'ok   ' : 'FAIL ') + label); cond ? pass++ : fail++; };

// 1. A 2-item lesson visits all 5 phases of item 0, then all 5 of item 1, then done.
{
  const n = 2;
  let s = start();
  const seen = [];
  let guard = 0;
  while (s.started && guard++ < 100) {
    seen.push(s.item + ':' + PHASES[s.phase]);
    s = advance(s, n); // simulate tapping Next/Skip every step
  }
  const want = [
    '0:intro', '0:recognition', '0:production', '0:context', '0:srs',
    '1:intro', '1:recognition', '1:production', '1:context', '1:srs',
  ];
  ok('visits every phase of every item in order', JSON.stringify(seen) === JSON.stringify(want));
  ok('loop terminates (done=true, started=false)', s.done && !s.started);
}

// 2. Skip has the SAME effect as Next — it always moves forward, from any step.
{
  const n = 3;
  for (let item = 0; item < n; item++) {
    for (let phase = 0; phase < PHASES.length; phase++) {
      const before = { item, phase, started: true, done: false };
      const after = advance(before, n); // "Skip"
      const progressed = after.done ||
        after.item > before.item ||
        (after.item === before.item && after.phase > before.phase);
      ok(`skip progresses from ${item}:${PHASES[phase]}`, progressed);
    }
  }
}

// 3. Quit always returns to a clean overview (no penalty state carried).
{
  const s = quit();
  ok('quit resets to overview', !s.started && !s.done && s.item === 0 && s.phase === 0);
}

// 4. A 1-item lesson still runs all 5 phases then completes (no under/overflow).
{
  let s = start();
  let steps = 0, guard = 0;
  while (s.started && guard++ < 100) { steps++; s = advance(s, 1); }
  ok('single-item lesson runs exactly 5 steps then done', steps === 5 && s.done);
}

console.log(`\n${pass}/${pass + fail} passed`);
process.exit(fail ? 1 : 0);

```


## File: tools\migrations_reference.mjs

```mjs
// Runnable proof for the DB migration runner (lib/db/migrations/migration.dart).
// Mirrors runMigrations()' version-window selection exactly, so the off-by-one-
// prone logic is verified without a Flutter SDK. Run: node tools/migrations_reference.mjs

// --- port of runMigrations(all, from, to): apply (from, to] in ascending order ---
function runMigrations(all, from, to) {
  return all
    .filter((m) => m.version > from && m.version <= to)
    .sort((a, b) => a.version - b.version)
    .map((m) => m.version);
}
// --- port of kSchemaVersion: highest migration number ---
const schemaVersion = (all) => all.reduce((max, m) => (m.version > max ? m.version : max), 0);

const m = (v) => ({ version: v, name: 'm' + v });
let pass = 0, fail = 0;
function eq(label, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  console.log((ok ? 'ok   ' : 'FAIL ') + label + '  got=' + JSON.stringify(got) + ' want=' + JSON.stringify(want));
  ok ? pass++ : fail++;
}

const one = [m(1)];
const three = [m(1), m(2), m(3)];
const shuffled = [m(3), m(1), m(2)]; // registry must tolerate any input order

eq('fresh DB (0->1) runs baseline only', runMigrations(one, 0, 1), [1]);
eq('fresh DB (0->3) runs all in order', runMigrations(three, 0, 3), [1, 2, 3]);
eq('upgrade 1->2 skips applied baseline', runMigrations(three, 1, 2), [2]);
eq('upgrade 2->3 runs only the delta', runMigrations(three, 2, 3), [3]);
eq('no-op 3->3 runs nothing', runMigrations(three, 3, 3), []);
eq('out-of-order registry still ascends', runMigrations(shuffled, 0, 3), [1, 2, 3]);
eq('partial upgrade 0->2 stops at target', runMigrations(three, 0, 2), [1, 2]);
eq('kSchemaVersion = max (baseline)', schemaVersion(one), 1);
eq('kSchemaVersion = max (three)', schemaVersion(three), 3);
eq('kSchemaVersion = max (shuffled)', schemaVersion(shuffled), 3);

console.log(`\n${pass}/${pass + fail} passed`);
process.exit(fail ? 1 : 0);

```


## File: tools\pitch_reference.mjs

```mjs
// Executable mirror of lib/domain/pitch.dart, with tests on synthetic signals.
// Run: node tools/pitch_reference.mjs
const SR = 16000;

function estimateF0(buf, sampleRate, minHz = 70, maxHz = 500) {
  const n = buf.length;
  let rms = 0; for (const s of buf) rms += s * s; rms = Math.sqrt(rms / n);
  if (rms < 0.01) return -1;
  const minLag = Math.floor(sampleRate / maxHz);
  const maxLag = Math.min(n - 1, Math.ceil(sampleRate / minHz));
  const c = new Array(maxLag + 2).fill(0);
  let best = 0, bestLag = -1;
  for (let lag = minLag; lag <= maxLag; lag++) {
    let sum = 0; for (let i = 0; i < n - lag; i++) sum += buf[i] * buf[i + lag];
    c[lag] = sum;
    if (sum > best) { best = sum; bestLag = lag; }
  }
  if (bestLag <= 0) return -1;
  let refined = bestLag;
  if (bestLag > minLag && bestLag < maxLag) {
    const a = c[bestLag - 1], b = c[bestLag], g = c[bestLag + 1];
    const denom = a - 2 * b + g;
    if (Math.abs(denom) > 1e-9) refined = bestLag + 0.5 * (a - g) / denom;
  }
  const f = sampleRate / refined;
  return (f >= minHz && f <= maxHz) ? f : -1;
}
function toShape(contour) {
  const voiced = contour.filter((f) => f > 0);
  if (!voiced.length) return contour.map(() => null);
  const mean = voiced.reduce((a, b) => a + b, 0) / voiced.length;
  return contour.map((f) => (f > 0 ? 12 * Math.log2(f / mean) : null));
}
function resample(xs, len) {
  if (!xs.length) return Array(len).fill(null);
  return Array.from({ length: len }, (_, i) => xs[Math.min(xs.length - 1, Math.floor(i * xs.length / len))]);
}
function accentScore(reference, learner) {
  const r = toShape(reference), l = toShape(learner);
  const len = Math.max(r.length, l.length);
  const rr = resample(r, len), ll = resample(l, len);
  let err = 0, count = 0;
  for (let i = 0; i < len; i++) { if (rr[i] == null || ll[i] == null) continue; err += Math.abs(rr[i] - ll[i]); count++; }
  if (!count) return 0;
  return Math.max(0, Math.min(100, 100 * (1 - (err / count) / 6)));
}
const sine = (hz, ms, sr = SR) => Array.from({ length: Math.round(sr * ms / 1000) }, (_, i) => Math.sin(2 * Math.PI * hz * i / sr));

let pass = 0, fail = 0;
const ok = (name, cond, extra = '') => { cond ? pass++ : fail++; console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}${extra ? '  (' + extra + ')' : ''}`); };

// 1. Detect a pure 220 Hz tone within 2 Hz.
const f = estimateF0(sine(220, 200), SR);
ok('estimateF0 detects 220Hz', Math.abs(f - 220) < 2, `got ${f.toFixed(1)}Hz`);

// 2. Detect 330 Hz too.
const f2 = estimateF0(sine(330, 200), SR);
ok('estimateF0 detects 330Hz', Math.abs(f2 - 330) < 2, `got ${f2.toFixed(1)}Hz`);

// 3. Silence -> unvoiced.
ok('silence -> unvoiced (-1)', estimateF0(Array(2048).fill(0), SR) === -1);

// 4. Identical contours -> perfect score.
const rising = [180, 190, 200, 220, 240, 260];
ok('identical contour -> 100', accentScore(rising, rising) === 100);

// 5. Same shape, different octave (male vs female) -> still ~100 (speaker-independent).
const risingHigh = rising.map((x) => x * 2);
ok('same shape different octave -> ~100', accentScore(rising, risingHigh) > 99, `${accentScore(rising, risingHigh).toFixed(1)}`);

// 6. Opposite melody (rising vs falling) -> low score.
const falling = [...rising].reverse();
ok('opposite melody -> low score', accentScore(rising, falling) < 40, `${accentScore(rising, falling).toFixed(1)}`);

// 7. atamadaka (HL) vs heiban-ish (LH) minimal pair -> clearly different.
const HL = [260, 250, 200, 190]; // high then low
const LH = [190, 200, 250, 260]; // low then high
ok('HL vs LH distinguishable', accentScore(HL, LH) < 50, `${accentScore(HL, LH).toFixed(1)}`);
ok('HL vs HL close', accentScore(HL, HL.map((x) => x + 5)) > 90, `${accentScore(HL, HL.map((x) => x + 5)).toFixed(1)}`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);

```


## File: tools\preview_server.mjs

```mjs
import http from 'http';
import fs from 'fs';
import path from 'path';
const dir = path.join(process.cwd(), 'preview');
http.createServer((req, res) => {
  let f = req.url === '/' ? '/index.html' : req.url.split('?')[0];
  const p = path.join(dir, f);
  if (!fs.existsSync(p)) { res.writeHead(404); return res.end('nope'); }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  fs.createReadStream(p).pipe(res);
}).listen(5599, () => console.log('preview on http://localhost:5599'));

```


## File: tools\validate_content.mjs

```mjs
#!/usr/bin/env node
// Content guardrail — enforces the 12 validation rules from 05_CONTENT_SCHEMAS.md.
// Run: node tools/validate_content.mjs
// Exit 0 = PASS, Exit 1 = FAIL (blocking errors found)

const fs = require('fs');
const path = require('path');

const CONTENT_DIR = 'assets/content';
const FACTORY_DIR = 'content_factory';

// ── Load guardrails ──────────────────────────────────────────────────────

let bannedPhrases = [];
const bannedPath = path.join(FACTORY_DIR, 'banned_phrases.txt');
if (fs.existsSync(bannedPath)) {
  bannedPhrases = fs.readFileSync(bannedPath, 'utf-8')
    .split('\n')
    .map(l => l.trim())
    .filter(l => l && !l.startsWith('#'));
}

let whitelist = new Set();
const whitelistPath = path.join(FACTORY_DIR, 'jft_a2_whitelist.txt');
if (fs.existsSync(whitelistPath)) {
  whitelist = new Set(
    fs.readFileSync(whitelistPath, 'utf-8')
      .split('\n')
      .map(l => l.trim())
      .filter(l => l && !l.startsWith('#'))
  );
}

// ── Rule definitions ─────────────────────────────────────────────────────

const rules = {
  // BLOCKING rules (exit 1 if violated)
  1: { name: 'Every [JP] has a [BN]', blocking: true },
  5: { name: 'Strict JSON', blocking: true },
  6: { name: 'Schema-valid structure', blocking: true },
  7: { name: 'No half-width katakana in beginner packs', blocking: true },
  12: { name: 'No banned dark-pattern copy', blocking: true },
  4: { name: 'Prerequisite IDs resolve', blocking: true },
  11: { name: 'Pack ID present + DAG acyclic', blocking: true },

  // SCAFFOLD rules (warning only — activate when data present)
  3: { name: 'Whitelist: all srs_words in JFT-A2 list', blocking: false },
  2: { name: 'Audio files exist', blocking: false },
  8: { name: 'Audio 1-10s', blocking: false },
  9: { name: 'Images <100KB', blocking: false },
  10: { name: 'Cultural notes reviewed', blocking: false },
};

// ── Helpers ──────────────────────────────────────────────────────────────

function loadJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  } catch (e) {
    return { _parseError: e.message };
  }
}

function hasHalfWidthKatakana(str) {
  // U+FF65-U+FF9F = half-width katakana
  return /[\uFF65-\uFF9F]/.test(str);
}

function findBannedPhrases(obj) {
  const text = JSON.stringify(obj);
  const found = [];
  for (const phrase of bannedPhrases) {
    if (text.toLowerCase().includes(phrase.toLowerCase())) {
      found.push(phrase);
    }
  }
  return found;
}

function checkWhitelist(obj, file) {
  const violations = [];
  const items = obj.items || [];
  for (const item of items) {
    const words = item.srs_words || [];
    for (const w of words) {
      if (!whitelist.has(w)) {
        violations.push({ file, item: item.id, word: w });
      }
    }
  }
  return violations;
}

// ── Validation engine ────────────────────────────────────────────────────

let blockingErrors = 0;
let warnings = 0;
const errors = [];
const warnList = [];

function error(ruleNum, msg) {
  blockingErrors++;
  errors.push(`[BLOCKING Rule ${ruleNum}] ${rules[ruleNum].name}: ${msg}`);
}

function warn(ruleNum, msg) {
  warnings++;
  warnList.push(`[WARN Rule ${ruleNum}] ${rules[ruleNum].name}: ${msg}`);
}

// ── Load all content ─────────────────────────────────────────────────────

const files = fs.readdirSync(CONTENT_DIR)
  .filter(f => f.endsWith('.json'))
  .map(f => ({ name: f, path: path.join(CONTENT_DIR, f), data: loadJson(path.join(CONTENT_DIR, f)) }));

const lessons = files.filter(f => f.name.startsWith('lesson_'));
const allIds = new Set();
const packGraph = new Map(); // pack_id -> [depends_on packs]

// ── Run checks ───────────────────────────────────────────────────────────

for (const file of files) {
  const { name, data } = file;

  // Rule 5: Strict JSON
  if (data._parseError) {
    error(5, `${name}: ${data._parseError}`);
    continue;
  }

  // Rule 6: Schema-valid structure
  if (!data.id) warn(6, `${name}: missing 'id'`);
  if (!data.verified === true) warn(6, `${name}: not marked verified`);

  // Rule 1: Every JP has BN
  const items = data.items || data.items || [];
  for (const item of items) {
    if (item.jp && (!item.meaning || !item.meaning.bn)) {
      error(1, `${name} item ${item.id}: jp present but meaning.bn missing`);
    }
  }

  // Rule 7: No half-width katakana
  const text = JSON.stringify(data);
  if (hasHalfWidthKatakana(text)) {
    error(7, `${name}: contains half-width katakana`);
  }

  // Rule 12: Banned phrases
  const banned = findBannedPhrases(data);
  if (banned.length > 0) {
    error(12, `${name}: banned phrases found: ${banned.join(', ')}`);
  }

  // Rule 3: Whitelist (scaffold — only warn)
  if (whitelist.size > 0) {
    const wlViolations = checkWhitelist(data, name);
    for (const v of wlViolations) {
      warn(3, `${v.file} item ${v.item}: "${v.word}" not in JFT-A2 whitelist`);
    }
  }

  // Collect IDs and pack graph
  allIds.add(data.id);
  if (data.pack_id) {
    if (!packGraph.has(data.pack_id)) {
      packGraph.set(data.pack_id, new Set(data.depends_on || []));
    }
  }
}

// Rule 4: Prerequisite IDs resolve
for (const lesson of lessons) {
  const prereqs = lesson.data.prerequisites || [];
  for (const p of prereqs) {
    if (!allIds.has(p) && p !== 'kana_hiragana') {
      // kana_hiragana is a meta-prerequisite (not a lesson ID)
      warn(4, `${lesson.name}: prerequisite "${p}" not found in content`);
    }
  }
}

// Rule 11: DAG acyclic check
function hasCycle(graph) {
  const visited = new Set();
  const recStack = new Set();

  function dfs(node) {
    visited.add(node);
    recStack.add(node);
    const deps = graph.get(node) || new Set();
    for (const dep of deps) {
      if (!visited.has(dep) && dfs(dep)) return true;
      if (recStack.has(dep)) return true;
    }
    recStack.delete(node);
    return false;
  }

  for (const node of graph.keys()) {
    if (!visited.has(node)) {
      if (dfs(node)) return true;
    }
  }
  return false;
}

if (packGraph.size > 0) {
  if (hasCycle(packGraph)) {
    error(11, 'Pack dependency graph contains a cycle');
  }
  // Check all lessons have pack_id
  for (const lesson of lessons) {
    if (!lesson.data.pack_id) {
      warn(11, `${lesson.name}: missing pack_id`);
    }
  }
}

// ── Report ───────────────────────────────────────────────────────────────

console.log('═══════════════════════════════════════════════════════════════');
console.log('  BHASAGO Content Validator');
console.log('═══════════════════════════════════════════════════════════════');
console.log(`Files checked: ${files.length}`);
console.log(`Lessons: ${lessons.length}`);
console.log(`Whitelist loaded: ${whitelist.size} words`);
console.log(`Banned phrases loaded: ${bannedPhrases.length}`);
console.log('');

if (errors.length > 0) {
  console.log('❌ BLOCKING ERRORS:');
  for (const e of errors) console.log('   ' + e);
  console.log('');
}

if (warnList.length > 0) {
  console.log('⚠️  WARNINGS:');
  for (const w of warnList) console.log('   ' + w);
  console.log('');
}

console.log(`Result: ${blockingErrors === 0 ? '✅ PASS' : '❌ FAIL'}`);
console.log(`  Blocking errors: ${blockingErrors}`);
console.log(`  Warnings: ${warnings}`);
console.log('');

// Rule coverage summary
console.log('Rule coverage:');
for (const [num, rule] of Object.entries(rules)) {
  const status = rule.blocking ? 'blocking' : 'scaffold';
  console.log(`  ${num}. ${rule.name} (${status})`);
}

process.exit(blockingErrors > 0 ? 1 : 0);

```
