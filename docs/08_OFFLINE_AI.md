# 08 OFFLINE AI — LLM, STT, TTS, RAG, FSRS
<!-- READ WHEN: implementing/tuning the on-device AI stack. DEPENDS: 00,02,03. ~2.2K tokens -->

## Stack roles (remember: LLM = selector/glue, never knowledge source — 02 §Key insight)
- **Verified content store** (Tier 0–1): the actual knowledge. Explanations, dialogues, mistake patterns.
- **RAG:** embed query → cosine sim over verified store → top-k retrieval. Target retrieval accuracy >90% held-out.
- **LLM** (Tier 3, optional): Qwen3 1.7B Q4_K_M + 50MB LoRA (rank 64/alpha 128, trained on verified pairs). Fine-tuned to SELECT and phrase, not invent.
- **GBNF:** grammar-constrained decoding → 100% schema-valid tagged output.
- **Whitelist enforcer:** post-decode filter; learner-facing Japanese limited to the 1,200-word JFT-A2 list. Violations → fall back to retrieved verbatim response.
- **Deterministic grader:** all graded answers = key match. LLM never grades.
- **STT** (Tier 2): whisper.cpp base. **Scoring mode = forced alignment against the KNOWN target sentence** + F0/phoneme comparison — never open transcription for grading (99 D-002). Text-input fallback always offered (noisy rooms).
- **TTS:** pre-recorded native OPUS first (Tier 0–1); Kokoro-82M for dynamic text (Tier 4).
- **Thermal/memory monitors:** reduce context length/threads on throttle; pause LLM features under low-memory, retrieval keeps working.

Quality ladder (constrained domain): raw Qwen 6.5/10 → +GBNF 7.5 → +RAG 8.5 (~9 tok/s, $0, offline). GPT-4o online 9.5 for the ~20% edge cases via smart router (07).

## FSRS-4.5 (CORRECTED — mood affects SELECTION, never the rating math; 99 D-003)
```dart
class FSRSEngine {
  final List<double> w = [0.40255,0.59854,2.40984,5.80984,4.92593,0.94123,0.86231,0.01000,
    1.48959,0.14480,0.94123,2.18154,0.05000,0.34560,1.26000,0.29400,2.61000];

  double retrievability(double s, double t) => math.exp(math.log(0.9) * t / s);

  FSRSCard review(FSRSCard c, int rating) { // rating stays pure 1..4 — NO mood multiplier
    final now = DateTime.now().millisecondsSinceEpoch;
    final t = c.lastReview != null ? (now - c.lastReview!) / 86400000 : 0.0;
    if (c.state == 'new') {
      c.stability = w[rating - 1];
      c.difficulty = (w[4] - w[5] * (rating - 3)).clamp(1, 10);
      c.state = rating == 1 ? 'learning' : 'review';
    } else {
      final r = retrievability(c.stability, t);
      final hard = rating == 2 ? w[15] : 1.0, easy = rating == 4 ? w[16] : 1.0;
      c.stability = c.stability * (math.exp(w[8] * (1 - r)) * hard * easy + 1);
      c.difficulty = (w[6] * c.difficulty + (1 - w[6]) * (w[4] - w[5] * (rating - 3))).clamp(1, 10);
    }
    c.reps++;
    if (rating == 1) { c.lapses++; c.state = 'relearning'; }
    else if (c.state != 'review') c.state = 'review';
    final days = switch (rating) { 1 => 1/1440, 2 => 1/24, 3 => c.stability, _ => c.stability * 2 };
    c..due = now + (days * 86400000).round() ..lastReview = now ..elapsedDays = t;
    return c;
  }

  // Mood adaptation lives HERE: tired/frustrated → serve easier, shorter queues.
  List<FSRSCard> getDueCards(List<FSRSCard> cards, {int limit = 20, String mood = 'neutral'}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final effLimit = switch (mood) { 'tired' || 'frustrated' => (limit * 0.6).round(),
                                     'anxious' => (limit * 0.8).round(), _ => limit };
    final due = cards.where((c) => c.due <= now).toList()
      ..sort((a, b) {
        const p = {'relearning':0,'learning':1,'review':2,'new':3};
        final s = p[a.state]! - p[b.state]!; if (s != 0) return s;
        if (mood == 'tired' || mood == 'frustrated') {
          final d = a.difficulty.compareTo(b.difficulty); if (d != 0) return d; // easiest first
        }
        return a.due - b.due;
      });
    return due.take(effLimit).toList();
  }
}
```

## Native bridge (MethodChannel `com.sensei.app/native`)
Dart calls: loadLlmModel(path) · generateLlmResponse(prompt) · loadSttModel(path) · transcribeAudio(path)→{text,language,confidence} · alignAudio(path, target)→{score, phoneme_errors[]} · speakJapanese(text, voice) · start/stopRecording · getThermalState · getMemoryState. Kotlin side wraps LlmService/SttService/TtsService/ThermalMonitor/AudioRecorder/MemoryMonitor in coroutines; `generateLlmResponse` reads thermal state and passes optimized params. (Reference impl from v4.1 Appendices C/D is behavior-correct; port as-is, add `alignAudio`.)

## System prompt for on-device LLM (Tier 3) — trimmed to what a 1.7B can honor
Identity: SENSEI, patient Bengali-first Japanese tutor. Persona injected: {Sensei|Didi|Bhai|Friend|Coach}.
Hard constraints: only whitelist vocabulary · only grammar from retrieved context (injected per prompt) · output in GBNF-enforced tags `[JP][BN][ROM][EXPLANATION][GRAMMAR_NOTE][SRS_WORDS][NEXT]` · never grade (grader does) · never claim rules not present in retrieved context — if missing, say so and suggest the lesson · encourage output, never demand; skipping is always fine · no shame/guilt/anxiety language · Bengali for all explanation, English never unless asked.
Per-prompt knowledge injection: USER_LEVEL, KNOWN_WORDS(last 200), WEAK_POINTS, RETRIEVED_CONTEXT(top-k verified docs), CONVERSATION_HISTORY(last 10), TODAY_SRS_DUE, EMOTIONAL_STATE, PERSONA_TYPE, SESSION_TIME.
Dropped from v4.1 prompt (moved to deterministic layers): confidence estimation, confusion detection, cap enforcement — agents own these (04, 99 D-004).

## Validation gates before any model ships in a pack
>85% on 1K held-out · 0 invented grammar rules on 500 trick questions (violation = falls back to retrieval, counts as pass only if fallback fired) · <3s/response · <3GB RAM in 100-conversation soak · 30-min thermal soak with ≤2 throttles.

## CURRICULUM LAYER (added 2026-07-11) — the curriculum bounds the AI
The per-level whitelist from `curriculum.json` is compiled into the **GBNF grammar + whitelist enforcer**: the on-device LLM literally cannot generate words above the learner's level or outside the verified set. RAG retrieves only level-scoped verified notes; explanations are selected, never invented. The deterministic grader uses Can-do answer keys. FSRS deck membership and unlock order come from curriculum prerequisites (selection only — rating stays pure, D-003). LoRA fine-tune trains on curriculum-derived data so default output is level-correct + Bengali-first. Net: **the curriculum is the fence that makes a 1.7B on-device model safe.**
