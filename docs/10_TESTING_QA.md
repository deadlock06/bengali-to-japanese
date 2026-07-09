# 10 TESTING & QA — Unit, Integration, Device, UAT, Ethics
<!-- READ WHEN: writing tests, CI, benchmarks, UAT plans. DEPENDS: 00. ~1.2K tokens -->

## Unit (flutter_test + mockito, coverage >85% on core)
Targets: FSRS math vs reference implementation (incl. mood-selection behavior, NOT rating mutation — 99 D-003) · Director decision tree (pure function: inputs→lesson/difficulty/state/rationale) · GBNF output schema compliance · content validation script (all 12 rules in 05) · export ZIP completeness · pack manifest verification (chunk hashes, signature, dependency graph).
```dart
test('Director recommends easy review after 3-day gap', () {
  final s = DirectorAgent().decide(retention: .55, daysSinceLast: 4, accuracy: .60, sessionMin: 15);
  expect(s.recommendedLesson.type, 'review');
  expect(s.difficulty, lessThan(4));
});
```

## Integration (integration_test; mock native channel for CI determinism)
1. Full lesson micro-loop → SRS scheduled. 2. High error injection → UI enters STRUGGLE ≤5s. 3. Airplane mode → all Tier-0 features pass. 4. Sync: local edits → sync → conflict cases (device-wins, cloud-wins, stability-max merge). 5. Export → ZIP contains every expected file, PDF opens. 6. Deletion → grace period honored → wipe verified. 7. **Pack lifecycle:** queue → interrupt mid-chunk → resume → verify → feature unlock; P2P import with bad signature → rejected. 8. **Skip/Quit reachability:** automated sweep asserting Skip+Quit enabled on every learning screen in all 4 psych states (constitution regression test).

## Real-device benchmarks (Tecno Pova 4; fail if any metric >target+20%)
Model load <3s · inference >8 tok/s · RAM peak <6.5GB (20-min session) · thermal ≤2 throttles/30min · battery <15%/hr · cold start <2s · STT→TTS <1.5s. Protocol: fresh install, 30-min scripted session, sample every 30s, auto-report.

## Pre-Phase-1 de-risk spikes (MUST run before foundation code — 99 D-002)
- **STT spike (2 weeks):** whisper.cpp base on-device with 20 real Bengali speakers, noisy environments, forced alignment vs known targets. Gate: usable scoring signal for >70% of attempts, else redesign speaking pillar.
- **Inference spike (1 week):** Qwen3 1.7B Q4_K_M on Pova 4 — verify tok/s + thermal before committing to Tier 3.

## UAT (100 users: 50 Dhaka, 50 Kolkata; 2 weeks; incentive = 3-mo Premium)
Observe unassisted: onboarding (first 5 lessons) · finding skip/pause/quit · data export · speaking drill in real rooms · offline usage · **Tier-1 pack download on their own data plans** · P2P pack share between two testers.
Collect: NPS (>50) · coercion reports (target 0%) · bug sev classes · 7-day retention (>40%) · lesson completion (>70%) · median data consumed (<120MB).

## Ethical review (blocking gate — checklist)
Dark-pattern screen audit (skip visible everywhere incl. Flow) · banned-copy scan · monetization audit (no microtransactions) · export/deletion E2E · parental mode · analytics default-off verified · SSW consent flow · accessibility suite · sign-off: Product + Engineering + Legal.
