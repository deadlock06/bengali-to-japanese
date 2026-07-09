# SENSEI v1.1 — Architecture Revision

**Purpose of this document:** Your v1.0 spec is engineered well. This revision keeps that engineering and changes the *mission-critical layers* to match the real goal you stated:

> Teach a Bangladeshi worker/student — often with near-zero Japanese — enough correct Japanese to **pass the exam required to work in Japan**, including **accent/pronunciation**, and **never teach wrong Japanese**.

It is written as a changelog against v1.0. Anything not mentioned here (device analysis, llama.cpp/whisper.cpp integration, FSRS engine, DB schema, thermal management, download manager) stays as-is.

---

## 0. The single biggest change: the target

v1.0 aimed at a "Year 2+ → JLPT N1 → business Japanese" ladder. That is the wrong target for your users and quietly triples your scope.

**The real target that gets a worker to Japan (SSW / 特定技能 "Specified Skilled Worker" visa):**

| User's target sector | Required Japanese test | Level | Where / frequency |
|---|---|---|---|
| Manufacturing, construction, agriculture, industrial cleaning, food/drink manufacturing, etc. (most workers) | **JFT-Basic** (Japan Foundation Test for Basic Japanese) | **A2**, pass mark **200 points** | Dhaka, CBT, ~6×/year, **same-day result** |
| Caregiving, food service, hospitality | **JLPT N4** | N4 | Twice yearly, result in ~2 months |

Both routes also require an industry **skills test**, but that is outside the language app's scope.

**Decision for v1:**
- **Primary track = JFT-Basic A2.** Faster, more frequent, same-day results, and it is a *practical everyday-communication* test — exactly your audience.
- **Secondary track = JLPT N4**, selectable for care/food/hospitality users.
- **Cut from v1 scope:** N3, N2, N1, business Japanese, dialects, "Year 2+ mastery." Add them later as content packs if the app succeeds. Shipping a focused A2/N4 app that actually gets people to Japan beats a half-built N1 ladder.

### Anchor all content on *Irodori* (this is the key unlock)

The Japan Foundation publishes a **free** coursebook, **"Irodori: Japanese for Life in Japan,"** built around the exact "Can-do" real-life tasks that JFT-Basic tests, **with native-recorded audio**. Levels: Starter (A1) → Elementary 1 & 2 (A2).

Using Irodori's Can-do list as your syllabus spine solves three problems at once:
1. **Exam alignment** — you are teaching precisely what is tested.
2. **Correctness** — you start from authoritative, verified material instead of model-generated content.
3. **Accent** — you get free native audio for every core sentence.

> Action: verify the current Irodori content licence for redistribution inside an app; at minimum you can align your own authored content to its Can-do structure, and link learners to the official audio.

---

## 1. Correctness architecture — "never teach wrong Japanese"

This is a hard constraint, and it is **architectural, not a prompt**. A 1.7B model *will* sometimes produce wrong Japanese or a wrong Bengali explanation. No system-prompt line ("never give incorrect grammar") can prevent that. So the design must guarantee the learner never *learns* from unverified output.

### Principle: Authored content is truth. The LLM is a conversation partner, never an authority.

**Two clearly separated content classes, visible in the UI:**

| Class | Source | Shown as | The learner should… |
|---|---|---|---|
| **Verified lesson content** | Pre-authored + human/expert-checked (Irodori-aligned, JLPT N4 lists; readings validated against **JMdict/JMdict-EDICT**) | ✅ "Verified" badge | Memorize / trust fully |
| **Practice conversation** | Live LLM output | 💬 "Practice mode" label | Use to build fluency, not to learn new facts |

### What the LLM is allowed to do (and not do)

**Allowed:**
- Drive branching **conversation practice** using only sanctioned vocabulary/patterns for the learner's current level.
- Encourage, vary phrasing, role-play scenario NPCs.
- **Surface** a pre-written Bengali explanation via retrieval (see below).

**Not allowed / removed:**
- ❌ Generating grammar rules or word readings on the fly as authoritative content.
- ❌ Being the judge of whether an exam-style answer is correct.
- ❌ Introducing vocabulary/kanji the learner hasn't been formally taught.

