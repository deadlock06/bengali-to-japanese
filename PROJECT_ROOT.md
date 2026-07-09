# SENSEI — single project directory

This folder is the whole project AND the Flutter app root (run `flutter` from here).

- `lib/ assets/ tools/ test/ pubspec.yaml` — the Flutter app
- `NEXT_SESSION.md` + `CODEBASE_MAP.md` — start here each session
- `docs/` — the v4.2 spec pack (00_START_HERE.md first)
- `prototypes/` — clickable HTML demos + planning docs (not part of the build)

First run: `node tools/fetch_stroke_data.mjs` (fills kana stroke data offline), then
`flutter pub get && flutter gen-l10n && flutter test && flutter run`.
