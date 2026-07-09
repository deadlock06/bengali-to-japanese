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
