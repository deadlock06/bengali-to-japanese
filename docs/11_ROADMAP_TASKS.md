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
