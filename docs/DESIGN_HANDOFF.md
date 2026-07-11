# SENSEI — Design & Build Handoff
<!-- READ WITH: docs/09_UI_STATES.md (design system + psych states), docs/01_CONSTITUTION.md (ethics),
     CURRICULUM_MAP.md (backbone). This turns the design into buildable specs. Stack: Flutter 3.22+, Riverpod, offline-first. -->

> Purpose: everything a coder (you + an AI) needs to implement each screen without guessing.
> Golden rule from 01_CONSTITUTION: **recommend, never force; no dark patterns; correctness over generation.**

---

## 0. How the curriculum drives the whole architecture (incl. AI)
The curriculum ontology (`assets/curriculum/curriculum.json`) is the **single source of truth**. Every layer reads from it:

| Layer | What it takes from the curriculum | Result |
|---|---|---|
| RAG store | can_do id + level tags on each verified note | retrieval scoped to learner level → higher accuracy |
| **LLM (on-device)** | per-level **whitelist** → GBNF grammar + whitelist enforcer | model *cannot* emit above-level or unverified words |
| LLM explanations | verified grammar notes (retrieved) | "selects & glues, never invents" is enforceable |
| Deterministic grader | can_do → answer keys | graded by string/key match, never LLM judgment |
| FSRS / SRS | per-level word lists + prerequisites | defines the deck + when a card first unlocks |
| Director agent | prerequisite graph | "what next?" is deterministic, not a guess |
| Feedback agent | mistake_pattern → remediation_lesson_id | targeted review, not random |
| Pack system | level → pack boundaries (acyclic graph, rule #11) | user downloads only the level they need |
| Content factory / LoRA | curriculum = authoring spec + held-out eval set | model defaults to level-correct Bengali-first output |

**One line:** the leveled curriculum is the *fence* around the small on-device AI — without it the AI is a liability; with it, it is a bounded, reliable tutor.

## 1. Data-model additions (add to lesson & card schema — see 05_CONTENT_SCHEMAS)
Every content item MUST carry these so the AI + validators can use it:
```
level            // "L0" | "A1" | "A2" | "N4"
can_do_id        // e.g. "A2.1"  (FK into curriculum.json)
prerequisites[]  // unit ids that must be mastered first
whitelist_ref    // "jft_a2" | "n4"
card_type        // "recognition" | "production"
```
CI (validate_content.mjs, T-104) must add: rule #3 whitelist check (no JP word outside `whitelist_ref`), rule #4 prerequisite resolution, rule #11 pack-graph acyclic.

## 2. Design tokens (canonical source: 09_UI_STATES)
Reconciliation note: the premium HTML prototype uses a coral→pink→violet gradient; the **spec (09) is canonical for shipping** because its palette encodes the 4 psychological states. Use 09's state palettes; the gradient may be reused ONLY on non-state surfaces (splash, onboarding) after a contrast check. Log the final call in 99_DECISIONS.

| Token | Value | Usage |
|---|---|---|
| `font-bn` | Noto Sans Bengali | all Bengali/Banglish text |
| `font-jp` | Noto Sans JP | all Japanese text |
| `type-scale` | 12 / 14 / 16 / 20 / 24 px | caption / body-sm / body / title / display |
| `space-base` | 8px | base rhythm unit |
| `space-card` | 16px | card padding |
| `space-screen` | 24px | screen margin |
| `radius-card` | 12px | cards |
| `radius-ctl` | 8px | buttons, inputs |
| `touch-min` | 48×48 dp | every tappable target (blocking) |
| `input-h` | 56px | text inputs |
| `flow` | #00C853 / #00E676 | FLOW state accents |
| `struggle` | #FF6D00 / #FFAB00 | STRUGGLE state |
| `burnout` | #2979FF / #0D47A1 | BURNOUT state |
| `boredom` | #AA00FF / #E040FB | BOREDOM state |
| `motion-flow` | 200ms ease-out | FLOW transitions |
| `motion-struggle` | 400ms ease | STRUGGLE transitions |
| `motion-reduced` | 0ms (none) | reduced-motion mode kills ALL animation |

Accessibility (blocking, from 09/01): contrast ≥ 4.5:1 · touch ≥ 48dp · full screen-reader labels · reduced-motion mode · high-contrast mode.

## 3. Global invariants (apply to EVERY screen — from 01/09)
- **`[Skip] [Hint] [Quit/Back]` visible and enabled in ≤1 tap in every learning state**, including Flow. Never hidden, never disabled.
- **Streak = plain history number.** No loss warnings, no streak-save purchase, no FOMO.
- **Continuation prompts are neutral** ("আরেকটা?" / "Continue?") — never "You were so close…".
- **Caps & breaks are recommendations** (20-min dismissible banner; 120-min full-screen recommend + [Easy review] / [Continue] / [Stop]). Parental mode is the ONLY firm cap.
- **Text expansion:** Bengali/Banglish and Japanese run longer than English — every label must wrap to 2 lines gracefully, never truncate meaning.

## 4. The 4 psychological states (drive theming per session — 09)
Detection is **deterministic (agents), never LLM** (D-004). UI reacts:
| State | Trigger | Palette | Motion | Key UI change |
|---|---|---|---|---|
| FLOW | 70–85% acc, <20min | `flow` | 200ms, gentle | difficulty +1, XP roll, neutral "আরেকটা?" |
| STRUGGLE | <60% acc, hesitation >3s | `struggle` | 400ms, calm, no bg motion | Hint pre-expanded & central; difficulty −1; end on a win |
| BURNOUT | tap speed <50% baseline, >40min | `burnout` | none | recommend break overlay: [বিরতি নিন](rec) / [চালিয়ে যাই](always on) |
| BOREDOM | >90% acc, autopilot | `boredom` | 150ms playful | optional [চ্যালেঞ্জ নিন] appears; Skip stays its own button |

---

# 5. Per-screen handoff specs
Each screen: Overview · Layout · Components · States/Interactions · Edge cases · Motion · A11y. Skip/Hint/Quit invariant applies to all learning screens (see §3).

## 5.1 Home / Dashboard
**Overview:** entry hub; shows current level, next Can-do to do, due reviews, path. Reads `curriculum.json` + progress.
**Layout:** scroll column, `space-screen` margins. Order: level+progress card → 3 stat chips → primary CTA → path list.
**Components:** `LevelProgressCard` (level name, % to next exam, honest Can-do count), `StatChip`×3 (streak=history, words, due), `PrimaryButton` "Continue" → next unauthored-safe unit, `UnitRow` list (icon, title BN, Can-do, progress dots, ✓/new/🔒 badge).
**States:** unit locked if prerequisites unmet → 🔒 + tap shows "আগে {prereq} শেষ করো" (recommend, not block-with-shame). Empty (new user) → "শুরু করো: হিরাগানা".
**Edge:** long BN titles wrap 2 lines. 0 due → chip shows 0, no red.
**Motion:** screen rise 200ms; progress ring animates once on load (respect reduced-motion).
**A11y:** each UnitRow is one focusable button with label "{title}, {status}"; ring has text alternative "৪১%".

## 5.2 Kana grid
**Overview:** learn/recognize hiragana & katakana; tap to hear.
**Layout:** SegmentedButton (ひらがな/カタカナ) → 5-col grid, `radius-ctl` tiles, `touch-min`.
**Components:** `CharTile` (char + romaji), `ScriptToggle`.
**States:** tap → highlight 220ms + play audio (offline TTS/recorded). Selected persists.
**Edge:** audio missing → silent + no error toast (offline tolerant).
**A11y:** tile label "{char}, {romaji}"; grid is a labelled list.

## 5.3 Writing (built — writing_screen.dart)
**Overview:** finger-write kana; watch offline stroke-order animation; trace guide.
**Layout:** script toggle → char strip → square `PracticePaper` (grid + faint guide) → tools row → Skip row.
**Components:** `PracticePaper` (CustomPainter: paper #FBFBFD, grid, guide glyph, ink, anim), `Toolbar` (watch/guide/undo/clear), `SkipBar`.
**States:** guide on/off; animating (input locked, shows pen tip); empty (undo/clear disabled).
**Edge:** char has no stroke data → hide Watch, keep tracing guide (never crash).
**Motion:** stroke draw 600ms/stroke; reduced-motion → jump to final glyph instantly.
**A11y:** Watch has label "Show stroke order for {char}"; canvas has description; all tools ≥48dp.

## 5.4 Lesson micro-loop (5 steps — build to spec 09)  ◐ needs building
**Overview:** the core teaching unit; 5 steps per Can-do. **Skip/Hint/Quit visible every step.**
**Layout:** step progress bar (5 dots) top; content center; action bar bottom.
**Steps/Components:**
1. **Intro (30s)** — `ExposureCard`: JP + furigana, `BilingualText` meaning, audio.
2. **Recognition (30s)** — `McCard`: audio→meaning (4 options), deterministic check.
3. **Production (60s)** — `ProduceCard`: speak (Tier2+ aligned score / Tier0-1 record+self-compare) OR finger-write; hint/skip/switch-type always offered.
4. **Context (60s)** — `SentenceBuild`: word-blocks with color coding (noun/particle/copula per 05); wrong placement = visual cue, **never "failure"**.
5. **SRS** — schedule via FSRS; no separate screen.
**States:** correct → FLOW chime + neutral advance; wrong → gentle cue, hint expands, no penalty; skip → next step, logged neutrally.
**Edge:** all-skip allowed (no lock). Long Bengali note scrolls within card.
**Motion:** step transitions 200ms; wrong-answer cue 400ms non-punishing.
**A11y:** MC options are radio group; SR announces "correct"/"try again"; color never sole signal (add icon).

## 5.5 Shadowing (built — accent_screens.dart)
**Overview:** listen → record → pitch score.
**Components:** `PlayNative`, `PitchMeter` (live F0), `RecordButton`, `ScoreDisplay` (0–100), `SkipBar`.
**States:** idle/recording(red dot)/scored. Mic denied → inline hint "Mic permission দরকার", text-input fallback.
**Edge:** no reference audio → hide score, keep listen+record. Noisy room → score still renders (alignment, not transcription — D-002).
**A11y:** record button label toggles "Record"/"Stop"; score has text "{n} out of 100, {verdict}".

## 5.6 Pitch accent (built)
**Overview:** minimal pairs, high/low line.
**Components:** `PitchPairCard` (kanji, reading, `BilingualText` meaning + type, `PitchLine` painter, play).
**Edge:** dialect label always shown ("Tokyo"). Reduced-motion: static line.
**A11y:** pitch pattern described in text ("high-low") not color/line alone.

## 5.7 Review (FSRS — built)
**Overview:** due-card review; ratings show real next interval.
**Components:** `ReviewCard` (word → reveal), `RatingRow` (Again/Hard/Good/Easy + interval), done state.
**States:** front/revealed/done. Rating persists via SrsLocal.applyReview.
**Edge:** 0 due → friendly done screen, no guilt. Rating is pure (D-003) — never mood-multiplied.
**Motion:** card flip 200ms; done confetti = predictable mastery reward (OK per 09), reduced-motion → none.
**A11y:** reveal button "Show answer"; ratings are 4 labelled buttons with interval read out.

---

# 6. Shared components (build once, reuse)
| Component | Props | States | Notes |
|---|---|---|---|
| `BilingualText` | tri{en,bn,ja}, lang | — | BN mode = BN line + dimmed EN gloss (built) |
| `PrimaryButton` | label, onTap, loading | default/press/loading/disabled | ≥48dp; press scale .97; loading spinner |
| `SkipHintQuitBar` | onSkip,onHint,onQuit | always enabled | **invariant** — present on every learning screen |
| `StatChip` | icon,value,label | — | streak value is neutral history |
| `PracticePaper` | char, strokes, guideOn | draw/animate | offline stroke data |
| `PitchLine` | pattern[] | static | text alt required |
| `LevelBadge` | level, exam | — | maps to curriculum level |
| `StateTheme` | psychState | flow/struggle/burnout/boredom | provides palette+motion to children |

# 7. Build order for the coder (matches roadmap)
1. Add the 5 data-model fields (§1) to schema + validator (T-104).
2. Build **Lesson micro-loop** (§5.4) with SkipHintQuitBar (FIX-D + T-106).
3. Add SQLCipher (FIX-C).
4. Wire `StateTheme` + the 4-state detection (deterministic) — Phase 4.
5. Author curriculum units A1.2 → A2.M (completes JFT-Basic path).
