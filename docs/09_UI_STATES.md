# 09 UI STATES — Design System & Psych-State Screens
<!-- READ WHEN: building screens, copy, animations, accessibility. DEPENDS: 00,01,04. ~1.5K tokens -->

## Design system
Fonts: Noto Sans Bengali (BN) · Noto Sans JP (JP) · Roboto fallback. Scale 12/14/16/20/24px.
Spacing: 8px base · card pad 16 · screen margin 24 · buttons ≥48px · inputs 56px.
Accessibility (blocking): contrast ≥4.5:1 · touch ≥48×48dp · full screen-reader labels · reduced-motion mode kills all animation · high-contrast mode.

## Invariant across ALL states (constitution rule — see 01)
`[Skip] [Hint] [Quit/Back]` visible and enabled in every learning screen, every state, ≤1 tap. Streak shown as plain history number, no warnings. No auto-advancing prompts.

## FLOW (optimal challenge) — accuracy 70–85%, engaged, <20min, no fatigue
Colors #00C853/#00E676, animated green→teal gradient (15s cycle). Bold 1.1× type. 200ms ease-out transitions. Correct = 440Hz major chime; upbeat 90BPM instrumental. Progress bar glows; XP numeric roll. Toast "দারুণ চলছে!" auto-dismiss 1.5s. Continuation prompt: neutral "আরেকটা?" (no urgency copy). Difficulty +1 step; scaffolding reduced.

## STRUGGLE — accuracy <60%, rising errors, hesitation >3s
Colors #FF6D00/#FFAB00, static warm gradient (no motion = less load). Regular type, 400ms ease. Calm 60BPM acoustic; correct = soft xylophone; wrong = brief low woodblock (non-punishing). Hint button large, central, glowing, pre-expanded at bottom. Difficulty −1 with "চলো একসাথে ঝালাই করি।" Session ends on learner's choice, ideally on a win.

## BURNOUT — tap speed <50% baseline, random taps, session >40min
Colors #2979FF/#0D47A1, solid, zero animation. Soft light-gray-on-blue type. Low ambient rain/ocean. Overlay: "তোমার মস্তিষ্ক ক্লান্ত। ৪০ মিনিটের পর ধারণক্ষমতা কমে যায়।" + "Recommended break: 5:00".
Buttons: **[বিরতি নিন] (recommended)** and **[আমি ঠিক আছি, চালিয়ে যাই] (always enabled)**. Continue → easy review only, difficulty floor. Back button stays fully functional (old "visually disabled Back" is banned).

## BOREDOM — accuracy >90%, autopilot, >20min
Colors #AA00FF/#E040FB, floating-particle background, rounded playful type, 150ms bounce, playful synth. "Challenge unlocked!" flash. Extra button appears: [চ্যালেঞ্জ নিন] → optional high-difficulty drill. Skip remains its own button (never repurposed).

## Transitions
Flow→Struggle: 5s color crossfade + music crossfade · Struggle→Burnout: hard cut to blue, soft flash · Flow→Boredom: purple particles fade in, pitch-shift up · Burnout→any: learner's choice; break → home screen.

## Core lesson micro-loop (every lesson)
1. **Intro** 30s — target word/phrase, meaning, sample sentence, all Bengali. 2. **Recognition** 30s — audio→meaning or text→audio MC. 3. **Production** 60s — speak (Tier 2+: aligned scoring; Tier 0–1: record & self-compare) or finger-write kana; hint/skip/switch-type always offered. 4. **Context** 60s — word-block sentence build or gap-fill; wrong placement = visual cue, never "failure". 5. **SRS** — schedule via FSRS (08).

## Scenario mode UX
NPC consistent personality + memory of past runs; keigo level per character; exit button persistent; on struggle → Scaffold offers word list/hints (04); errors logged for Feedback agent.

## Session-cap & break UX (implements 01 policy)
20-min mark: dismissible banner "৫ মিনিটের বিরতি নিলে ভালো হয়" · 120-min mark: full-screen recommendation + [Easy review only] + [Continue anyway] + [Stop for today]. Parental mode: same screens but Continue requires guardian PIN.
