# 02 ARCHITECTURE — System Layers & Dependencies
<!-- READ WHEN: designing components, wiring layers, adding deps. DEPENDS: 00. ~1.5K tokens -->

## Layer stack (top→bottom)
1. **Presentation (Flutter/Dart)** — state-adaptive UI (4 psych states, see 09), mastery visualization (XP, brain map), guided-output interfaces (mic, finger-drawing kana). Riverpod state mgmt.
2. **Agent Orchestration (Dart)** — 4 agents (Director, Persona, Scaffold, Feedback) on a shared state bus with arbitration; Director has final say; all decisions logged + explainable; user override always wins. See 04.
3. **Offline AI Core (C++/Kotlin via MethodChannel FFI)** — llama.cpp (Qwen3 1.7B Q4_K_M + 50MB LoRA), GBNF grammar-constrained decoding, RAG (embeddings + cosine sim over verified store), 1,200-word whitelist enforcer, deterministic grader (key match), whisper.cpp (STT), Kokoro-82M (TTS), FSRS-4.5 scheduler, thermal/memory monitors that throttle inference params. See 08.
4. **Content Layer (SQLite + files)** — verified responses (10K target, 5K MVP), 500+ mistake patterns, 200+ scenario trees, OPUS native audio, brain-map concept graph, milestone cosmetics. Schemas in 05. **Content is tiered for staged download — see 03.**
5. **Sync Bridge (Dart+Kotlin)** — delta sync, offline queue, conflict resolution (device-wins default), gzip + TLS1.3, SQLCipher at rest. See 07.
6. **Online Layer (optional; Supabase or Firebase + OpenAI)** — smart-router LLM fallback (~20% of conversations), Whisper Large v3 cloud STT, audio CDN, auth, social, push (opt-in), analytics (opt-in), SSW API. See 07/12.

## Capability ladder (CRITICAL design rule)
The app must be **fully usable at every content tier** (03_DISTRIBUTION). Feature availability by tier:
- **Tier 0 (base APK):** kana + first units, SRS, deterministic grading, scripted scenarios via retrieval/templates, pre-bundled audio. NO on-device LLM, NO STT — speaking drills use record+self-compare vs native audio.
- **Tier 1 (+content packs):** full lesson/scenario/audio library. Still retrieval-driven.
- **Tier 2 (+STT pack):** whisper.cpp scoring of speaking drills (forced alignment vs known target sentence — NOT open transcription).
- **Tier 3 (+LLM pack, optional):** free-form tutor conversation, dynamic scaffolding phrasing.
Every feature must declare its minimum tier and degrade gracefully below it.

## Key insight governing the AI core
Because ALL graded content is deterministic and ALL explanations are retrieved from the verified store, **the LLM is a selector/glue layer, not a knowledge source.** This is why Tier 0–2 work without it, and why "0% invented grammar rules" is achievable: generation is constrained to whitelist vocabulary + retrieved explanation text + GBNF format.

## Flutter dependencies (pin via fvm, Flutter 3.22+)
riverpod ^2.5, sqflite ^2.3 (+SQLCipher), shared_preferences, record ^5, just_audio, dio ^5.4, flutter_animate, uuid, intl, crypto, path_provider, sensors_plus, local_auth (optional), firebase_core/auth/firestore/messaging OR supabase_flutter (pick one at T-105), csv, pdf, archive, share_plus. Native: NDK 25+, CMake 3.22+, arm64-v8a, android-24 min.

## Performance budgets (Tecno Pova 4, Helio G99)
Model load <3s · inference >8 tok/s · RAM peak <6.5GB in 20-min session · cold start <2s · STT→TTS latency <1.5s · battery <15%/hr · ≤2 thermal throttle events per 30 min. Thermal monitor reduces ctx/threads under load.
