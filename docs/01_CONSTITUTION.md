# 01 CONSTITUTION — Product Philosophy & Ethics
<!-- READ WHEN: making product/ethics/UX-policy decisions. DEPENDS: 00. ~1.2K tokens -->

## Core principle
"Mastery is the destination. Engagement is the vehicle. If the vehicle drives in circles, we have failed."
Promise: **irresistible, not inescapable.** Red line: if a user engages frequently but doesn't improve, the product has failed.

## Three pillars
- **Autonomy** — user controls pace, content, exit at all times.
- **Retention** — remembered because chosen, not coerced.
- **Outcome** — pass the exam, get the job.

## Session-health policy (RESOLVED — supersedes any older contradictory text)
- Daily study **soft cap: 120 min**. At cap: full-screen recommendation to stop + easy-review-only mode offered. **Never a hard lock.**
- Break **reminder** every 20 min: dismissible overlay, one tap to continue. **Screen never locks.**
- Burnout detection → recommend end, reduce difficulty if user continues. Buttons: [Take a Break] (recommended) / [I'm Okay, Continue] (always enabled).
- **Parental mode (opt-in by guardian, for under-18 only):** caps become firm (45 min/day) with guardian PIN override. This is the sole exception to "never force."

## UI honesty rules
- Skip/Hint/Quit are **always visible and reachable** in ≤1 tap in every state, including Flow. (Old "hide skip in Flow" is banned — that was a dark pattern.)
- Streaks shown as neutral history only; no streak-loss warnings, no streak-save purchases.
- Continuation prompts are neutral ("Continue?") — no manufactured urgency ("You were so close…").
- All copy audited against banned patterns: shame, guilt, FOMO, countdown pressure, sunk cost.

## Monetization ethics
- Free tier: all lessons, SRS, scenarios, export. 15-min/day soft nudge (not a wall).
- Premium ($3.99/mo): unlimited time nudge-free, cloud sync, GPT-4o-mini deep explanations, social (opt-in), weekly content.
- Pro ($19.99/mo): 1-on-1 AI exam coaching, mock exams, SSW agency fast-track (opt-in), priority Bengali support.
- **Prohibited forever:** any microtransaction (streak saves, energy, mystery boxes, boosts), ads, frustration monetization, repeated upsell nagging (Premium prompt max once + one 3-day trial offer).

## Privacy stance (summary — details in 07/06)
Collect only what learning needs. Analytics opt-in, anonymized (HMAC-SHA256, rotating salt), default OFF. Audio deleted after transcription (cloud: immediately; local: 7 days). SSW data shared only with explicit per-share consent. No third-party ad/tracking SDKs. Plain-language Bengali privacy policy.

## Ethical review gate (blocks launch)
Sign-off required from Product + Engineering + Legal on: dark-pattern screen audit, copy audit, monetization audit, export/deletion E2E test, parental mode, accessibility (4.5:1 contrast, 48dp targets, reduced-motion), UAT with 0% users reporting coercion.
