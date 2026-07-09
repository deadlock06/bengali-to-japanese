---
name: sensei-flutter
description: >-
  Flutter/Dart coding skill for the SENSEI app. Activates when writing,
  reviewing, or debugging Dart/Flutter code — widgets, Riverpod providers,
  screens, navigation, l10n, unit tests, or any file under lib/ or test/.
  Also activates on: flutter, dart, riverpod, sqflite, widget test, pubspec,
  gen-l10n, Material, BilingualText, SrsLocal, screens.dart, migrations,
  db_key, SQLCipher, flutter_secure_storage.
---

# SENSEI Flutter/Dart Coding Guide

## Stack pinned versions
```yaml
flutter: ">=3.22.0"
dart: ">=3.3.0"
riverpod: ^2.x          # flutter_riverpod
sqflite_sqlcipher: ^2.x  # encrypted DB
flutter_secure_storage: ^9.x
fftea: ^1.x             # pitch/F0
```

## Architecture patterns
- **State:** Riverpod `AsyncNotifierProvider` for async, `NotifierProvider` for sync.
  Never use `StateProvider` for complex state.
- **Navigation:** GoRouter. Named routes only — no string paths hardcoded.
- **Localization:** `S.of(context).key` via `gen-l10n`. All user-visible strings must
  be in `.arb` files (`lib/l10n/app_{en,bn,ja}.arb`). Bengali-first.
- **BilingualText:** Use `Tri.lines()` for trilingual strings; `BilingualText` widget
  for BN + EN-gloss display. See `lib/domain/models.dart`.

## Core file map
| File | Role |
|---|---|
| `lib/main.dart` | App entry, locale switcher, ProviderScope, GoRouter shell |
| `lib/domain/models.dart` | Trilingual models, `Tri`, `BilingualText` |
| `lib/domain/fsrs.dart` | FSRS-4.5 scheduler (pure Dart, no Flutter dep) |
| `lib/domain/pitch.dart` | F0/pitch engine, `accentScore()` |
| `lib/data/content_repository.dart` | Loads verified JSON; rejects unverified |
| `lib/data/srs_local.dart` | `SrsLocal` DAO — SQLCipher + FSRS |
| `lib/db/db_key.dart` | Keystore-backed encryption key |
| `lib/db/migrations/` | Numbered immutable migrations |
| `lib/presentation/screens.dart` | Lesson, Review, Kana screens |
| `lib/presentation/accent_screens.dart` | PitchScreen, ShadowingScreen |
| `lib/presentation/widgets.dart` | Shared widgets incl. `BilingualText` |

## Coding rules
1. **Autonomy invariant:** Every lesson/review screen must show `[Skip]`, `[Pause]`, `[Quit]`
   — always visible, always enabled, ≤1 tap, zero penalty. Never auto-advance.
2. **Correctness gate:** Graded answers → deterministic key match only. Never ask
   the LLM if an answer is correct.
3. **Offline-first:** No `http` / `dio` calls in domain or data layer. All network
   is in separate sync adapters behind an abstraction.
4. **Bengali-first:** Default locale is `bn`. `S.of(context)` falls back to `en`.
5. **No dark patterns:** No streak counters that penalize breaks, no FOMO copy,
   no variable-reward mechanics.

## Device budget checks (add as assertions or doc comments)
```dart
// RAM: keep heap peak < 6.5 GB (profile with DevTools)
// Cold start: < 2s (measure with flutter run --profile)
// Battery: < 15%/hr (measure on Tecno Pova 4)
// LLM: > 8 tok/s on device (benchmark in 08_OFFLINE_AI)
```

## Running locally
```powershell
flutter pub get
flutter gen-l10n           # generates lib/l10n/app_localizations.dart
flutter analyze            # must be clean before committing
flutter test               # FSRS property tests + migration tests
flutter run                # needs Android device or emulator (minSdkVersion >= 23)
```

## Common gotchas
- **minSdkVersion must be ≥ 23** — required by both SQLCipher and flutter_secure_storage.
  Set in `android/app/build.gradle` when the `android/` folder is created.
- `SrsLocal` is not yet instantiated in `main.dart` — wire it via `ProviderScope` override.
- `flutter gen-l10n` must run before `flutter analyze` or you'll get missing class errors.
- KanjiVG stroke data is in `assets/stroke/kana_strokes.json` (CC BY-SA — attribution
  must appear in app About screen, per D-011).

## Writing migrations
```dart
// lib/db/migrations/m002_add_column.dart
// Rules:
// 1. Immutable — never edit a committed migration
// 2. Numbered sequentially (m001, m002, ...)
// 3. Register in lib/db/migrations/registry.dart
// 4. Add a proof: tools/migrations_reference.mjs test N/N pass
```
