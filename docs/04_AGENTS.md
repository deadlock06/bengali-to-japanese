# 04 AGENTS — The Four-Agent System
<!-- READ WHEN: implementing agent logic, state bus, psych states. DEPENDS: 00,02. ~1.6K tokens -->

Four Dart-side agents on a shared state bus. Director arbitrates. Every decision: logged, explainable in Bengali, **overridable by the user**. Agents run on deterministic signals (taps, timing, accuracy) — NOT on LLM judgment (see 99 D-004).

## 1. Director — curriculum & pacing
Decides WHAT to teach, WHEN to shift difficulty, WHETHER to recommend continuing.
- Inputs: accuracy/speed/hesitation, tap patterns, SRS retention & due load, session time, days since last session, time of day, installed pack tiers.
- Outputs: recommended next lesson ID + difficulty (1–10) + psych state + recommended session length + one-line Bengali rationale.
- Sequencing: Irodori Can-do order, adaptive; i+1 mix ≈ 70% known / 30% new.
- Decision rules (examples — implement as a testable pure function):
  - retention<60% AND days_since>3 → STRUGGLE → easy review, ≤10 min, "আগে একটু ঝালাই করি।"
  - accuracy>90% AND session>20min → BOREDOM → offer new pattern/challenge.
  - tap_speed<50% baseline AND error_rate>30% → BURNOUT → recommend end, offer break screen (dismissible).
  - accuracy 70–85% AND engaged → FLOW → hold difficulty, offer (not push) continuation.
- Constraint: **recommends, never forces.** At the 120-min soft cap: recommendation screen + easy-review-only mode offer (01 §Session-health).

## 2. Persona — tone & relationship
Types: **Sensei** (strict, traditional) · **Didi/Bhai** (warm, patient) · **Friend** (playful) · **Coach** (competitive). User picks; agent may suggest a switch, never auto-switches.
Relationship arc: Week1 formal → Weeks2–4 knows name, gentle references to past mistakes → Months2–3 mentor → Month4+ casual banter (only if user opted in).
Constraints: no shame/pressure ever; detect anxiety → reduce intensity; honor a fixed-persona preference permanently.

## 3. Scaffold — micro-teaching & confusion resolution
Confusion signals (deterministic): hesitation>3s → offer hint · 3+ misses on same pattern → switch to review · random tapping → offer help · session abandonment → log frustration point for Director. (Voice-stress detection: deferred, see 99 D-005.)
Methods: hint ladder (user pulls each rung) · syllable breakdown · easier example bridge · visual scaffold (stroke order, word blocks) · Bengali cultural analogy.
Constraint: always asks ("এটা নিয়ে সাহায্য লাগবে?"), never commands. Skip is penalty-free.

## 4. Feedback — mastery tracking & reporting
Session summaries (learned / weak / next), weekly reports, opt-in notifications, milestone celebrations.
Reward schedule (all **predictable**, mastery-tied): correct answer → instant positive feedback · lesson complete → fixed XP · 10 lessons mastered → milestone · 50 words retained → level · exam-readiness rise → SSW progress marker. **No variable rewards, ever.**

## State bus contract
```dart
class AgentState { PsychState psych; int difficulty; String? recommendedLessonId;
  String rationaleBn; PersonaType persona; ScaffoldOffer? scaffold; SessionAdvice advice; }
```
- Bus is a Riverpod StateNotifier; agents publish proposals; Director merges each tick (post-answer + every 30s).
- UI consumes final AgentState only. All transitions logged to `agent_log` for debug overlay + explainability.

## Psych states (recommendations only — UI specs in 09)
FLOW (optimal) · STRUGGLE (accuracy<60%) · BURNOUT (fatigue signals) · BOREDOM (accuracy>90%, autopilot). Transitions animate per 09; none ever locks input or hides Skip.
