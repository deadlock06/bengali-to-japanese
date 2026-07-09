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
