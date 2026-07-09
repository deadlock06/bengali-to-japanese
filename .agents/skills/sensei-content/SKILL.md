---
name: sensei-content
description: >-
  Content authoring and validation skill for the SENSEI app. Activates when
  creating, editing, or validating lesson JSON, SRS cards, kana data, pitch
  accent pairs, vocabulary, or running validate_content.mjs. Also activates on:
  content, lesson, kana, hiragana, katakana, JSON schema, validate, arb files,
  JFT-Basic, JLPT, Can-do, konbini, pitch_accent.json, assets/content,
  content_factory, banned_phrases, pack_id.
---

# SENSEI Content Authoring Guide

## The golden rule
**The LLM selects and glues, never invents Japanese rules.**
All graded content → authored in JSON → validated by `validate_content.mjs`.
The on-device LLM only generates conversation, constrained by retrieved grammar.

## Content locations
| Path | What |
|---|---|
| `assets/content/hiragana.json` | 46 hiragana cards |
| `assets/content/katakana.json` | 46 katakana cards |
| `assets/content/lesson_konbini.json` | Can-do #1: convenience store |
| `assets/content/pitch_accent.json` | 6 Tokyo-dialect minimal pairs |
| `assets/stroke/kana_strokes.json` | KanjiVG stroke order (CC BY-SA) |
| `content_factory/banned_phrases.txt` | Banned dark-pattern copy |
| `content_factory/jft_a2_whitelist.txt` | JFT-A2 vocab whitelist (TODO: author) |

## JSON schema (lesson card)
```json
{
  "id": "unique-kebab-id",
  "pack_id": "jft-a2-konbini",
  "type": "vocabulary|kana|grammar|pitch",
  "ja": "日本語テキスト",
  "ja_reading": "にほんごてきすと",
  "bn": "বাংলা অনুবাদ",
  "en": "English gloss",
  "example_ja": "例文。",
  "example_bn": "উদাহরণ।",
  "tags": ["jft-a2", "konbini"],
  "verified": true,
  "source": "jft-official|author:<name>"
}
```

## Validator rules (blocking)
Run: `node tools/validate_content.mjs` — must pass before commit.

| # | Rule | Status |
|---|---|---|
| 1 | `verified: true` required on every card | Blocking |
| 5 | No half-width katakana (ｦｧ… U+FF65–FF9F) | Blocking |
| 6 | `type` must be in whitelist | Blocking |
| 7 | No banned phrases (see `content_factory/banned_phrases.txt`) | Blocking |
| 3 | Vocab must be in JFT-A2 whitelist (when whitelist exists) | Blocking* |
| 4 | Prereq pack_ids must exist | Blocking |
| 11 | `pack_id` required; dependency graph must be acyclic | Blocking |
| 2,8,9 | Audio/image file existence | Non-blocking (packs not yet shipped) |

*Rule 3 is non-blocking until `content_factory/jft_a2_whitelist.txt` is authored.

## Adding a new lesson pack
1. Create `assets/content/<pack_name>.json`
2. Add `"pack_id": "<unique-slug>"` to every card
3. Verify: `node tools/validate_content.mjs` — all blocking rules pass
4. Register pack in `lib/data/content_repository.dart` whitelist
5. Commit only after validator passes 0 blocking errors

## Pitch accent format
```json
{
  "id": "hashi-chopsticks",
  "pack_id": "pitch-accent-basics",
  "type": "pitch",
  "ja": "箸",
  "ja_reading": "はし",
  "pitch_pattern": "LH",
  "pitch_mora": 0,
  "minimal_pair_ja": "橋",
  "minimal_pair_reading": "はし",
  "minimal_pair_pitch": "HL",
  "bn": "চপস্টিক",
  "verified": true,
  "source": "nhk-accent-dict"
}
```

## Banned content (dark patterns — never author)
See `content_factory/banned_phrases.txt`. Key examples:
- Streak-save / streak-loss guilt ("Don't break your streak!")
- FOMO copy ("Limited time offer", "Others are ahead of you")
- Forced progression ("Complete this to unlock")
- Variable reward copy ("You might earn a bonus!")
- Any "speak or die", forced output, session lock

## Kana stroke data
Source: KanjiVG (CC BY-SA 3.0). Stroke points are scaled to 0..1000 space.
Attribution MUST appear in the app About screen (D-011).
Re-run: `node tools/fetch_stroke_data.mjs` (one-time; already committed).
