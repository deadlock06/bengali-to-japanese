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

## CURRICULUM LAYER (added 2026-07-11) — required fields on every lesson & card
`level` (L0|A1|A2|N4) · `can_do_id` (FK → curriculum.json) · `prerequisites[]` · `whitelist_ref` (jft_a2|n4) · `card_type` (recognition|production).
CI additions (T-104): enforce rule #3 whitelist (no learner-facing JP word outside `whitelist_ref`), rule #4 prerequisite IDs resolve, rule #11 pack dependency graph acyclic.