### Three mechanisms that enforce it

1. **Retrieval-grounded explanations (RAG over your own verified content).**
   When the learner asks "why が and not は here?", the app looks up the *authored* explanation for that grammar point and shows it. The model may *select/paraphrase lightly in Bengali* but the facts come from the verified store. If no authored explanation exists, the app says "let me note this — not yet covered," instead of inventing one.

2. **Grammar-constrained decoding (llama.cpp GBNF grammar).**
   In drills and structured turns, constrain the model so it can only emit sanctioned tokens/structures. This also fixes v1.0's fragile "must output 8 tags every turn" assumption — a 1.7B model won't reliably free-form that format, but a GBNF grammar *forces* it.

3. **Deterministic answer-checking for anything graded.**
   Exam items and drills have known correct answers (from the authored key). Check the learner's answer with **string/rule matching against the key**, never by asking the LLM "is this right?" Reserve model judgment for open conversation only — and even there, correct only against a whitelist of known patterns, framed gently.

### Where correctness is riskiest: correcting the *learner's* free output

A small model grading free-form learner Japanese will sometimes mark correct answers wrong (worse for morale) or wrong answers correct (worse for the exam). Mitigations:
- Keep **free conversation labelled as practice**, explicitly "I may not catch every mistake."
- For anything the learner should *rely on*, route them to a **structured drill** with a deterministic key.
- Log suspected mistakes to `grammar_mistakes` but only *surface* corrections that match an authored mistake-pattern entry with a verified explanation.

---

## 2. True-beginner onboarding (worker with ~zero Japanese)

v1.0 assumes a motivated self-learner. Many of your users start at zero and are studying after a workday. Adjust:

- **Sound & script before everything.** Hiragana → Katakana with audio, then straight into high-frequency **survival + workplace** phrases (greetings, numbers, days off, "I don't understand, please repeat," clinic, konbini). These are literally JFT-Basic Can-dos.
- **Bengali as scaffold, then fade it.** Bengali-first is right for *instructions and safety*, but for the target sentences, move from "Bengali + Japanese" → "Japanese with picture/context" as the learner progresses, so they stop leaning on translation.
- **Romaji as a training wheel with an expiry.** Show romaji only through the kana-learning phase, then turn it off automatically. Romaji that never goes away caps pronunciation and reading.
- **Short, finishable daily sessions** (10–15 min) with a clear "today's Can-do" — better for tired workers than open-ended chat.
- **Kanji: recognition only, minimal.** JFT-Basic/N4 need very limited kanji. Don't ship the 500-kanji stroke-order plan in v1; teach the small set the exam actually uses, recognition-first.

---

## 3. Accent & pronunciation engine (new Layer)

"Accent" in Japanese for a Bengali speaker means three things, in priority order for being *understood*:

1. **Mora timing & length** — long vs short vowels (おばさん vs おばあさん), っ (small tsu), ん as its own beat. Highest impact on intelligibility.
2. **Individual sounds** — つ, ら-row, ふ, devoiced vowels (です → "des"), which don't map cleanly from Bangla.
3. **Pitch accent (高低アクセント)** — 箸 vs 橋 vs 端 (hashi), 雨 vs 飴 (ame). Bangla has no lexical pitch, so this must be taught explicitly, not absorbed.

### Engine design

- **Native audio is the reference, not TTS.** Drop C-grade Kokoro as the pronunciation model for core content; use **Irodori's native recordings** (or your own native voice-actor recordings) for every target sentence. Keep TTS only for dynamic filler where accuracy doesn't matter — or drop it from the pronunciation path entirely.
- **Shadowing loop (the core drill):** play native line → learner repeats → **record learner** → play native + learner back-to-back for self-comparison. Shadowing + honest self-compare is the highest-return accent tool and needs no ML.
- **Pitch-accent visualization:** show the high/low contour line for each word/phrase (the way OJAD does), teach the 4 patterns (heiban / atamadaka / nakadaka / odaka), and drill **minimal pairs** as a mini-game.
- **Bengali-interference notes**, authored per sound: e.g. "খেয়াল রাখুন — জাপানিজে 'ু' ছোট, おばさন (khala) আর おばあさん (dadi/nani) আলাদা।"

