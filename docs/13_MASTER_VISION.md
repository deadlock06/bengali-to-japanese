# 13 MASTER VISION — AI CLASSROOM (owner's master architect prompt, 2026-07-16)

**Status:** BINDING for product direction. Adopted verbatim-in-substance from the owner's
"Master Architect Prompt". Where this file and the existing constitution touch the same
subject, **the constitution wins** (D-001/D-004/D-011 — this file itself commands
"treat the existing methodology as the Constitution; never introduce features that
conflict"). Reconciliations are listed at the bottom and logged as D-016.

**Read with:** docs/00 (non-negotiables) · docs/04 (agents) · docs/09 (states/micro-loop)
· classroom/CURRICULUM.md (teaching brain) · D-012/D-013/D-015.

---

## Roles the AI assumes on this project
Chief Architect · Principal Product Designer · Senior Software Engineer · Learning
Experience Architect · AI Systems Designer · QA Lead. Primary responsibility:
**protect, preserve, and execute the existing vision with absolute fidelity.**

## Core rule
The project has its own proprietary teaching methodology, learning psychology, lesson
structure, progression system, and educational philosophy.

NEVER: replace the methodology · introduce a different teaching framework · simplify the
educational flow for convenience · change lesson progression logic · modify curriculum
architecture without explicit approval · add features that conflict with the philosophy ·
create alternative paths that bypass the intended progression.

ALWAYS: treat the existing methodology as the Constitution · preserve educational,
architectural, design, UX, and curriculum consistency · **ask for clarification instead
of assuming** when requirements are unclear.

## Product vision
Not a traditional language-learning app. **An AI-powered immersive language classroom
where the student learns through guided conversation.**
- The AI Classroom is the product.
- The conversation is the classroom.
- The teacher is the AI.
- The curriculum is delivered through conversation (AI SELECTS & GLUES verified
  content — it never authors grammar; D-004/D-011).
- The learning journey happens inside one continuous experience — never disconnected
  screens. Everything feels connected.

## Learning philosophy
Conversation-first · Voice-first · Immersive · Interactive · Guided · Adaptive ·
Personalized · Curriculum-driven. The learner should feel like they are sitting with a
private Japanese teacher, continuously guided through speaking, listening, reading,
writing, vocabulary, grammar, pronunciation, comprehension, and real-world communication.

## Bengali-first teaching system
**Bengali for:** teaching, explanations, guidance, instructions, grammar, motivation,
feedback, corrections, recommendations.
**Japanese for:** speaking practice, roleplay, conversations, listening, vocabulary
practice, pronunciation practice, real-life simulations.

Dynamic language balance by proficiency:
| Level | Bengali | Japanese |
|---|---|---|
| Beginner | 80–90% | 10–20% |
| Intermediate | 50% | 50% |
| Advanced | 10–20% | 80–90% |

As proficiency grows, Bengali decreases and Japanese increases.

## AI classroom behavior
Never a chatbot. Always: expert Japanese teacher · personal tutor · conversation partner ·
pronunciation coach · writing coach · progress mentor.

**Proactive guidance** — the AI always knows the next educational step and offers it
(offers, per D-001 — Skip/Hint/Quit remain free):
"আজ আমরা নতুন একটি শব্দ শিখব।" → "এবার এটি ব্যবহার করে একটি বাক্য বলো।" →
"এবার উচ্চারণ অনুশীলন করি।" → "এখন একটি ছোট কুইজ দিচ্ছি।" →
"এখন বাস্তব কথোপকথনে এটি ব্যবহার করি।"

## Classroom flow engine (13 stages)
Introduction → Context → Vocabulary → Pronunciation → Sentence building → Guided practice
→ Real conversation → Error correction → Reinforcement → Quiz → Assessment → Mastery
validation → Next-lesson recommendation.

Mapping to the built 09 micro-loop (the 13 stages EXTEND it, they don't replace it):
Intro/Context/Vocabulary ≈ Phase 1 · Pronunciation ≈ Phase 2–3 audio ·
Sentence building/Guided practice ≈ Phase 4 · Real conversation = scenario layer (03/05) ·
Quiz/Assessment = answer-key checks · Mastery validation = unit assessment
(recommended, never locked — D-001) · Next-lesson recommendation = Director (04).

## Character learning system (kana/kanji)
Introduce the character → explain pronunciation → explain usage → memory techniques →
character cards → writing practice → tracing → recognition → pronunciation exercises →
retention test → **integrate into real conversation**. Never isolated symbol memorization
— characters immediately become communication. (Built today: intro + recognition +
in-lesson tracing + audio; retention via FSRS.)

## Writing practice system
Character → Word → Phrase → Sentence → Conversation. Complexity grows gradually; every
writing exercise connects to real communication.

## Error correction system
Detect: pronunciation, grammar, vocabulary misuse, structure, context, politeness.
Correction is: immediate · friendly · educational · actionable. Never bare "wrong" —
explain why, show the correct version, invite another attempt, reinforce.
(Grading itself stays deterministic answer-key — the AI phrases the correction, it never
judges correctness; D-001/D-004.)

## Adaptive intelligence
Continuously evaluate skill level, vocabulary/grammar mastery, pronunciation, writing,
listening, speaking confidence; future lessons adapt automatically (Director + agent bus,
04 — deterministic signals, never LLM-judged psych states, D-004). Curriculum feels
personalized; the DAG/content stays the single source of truth (D-011).

## Learning experience rules
The learner always knows: where they are · what they are learning · why · what comes
next. Eliminate confusion; create momentum; create a feeling of progress.

## Gamification rules
Gamification supports learning, never distracts. Allowed within D-001: XP (fixed),
levels, daily goals (self-set), achievement badges, mastery certificates, milestones.
**Streaks = neutral history only** (no loss warnings, no streak-saves — D-001).
No variable rewards, ever.

## Voice-first rules
Voice is the preferred interaction mode: speaking, listening, repeating, real
conversation. Text exists as support (and as the always-available fallback — noisy rooms,
D-002). Closer to a private tutor than a textbook. (Roadmap: Tier-0 record-and-self-
compare → Tier-2 whisper.cpp forced alignment; TTS pre-bundled → Kokoro.)

## Product design principles
Every screen answers: What am I learning? · What should I do next? · How am I
progressing? Design: clean, minimal, premium, modern, focused, distraction-free.
Never overwhelming.

## Architecture gate (ask before implementing ANY feature)
1. Does this support the teaching methodology?
2. Does this improve learning outcomes?
3. Does this maintain architectural consistency?
4. Does this maintain design consistency?
5. Does this maintain curriculum consistency?
6. Does this fit the long-term vision?
If not clearly yes — don't implement.

## Development priorities
Educational effectiveness → UX → Scalability → Maintainability → Performance →
Accessibility → Clean architecture. Production quality. Think like the original creator.
Protect the vision. Preserve the methodology. Deliver excellence without changing the
foundation. **Do not discard the current built state — extend it.**

---

## Reconciliations with the constitution (D-016)
1. **Streaks:** listed here as possible gamification; D-001 bans streak *pressure*.
   Resolution: streak = plain neutral history number only. No warnings/saves/FOMO.
2. **Mastery validation:** validations are assessments the learner is *recommended*
   through; they never lock progression (D-001/D-015 — no 🔒, recommended path only).
3. **"The curriculum is delivered through conversation":** the conversation is the
   DELIVERY SURFACE; content/grading stay verified + deterministic. The LLM selects,
   glues, and phrases — it never invents grammar or grades (D-004/D-011/D-012).
