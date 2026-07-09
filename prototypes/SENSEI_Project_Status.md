# SENSEI — Project Status & What To Do Next

*Plain-language guide. No coding knowledge needed to read this.*

---

## What SENSEI is

An offline phone app that teaches a Bangladeshi worker enough **correct** Japanese
to pass the exam needed to work in Japan, and to speak with a decent accent —
with the app's menus available in **English, Bengali, or Japanese**.

The real target we locked in: **JFT-Basic (A2 level)** — the test taken in Dhaka
for the Specified Skilled Worker (SSW) visa — plus **JLPT N4** for care/food/
hospitality jobs. Not the far-off "become fluent" dream; the exam that gets
someone on a plane.

---

## What you have right now (two things)

### 1. A working demo you can open today — `sensei_prototype.html`
Double-click it in any web browser (Chrome is best). No install. It shows the
real feel of the app:
- Learn the kana alphabet (tap to hear each letter)
- A workplace lesson (greetings, self-introduction) — verified correct Japanese
- **Shadowing**: hear a phrase, record yourself, watch your live pitch line
- **Pitch accent**: see how 箸 (chopsticks) vs 橋 (bridge) differ in melody
- A flashcard review that schedules words the smart way
- A language switch (English / বাংলা / 日本語). In Bengali it shows **English
  underneath**, so imperfect Bengali wording is always backed up.

This is what you show people, use yourself, or hand to an investor.

### 2. The real app's foundation — the `sensei_app/` folder
This is the actual app's skeleton in Flutter (the tool used to build real phone
apps). It's not yet an installable app, but the hard, correctness-critical parts
are done and **tested**:

| Piece | What it does | Proven? |
|---|---|---|
| Memory scheduler (FSRS) | Decides when to review each word so you don't forget | ✅ 11/11 tests pass |
| Pitch/accent engine | Measures your voice's melody and scores it vs native | ✅ 8/8 tests pass |
| Content checker | Blocks any lesson that isn't 100% verified & trilingual | ✅ all content passes |
| Verified content | 46 hiragana, 46 katakana, 2 workplace lessons, 6 pitch pairs | ✅ |
| Trilingual menus | English / Bengali / Japanese, Bengali shown bilingually | ✅ |
| App screens | Kana, Lesson, Shadowing, Pitch, Review | built |

**The core promise — "never teach wrong Japanese" — is built into the code.**
Every lesson is written and checked ahead of time; the AI is only ever a
practice partner, never the source of what's "correct."

---

## The honest gap: what's NOT done yet

To become a real app someone installs from the Play Store, three things remain,
and they **need a phone/computer with developer tools** (they couldn't be done or
tested in this chat):

1. **Wiring the "brain" onto the phone** — the offline AI (for conversation), the
   voice-to-text, and the Japanese voice. These are known open-source pieces; they
   need a developer to plug into the Android side.
2. **Turning on the microphone** for real recording (the demo already shows how).
3. **Building and testing on an actual Techno/Tecno phone.**

Think of it this way: the *engine and the blueprint* are built and tested. The
*final assembly onto a phone* is the remaining work.

---

## What to do next — your options

**Option A — Keep it as a demo for now (₹0, no developer).**
Use `sensei_prototype.html` to show the idea, get feedback from real JFT-Basic
students, and refine the lessons. I can keep adding verified content (more
lessons: clinic, train station, asking for days off) and polish the demo.

**Option B — Turn it into a real app (needs a Flutter developer).**
Hand them the `sensei_app/` folder and the architecture document. Because the
scheduler, pitch engine, content system, and screens are already built and
tested, a developer is mostly doing the "assembly onto the phone" part.
Rough estimate: a single experienced Flutter/Android developer, **6–10 weeks**
for a first installable version — with content authoring as the ongoing work.

**What to hand a developer:**
- The `sensei_app/` folder (the code)
- `SENSEI_Architecture_v1.1_Changes.md` (the plan)
- This file (the status)
- Tell them: *"The FSRS engine, pitch engine, content pipeline and screens are
  done and tested. I need the native model integration (llama.cpp / whisper.cpp /
  audio), real mic capture, and an Android build for the Tecno Pova 4."*

---

## The one rule to protect

Whoever continues this must keep the safety rule: **the learner only ever learns
from pre-written, verified content — never from raw AI output.** That's what makes
SENSEI trustworthy for someone whose visa depends on passing. The code already
enforces it (`validate_content.mjs` must pass before any lesson ships).

---

## Quick file map

- `sensei_prototype.html` — the clickable demo (open in a browser)
- `SENSEI_Architecture_v1.1_Changes.md` — the strategy & design
- `sensei_app/` — the real app foundation
  - `README.md` inside — how a developer runs it
  - `assets/content/` — the verified lessons (this is the app's "textbook")
  - `lib/` — the app's code (engine + screens)
  - `tools/` — the test/validation scripts that prove it works

You started with a strong architecture doc. You now have a runnable demo, a
tested foundation, and a clear path. That's real progress. 頑張って (ganbatte)!