### On-device pronunciation scoring — scope honestly

- **v1 (feasible):** extract the learner's **pitch (F0) contour** with an on-device algorithm (pYIN/YIN, or a tiny CREPE) and the **energy/duration envelope**; align to the reference and score *pitch-shape similarity* and *rhythm/timing*. This gives real, useful feedback ("your pitch went up where it should go down"; "your っ pause was too short").
- **v2 (hard, be realistic):** phoneme-level scoring ("was your つ correct?") needs forced alignment / an acoustic model offline — genuinely difficult on a Helio G99 with no NPU. Don't promise it in v1.

---

## 4. Latency & UX for the conversational core

v1.0's 12–18s response loop kills the fast back-and-forth that language practice needs, and tired workers won't wait.

- Make the **spine of the app pre-authored and instant** (lessons, drills, scenarios, shadowing). The LLM is the *occasional* enrichment, not on the critical path of every screen.
- When the LLM is used, **stream tokens** so the learner sees a response forming instead of an 18-second blank.
- Cache TTS/audio for all core content (already in v1.0 — keep it).

---

## 5. Revised roadmap (replaces v1.0 §19)

Keeps your phase structure; retargets content and adds correctness + accent. Note that **content authoring is the real bottleneck**, not the code — budget for it.

**Phase 1 — Foundation (Weeks 1–2):** Flutter project, DB schema, kana lessons with native audio, FSRS engine, Irodori-aligned content pipeline (JSON schema + a verified-content authoring/QA process).

**Phase 2 — Verified content core (Weeks 3–5):** Author + expert-check the JFT-Basic A2 Can-do units (survival + workplace scenarios), readings validated against JMdict. This is the heaviest phase. Build the "Verified vs Practice" content separation.

**Phase 3 — AI conversation, constrained (Weeks 6–7):** llama.cpp via FFI, **GBNF grammar-constrained** output, RAG retrieval over verified explanations, deterministic drill checking. Streaming UI.

**Phase 4 — Voice & accent (Weeks 8–9):** whisper.cpp STT, shadowing loop + record/playback, pitch-accent visualization, on-device F0/timing scoring (v1 tier), Bengali-interference notes.

**Phase 5 — Exam mode & launch (Weeks 10–12):** JFT-Basic **mock tests in real CBT format** (script/vocab, conversation & expression, listening, reading), progress dashboard tied to "exam readiness," JLPT N4 track toggle, beta test with 5–10 real candidates in Dhaka, polish.

Realistically **12 weeks**, with content authoring as the risk.

---

## 6. Smaller fixes

- It's **Tecno** Pova 4, not "Techno."
- v1.0's per-turn 8-tag output format → replace with GBNF-constrained structured output (see §1).
- Kokoro voice quality is C-grade **by your own table** — fine for filler, not for teaching accent.
- whisper-base Bengali accuracy is modest; keep confidence thresholds and a "type instead" fallback.
- Keep FSRS, but **hide the review queue inside the lesson/scenario flow** so it feels like progress, not homework.

---

## Summary of the shift

| | v1.0 | v1.1 |
|---|---|---|
| Target | JLPT N5→N1, fluency, business | **JFT-Basic A2** (+ JLPT N4 track) → SSW visa |
| Content source | AI-generated + some pre-built | **Verified, Irodori-aligned; AI never authoritative** |
| Correctness | "System prompt says be correct" | **Architectural: authored=truth, LLM constrained + retrieval-grounded + deterministic checking** |
| Pronunciation | Kokoro C-grade TTS | **Native audio + shadowing + pitch-accent + on-device pitch scoring** |
| LLM role | The tutor / source of truth | **Conversation partner only, clearly labelled** |
| Scope | 2+ years to N1 | **12 weeks to a shippable exam-prep app** |

Same solid engine. A soul that gets your users to Japan without ever teaching them a wrong sentence.
