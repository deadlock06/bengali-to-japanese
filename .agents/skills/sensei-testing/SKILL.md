---
name: sensei-testing
description: >-
  Testing, CI/CD, and quality assurance skill for SENSEI. Activates when
  writing tests, running proofs, debugging CI failures, adding benchmarks,
  or doing ethical/UAT review. Also activates on: flutter test, node proof,
  mjs test, ci.yml, github actions, validate, benchmark, fsrs_reference,
  pitch_reference, migrations_reference, lesson_flow_reference, analyze,
  pub get, gen-l10n, unit test, property test, pass/fail.
---

# SENSEI Testing & CI Guide

## Proof scripts (no device / Flutter needed)
Run from repo root:
```powershell
node tools/fsrs_reference.mjs          # FSRS math — 11/11 pass
node tools/pitch_reference.mjs         # Pitch/F0 engine — 8/8 pass
node tools/migrations_reference.mjs    # DB migration selection — 10/10 pass
node tools/lesson_flow_reference.mjs   # Lesson state machine — 19/19 pass
node tools/validate_content.mjs        # Content guardrails — 0 blocking errors
```
**All 5 must pass before any commit.**

## Flutter tests (needs Flutter SDK)
```powershell
flutter pub get
flutter gen-l10n          # generates app_localizations.dart (required)
flutter analyze           # must be clean (0 errors, 0 warnings)
flutter test              # FSRS property tests + migration tests in Dart
```

## CI pipeline (`.github/workflows/ci.yml`)
### Node job (proof scripts)
```yaml
- node tools/validate_content.mjs
- node tools/fsrs_reference.mjs
- node tools/pitch_reference.mjs
- node tools/migrations_reference.mjs
- node tools/lesson_flow_reference.mjs
```

### Flutter job
```yaml
- flutter pub get
- flutter gen-l10n
- flutter analyze
- flutter test
```

**CI runs on:** push to main, pull requests to main.  
**Fail = block merge.** No exceptions.

## Writing new proofs (Node.js pattern)
```javascript
// tools/my_feature_reference.mjs
// Pattern: pure JS, no imports, property-based, self-validating
let pass = 0, fail = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    pass++;
  } catch (e) {
    console.error(`  ✗ ${name}: ${e.message}`);
    fail++;
  }
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

// --- tests ---
test('basic case', () => {
  assert(myFunction(input) === expected, `got ${result}`);
});

// --- summary ---
console.log(`\n${pass}/${pass + fail} pass`);
if (fail > 0) process.exit(1);
```

## Ethical review checklist (before shipping any new UX feature)
Run through this before committing UX changes:

- [ ] Skip / Pause / Quit always visible and enabled (≤1 tap, zero penalty)?
- [ ] No streak-save, streak-loss, or FOMO copy?
- [ ] No variable rewards or loot mechanics?
- [ ] No forced output / "speak or die" patterns?
- [ ] No session or screen locks?
- [ ] Graded answers use deterministic key match (not LLM judgment)?
- [ ] Bengali shown first (or alongside English gloss)?
- [ ] Offline works with zero network?
- [ ] Free tier genuinely usable without payment prompt?

**If any box is unchecked → block the feature, flag to human.**

## Device benchmarks (TODO — needs Tecno Pova 4)
```
LLM inference: >8 tok/s (llama-bench, Q4_K_M 7B)
STT transcribe: <3s for 15s clip
TTS first audio: <1s
Cold start: <2s (flutter run --profile)
Battery: <15%/hr (screen-on, active lesson)
RAM peak: <6.5 GB (DevTools memory profiler)
```

## What's currently verified ✅
- FSRS math: 11/11 node proof + Dart property tests
- Pitch/F0: 8/8 node proof
- Migration selection: 10/10 node proof
- Lesson state machine: 19/19 node proof
- Content: validator passes (7 non-blocking pack_id warnings — need pack_ids added)

## What's NOT yet verified ⚠️
- Dart/Flutter compile (no SDK in this environment — needs local machine or CI)
- SQLCipher wiring in `srs_local.dart` (hand-reviewed, not compiler-checked)
- Lesson loop `_srs` TODO markers (not yet wired to SrsLocal)
- Android build (no `android/` folder yet — `flutter create . --platforms=android` needed)
