# DESIGN BRIEF — Bhasago v4 "Bold Ink" (for the Claude design project)

Paste this file into the design project when starting the next design session.
Working model (owner's direction): **design the system first, then hand off —
code follows the design, never the other way.** The design project may
**re-architect any screen or component**, including ones already implemented;
nothing in the codebase is frozen. Every approved design ships as a
`*.dc.html` + a `HANDOFF.md` with ordered steps and exact repo destinations
(the v4 home handoff is the template — keep that format).

## 1. Where the design system stands (2026-07-10)
DESIGNED + IMPLEMENTED (from `Home v4.dc.html` handoff):
- Token set: ink-black surfaces `#0F0F0F/#1A1A1A/#242424`, outline `#2E2E2E`;
  accent inks yellow `#EFE94B` (current/primary), pink `#F06EB7` (review),
  blue `#4D7DF7` (AI/exam), green `#35E065` (progress); content on accents is
  always near-black `#111`; text `#F5F5F0` / dim `#8F8F8A`.
- Shape: cards 20px radius, buttons/chips stadium pills, bottom-nav active =
  white pill; type: Baloo Da 2 (BN+display), Zen Kaku Gothic New (JA),
  Archivo (Latin labels), Space Grotesk (numbers, optional).
- Screens: Home, first-run language onboarding, Progress (retention chart),
  AI-check (mock exam + Banglish suggestion), 4-tab shell
  (Home / Learn / Speak / Progress; Kana·Write·Settings push from Home AppBar).

NOT YET DESIGNED (running on old v0.1 styling inside the new theme):
Lesson player, Review (SRS), Learn tab (lesson list), Speak tab (shadowing),
Pitch, Kana grid, Writing practice, Settings/export/deletion, agent psych
strip, and all empty/error/offline states.

## 2. Design next — priority order
1. **Lesson player** (`lib/presentation/screens.dart` → LessonScreen) — the
   core loop: exercise card, answer states, agent psych strip + dismissible
   advice (persona voice), fixed rewards (10 XP/lesson). MUST keep visible,
   penalty-free **Skip / Hint / Quit** at all times (spec invariant).
2. **Speak tab** (ShadowingScreen) — record/playback vs reference audio,
   alignment-based score, text-input fallback always offered, **plus the
   Pitch entry card** (Pitch currently has no route in the v4 shell).
3. **Learn tab** (LessonListScreen) — lessons grouped by pack
   (basics ← daily ← work DAG), per-lesson progress, downloadable-pack
   affordance (03: tiered packs, P2P share).
4. **Review** (ReviewScreen) — SRS card flow in the pink family; neutral
   "N cards due today" framing (never guilt/streak pressure).
5. **Kana grid + Writing practice** — stroke-order playback, square canvas
   adapts to shorter axis (D-013 — don't design a fixed-portrait canvas).
6. **Settings + data autonomy** — locale, persona picker, one-tap export
   (ZIP), delete with 7-day grace, KanjiVG CC BY-SA attribution line.
7. **State pack** — loading / empty / error / offline / first-use for every
   screen above (offline is the NORMAL state, not an error).

## 3. Hard constraints (00_START_HERE non-negotiables — design MUST honor)
- **Recommend, never force**: no locks, no forced sessions; Skip/Hint/Quit
  everywhere; break suggestions are dismissible.
- **No dark patterns**: no variable rewards, streak-saves, guilt/FOMO copy;
  fail states neutral (D-001). Rewards predictable and mastery-based.
- **Offline-first**: no design may depend on connectivity; cloud = optional.
- **Correctness over generation**: "AI" UI must read as *examiner that grades
  from the answer key*; LLM only phrases feedback (Banglish OK).
- **Bengali-first**: BN is the default register everywhere; EN/JA secondary.
- **Data autonomy**: export/delete are first-class UI, not buried.
- Budget-phone target (Tecno Pova class): light effects only, no heavy blur/
  video backgrounds; tap targets ≥ 44px; contrast on accent fills uses `#111`.

## 4. Handoff format (repeat what worked)
- One `.dc.html` per screen/flow, mobile 390×844 frame, tokens from §1.
- `HANDOFF.md` with: design summary, files→destinations table, ordered steps
  (later steps may import earlier ones), spec-compliance checklist (call out
  D-001 + Skip/Hint/Quit explicitly), post-copy commands, open follow-ups,
  suggested commit message.
- Component naming: match existing Dart (`BhasagoColors.*`, screens in
  `lib/presentation/`, providers in `lib/app/providers.dart`).
- If a design re-architects an existing component, say so in HANDOFF.md
  ("replaces X, migrate Y") — the coding session will follow it.
