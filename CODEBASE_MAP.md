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
