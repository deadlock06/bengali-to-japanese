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
- [x] **A4 · Mock-exam engine + A2.M/N4.M** — DONE 2026-07-17: deterministic
      builder selects from the verified store (never invents); JFT 50Q/60min ×4
      real sections (incl. listening from bundled clips) + N4 39Q/50min ×3;
      recommend-only timer, honest band estimate, weakest-section advice;
      launched from the curriculum ladder (🎯 মক দাও), completion marks the unit
      done. Proven by test/mock_exam_test.dart. _needs: A1_ · size L
- [ ] **A5 · Native-speaker review pass** — HUMAN work (I can't fake it): a native
      JP speaker checks each file, adds `"reviewed_by":"<name>"`. TRACKER READY:
      `node tools/review_status.mjs` reports coverage % + pending files; publish
      blocked until 100%. Owner must arrange a reviewer. _needs: A1 (rolling)_ · size M-human

## PHASE B — PRACTICE completion (the 5-phase loop, then some)
- [x] **B1 · Vocab Phase-4: context practice** — DONE 2026-07-17 as boundary-guarded
      GAP-FILL (spec 09 allows 'word-block build or gap-fill'; kana word-splitting
      would teach wrong boundaries): sentence items with a known word at a particle
      boundary get a 'বাক্যটা পূরণ করো 🧩' step after Recognition — wrong pick =
      orange nudge + retry (never failure), skip free. 70+ sentences today, grows
      with vocab. Proven by test/gap_fill_test.dart. _needs: —_ · size M
- [x] **B2 · Vocab Phase-3: say-it (Tier-0)** — DONE 2026-07-17: after Recognition,
      every audio-backed vocab item gets 'এবার মুখে বলো 🎙️' — native 🔊 → record →
      'আমারটা' replay → self-compare ('তোমার কানই বিচারক, আমি নম্বর দিই না', D-002);
      no-mic surfaces degrade to say-aloud-3-times; skip free. Vocab loop now
      Intro→Recognition→SAY→Context→SRS. Proven by test/say_it_phase_test.dart.
      _needs: —_ · size M
- [x] **B3 · Kana completion** — DONE 2026-07-17: kana batch 71→106 per script —
      33 yōon (small ゃゅょ merge-rule taught: きや≠きゃ) + sokuon っ (きって demo:
      'থামাই অর্থ বদলায়') + long vowel (おかあさん/コーヒー) ×both scripts, 70 new
      audio clips (922 total); yōon get say-it practice via B2. Name-builder drill
      deferred to C-phase polish. Proven in kana_writing_phase_test. _needs: —_ · size M

## PHASE C — VISION surfaces
- [x] **C1 · Goal-select onboarding + journey-map Learn tab** — DONE 2026-07-17:
      onboarding step 2 asks the goal (SSW🏭/JLPT🎓/daily🗾, 'পথ একটাই, জোরটা বদলায়');
      Learn tab = winding Japan climb (Kyushu→torii ⛩️) over the SAME DAG — done=
      hanko 印 stamp, current=🔥, upcoming=neutral (no locks), mock=🎯; goal changes
      EMPHASIS/badge only (D-015); node sheet: can-do + honest CTA. Also fixed a
      long-hidden test-env DB hang (SrsLocal fail-fast). _needs: —_ · size L
- [x] **C2 · Scenario/roleplay mode** — DONE 2026-07-17: 3 scripted VERIFIED trees
      (🏪 konbini · 🩺 clinic · 💼 interview) — sensei plays the NPC (bundled audio
      per line), learner answers from taught choices only, any choice is fine
      (D-001), ending = celebration + restart free. Entry: Speak-tab 'conversation
      corner' card. Validator gained scenario-type graph-integrity checks (every
      choice resolves, ending reachable) — PASS. _needs: A1_ · size L
- [x] **C3 · State packs + Review/Speak v4 restyle** — DONE 2026-07-17: reusable
      `StatePack` (loading/empty/error/offline, Bengali-first, warm — offline
      reassures 'বাকি সব ইন্টারনেট ছাড়াই চলে'); Review screen fully restyled to
      Bold Ink (pink card, progress count, StatePack empty/done); Speak(pitch) +
      Progress tabs use StatePack loading. Proven by test/state_pack_test.dart.
      Remaining bare spinners are on non-nav v0.1 screens (old lesson/list) —
      logged for a later sweep. _needs: —_ · size M

## PHASE D — PLATFORM
- [x] **D1 · Sync client** — CODE DONE 2026-07-17: supabase_flutter wired
      (Supabase.initialize at startup, public anon key embedded); SyncService with
      anonymous auth + idempotent progress upsert (profiles + daily_stats, uses
      existing local counts) + Settings opt-in toggle (off by default, offline-
      first untouched, honest copy + 'সিঙ্ক করো'/last-synced). Graceful on every
      failure. ✅ ACTIVE 2026-07-17: owner enabled Anonymous sign-ins; full round-trip verified
      (sign-in → profile+srs_cards upsert → read-back → RLS isolation confirmed). Per-card srs_cards
      delta sync = next increment. _needs: OWNER: anon key ✓_ · size M
- [x] **D2 · APK on real device** — DONE 2026-07-18: `tools/build_apk.sh` installed the
      full toolchain (local JDK21 + Android SDK, flock/resume-safe); app-release.apk built,
      installed + smoke-tested on the owner's TECNO. Perf/battery/thermal benchmarks (02
      targets) remain an open follow-up. _needs: OWNER: machine ✓_ · size M
- [ ] **D3 · Content packs / tiered download** — split bundle per 03 (base APK ≤ target,
      packs downloadable; manifest endpoint). _needs: A1_ · size L
- [ ] **D4 · Offline LLM spike → integrate** — llama.cpp + Qwen3 1.7B Q4 via
      MethodChannel; GBNF + whitelist enforcer; >8 tok/s gate (T-000). THE long pole.
      _needs: D2_ · size XL
- [ ] **D5 · STT Tier-2** — whisper.cpp forced alignment vs known target (D-002),
      pronunciation scoring in Phase-3. _needs: D4 (native toolchain)_ · size L

## PHASE E — LAUNCH
- [x] **E1 · Privacy policy in-app** — DONE 2026-07-18: `privacy_screen.dart` (Bengali-first,
      plain-language, honest to actual practices) wired into Settings; consent = sync stays
      opt-in-off + AI use disclosed. Store data-safety form still due at E4. _needs: D1 ✓_ · size S
- [ ] **E2 · Payments/tiers** (12_BUSINESS: free core + Pro; no dark patterns).
      _needs: D2_ · size L
- [ ] **E3 · UAT with real SSW-track learners** + fixes. _needs: A1,B1,D2_ · size M-human
- [ ] **E4 · Store submission** (Play data-safety, listing bn/en). _needs: E1,E3_ · size M

## OWNER-ONLY standing items (nothing ships until these)
- [ ] Rotate Supabase DB password (posted in chat 2026-07-16)
- [ ] Revoke the exposed OpenAI key (posted in chat earlier)
- [x] `git push origin main` — DONE 2026-07-17 (67 commits, 60aedb1..a691953)
- [x] Provide Supabase **anon key** — DONE 2026-07-17 (embedded; public by design)
- [x] **Enable Anonymous sign-ins** in Supabase — DONE 2026-07-17 (D1 sync verified live)

---
_Automated pillar percentages live in the script output — do not hand-edit numbers
here. History of WHY: docs/99_DECISIONS.md. What exists: CODEBASE_MAP.md._
