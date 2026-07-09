---
name: sensei-decisions
description: >-
  Architecture decision logging skill for SENSEI. Activates when making a
  design choice, trade-off, or architectural decision; when the user asks "why
  was X decided?"; when changing existing design; or when spec is silent and
  a judgment call is needed. Also activates on: decision log, 99_DECISIONS,
  D-001, trade-off, "why did we", "should we use", design choice, log decision,
  append decision, decision number.
---

# SENSEI Decision Logging Guide

## When to log a decision
Log any choice that:
- Is not obvious from the spec
- Could be reasonably made differently
- Changes existing architecture
- The next AI session needs to know about

## Decision format (append to `docs/99_DECISIONS.md`)
```markdown
## D-NNN — Short descriptive title
**Date:** YYYY-MM-DD  
**Author:** Claude <model> / <human-name>  
**Status:** ACCEPTED | SUPERSEDED-BY D-NNN | PENDING-HUMAN-REVIEW  

### Context
What problem were we solving? What were the constraints?

### Options considered
1. Option A — pros/cons
2. Option B — pros/cons

### Decision
We chose Option B because...

### Consequences
- ✅ What this makes easier
- ⚠️ What this makes harder / deferred
- 🔒 Human review required: yes/no — why

### Linked tasks
T-NNN, FIX-X
```

## Key existing decisions (know these before making changes)
| ID | Topic | Decision |
|---|---|---|
| D-001 | Dark patterns | BANNED: dopamine engine, forced output, loot, hidden skip, streak-saves. Penalty-free always. |
| D-011 | KanjiVG stroke data | Use KanjiVG (CC BY-SA); attribution in About screen. PENDING human review on commercial use. |

## Rules for decision logging
1. **APPEND-ONLY** — never edit or delete existing decisions
2. Number sequentially (check last D-NNN in the file, increment)
3. Mark `PENDING-HUMAN-REVIEW` for anything with legal, commercial, or ethical weight
4. If you supersede a decision, mark old one `SUPERSEDED-BY D-NNN`, then add new entry
5. Cite the decision number in code comments: `// per D-011`

## Automatic logging triggers
Log a decision when:
- Picking between 2+ reasonable tech choices
- Making a UX trade-off
- Choosing a third-party library
- Setting a budget threshold (RAM, battery, latency)
- Changing a NON-NEGOTIABLE-adjacent behavior
- Anything that surprised you during implementation

## Open decisions (need human action)
From NEXT_SESSION.md:
- **D-011** — Confirm KanjiVG CC BY-SA is acceptable for commercial build (attribution is embedded; standard practice; human confirmation still required)
- **Pitch pillar keep/kill** — Recommend KEEP (`lib/domain/pitch.dart`, `pitch_accent.json`, PitchScreen)
