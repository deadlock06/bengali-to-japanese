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
