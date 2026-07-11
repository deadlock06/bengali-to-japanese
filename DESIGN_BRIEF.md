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

## 2. Design next — priority order (v2, owner's direction 2026-07-11)
The Learn experience is being re-architected as **goal-based journey maps +
AI classrooms** (proposed D-015 in 99_DECISIONS.md). Design these in order:

1. **Goal select (onboarding step 2)** — after language: "তুমি কেন শিখছ?"
   Three goal cards: SSW কাজের ভিসা / JLPT পরীক্ষা / জাপানে দৈনন্দিন জীবন.
   Picks the map; changeable later in Settings, never locked in.
2. **Journey map (Learn tab)** — a stylized Japan map per goal. Regions =
   content packs (airport/greetings → neighborhood/konbini → city/transport →
   clinic/emergency → workplace). Nodes = lessons/scenarios. Director's
   recommended path is drawn; **every node stays tappable** — a hard one just
   says neutrally "এটা এখনো কঠিন হতে পারে". Progress = regions filling in +
   passport stamps at FIXED milestones (10 lessons / 50 retained words —
   never random rewards). SSW map surfaces work regions early; study map
   goes deeper into reading/writing; life map leads with daily scenarios.
3. **AI Classroom (lesson player)** — each node opens a staged classroom
   scene: the Persona teacher avatar runs the 5-phase micro-loop (intro →
   recognition → production → context → SRS). The agent state bus drives the
   staging continuously: FLOW = warm, gently animated room (green family) ·
   STRUGGLE = motion stops, teacher steps closer, hint ladder slides up ·
   BURNOUT = lights dim, teacher recommends a break (both buttons enabled) ·
   BOREDOM = challenge door appears. Skip/Hint/Quit = fixed toolbar, always
   visible. Design ONE classroom scene + all four state variants first.
4. **Speak tab** (ShadowingScreen + Pitch entry card) — can be a classroom
   "conversation corner" scene.
5. **Review** — pink family; neutral "N cards due" framing; could be the
   classroom's "notebook" scene.
6. **Kana grid + Writing practice** — square canvas adapts to shorter axis
   (D-013); could be the classroom's "blackboard" scene.
7. **Settings + data autonomy** — locale, goal, persona picker, export ZIP,
   delete w/ 7-day grace, KanjiVG attribution.
8. **State pack** — loading / empty / error / offline for every screen
   (offline is NORMAL, not an error).

Animation budget (hard): Tecno-class devices, battery <15%/hr, reduced-motion
mode must kill ALL animation (accessibility gate). Vector/state-driven tweens
only — no video backgrounds, no particle storms. All assets ship offline.

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
