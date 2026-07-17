# 📏 PROJECT SCALE — the master completion tracker (single source of "how far are we")

`Created 2026-07-16 (D-019). This file + tools/progress_scale.mjs ARE the project's
memory of remaining work. Every session: run the scale first, work the NEXT step,
tick it, re-run the scale, update CODEBASE_MAP + NEXT_SESSION.`

## How to use (the loop that keeps nothing broken)
```
node tools/progress_scale.mjs          # scoreboard: % per pillar + next step
node tools/progress_scale.mjs --gate   # FULL gate (flutter analyze+test too) — run before AND after every step
```
1. Run the scale → it names the **next unblocked step**.
2. Do ONLY that step. 3. Run `--gate` → must be all green.
4. Tick the checkbox here, update `CODEBASE_MAP.md` (+ `NEXT_SESSION.md` at session end).
5. Commit. Repeat.

**Rules:** one step at a time · never start a step whose `needs:` isn't done ·
gate green before ticking · content follows the ≤8-items-per-lesson rule ·
constitution (docs/00, D-001) outranks everything · spec-silent choice → log D-xxx.

Automated metrics (content %, audio, kana, book sync, proofs) are computed by the
script — checkboxes below are for the steps the machine can't measure.

---

## PHASE A — CONTENT to beta target (biggest lever)
- [x] **A1 · A1/A2 vocab to ladder targets (772)** — DONE 2026-07-16: every L0/A1/A2
      unit ≥ target (466 items, 55 lessons, 596 audio clips, book synced). Remaining
      772-gap is entirely N4 (steps A2/A3). _needs: —_ · size L
- [x] **A2 · N4 whitelist** — DONE 2026-07-17: `content_factory/n4_whitelist.txt`
      (1402 words = full JFT-A2 superset + curated standard JLPT-N4 core); validator
      now level-scoped (N4-tagged lessons check n4, others jft_a2). _needs: —_ · size M
- [x] **A3 · N4.1–N4.5 content** — DONE 2026-07-17: all 5 N4 units complete (33
      lessons, 248 items: te-form/plain+casual/potential/give-receive/keigo incl.
      uchi-soto rules). Ladder 806/772 = 104%. _needs: A2_ · size L
- [ ] **A4 · Mock-exam engine + A2.M/N4.M** — CBT-format mock (timer, 4 sections,
      answer-key scoring, honest band estimate). _needs: A1_ · size L
- [ ] **A5 · Native-speaker review pass** — human-gated; mark reviewed lessons in JSON
      (`reviewed_by`). BLOCKS PUBLISH. _needs: A1 (rolling)_ · size M-human

## PHASE B — PRACTICE completion (the 5-phase loop, then some)
- [ ] **B1 · Vocab Phase-4: word-block sentence building** — deterministic blocks from
      verified items (srs_words order), classroom step after Recognition for phrases.
      _needs: —_ · size M
- [ ] **B2 · Vocab Phase-3: say-it (Tier-0)** — record → replay next to native clip →
      self-compare (NO scoring without STT; D-002). `record` package. _needs: —_ · size M
- [ ] **B3 · Kana completion** — yōon (きゃ…), sokuon っ, long-vowel ー recognition
      (+audio); katakana name-builder drill. _needs: —_ · size M

## PHASE C — VISION surfaces
- [ ] **C1 · Goal-select onboarding + journey-map Learn tab** — SSW/JLPT/daily-life goal
      → Japan-map journey over the SAME DAG (D-015; design-first per DESIGN_HANDOFF).
      _needs: —_ · size L
- [ ] **C2 · Scenario/roleplay mode** — scripted dialogue trees (verified, 05 schema),
      sensei plays the other role; entry from classroom stage 7. _needs: A1_ · size L
- [ ] **C3 · State packs + Review/Speak v4 restyle** — loading/empty/error/offline for
      every screen; v0.1 screens to Bold Ink. _needs: —_ · size M

## PHASE D — PLATFORM
- [ ] **D1 · Sync client** — supabase_flutter + anonymous auth + SyncService (delta,
      device-wins, offline queue) + Settings opt-in toggle. Schema is LIVE (D-018).
      _needs: OWNER: anon key_ · size M
- [ ] **D2 · APK on real device** — Android SDK on owner's machine, release build,
      TECNO smoke test, perf/battery/thermal benchmarks (02 targets). _needs: OWNER: machine_ · size M
- [ ] **D3 · Content packs / tiered download** — split bundle per 03 (base APK ≤ target,
      packs downloadable; manifest endpoint). _needs: A1_ · size L
- [ ] **D4 · Offline LLM spike → integrate** — llama.cpp + Qwen3 1.7B Q4 via
      MethodChannel; GBNF + whitelist enforcer; >8 tok/s gate (T-000). THE long pole.
      _needs: D2_ · size XL
- [ ] **D5 · STT Tier-2** — whisper.cpp forced alignment vs known target (D-002),
      pronunciation scoring in Phase-3. _needs: D4 (native toolchain)_ · size L

## PHASE E — LAUNCH
- [ ] **E1 · Privacy policy in-app** (Bengali-first, plain language) + consent flows.
      _needs: D1_ · size S
- [ ] **E2 · Payments/tiers** (12_BUSINESS: free core + Pro; no dark patterns).
      _needs: D2_ · size L
- [ ] **E3 · UAT with real SSW-track learners** + fixes. _needs: A1,B1,D2_ · size M-human
- [ ] **E4 · Store submission** (Play data-safety, listing bn/en). _needs: E1,E3_ · size M

## OWNER-ONLY standing items (nothing ships until these)
- [ ] Rotate Supabase DB password (posted in chat 2026-07-16)
- [ ] Revoke the exposed OpenAI key (posted in chat earlier)
- [ ] `git push origin main` from a credentialed machine
- [ ] Provide Supabase **anon key** (unblocks D1)

---
_Automated pillar percentages live in the script output — do not hand-edit numbers
here. History of WHY: docs/99_DECISIONS.md. What exists: CODEBASE_MAP.md._
