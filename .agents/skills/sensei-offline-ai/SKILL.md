---
name: sensei-offline-ai
description: >-
  On-device AI implementation skill for SENSEI. Activates when working on
  llama.cpp, whisper.cpp, Kokoro TTS, FSRS-4.5 scheduler, RAG pipeline,
  on-device inference, Kotlin NDK, MethodChannel, STT/TTS, or any AI that
  runs without internet. Also activates on: inference, quantization, GGUF,
  embedding, vector store, pitch scoring, accentScore, F0 extraction,
  autocorrelation, kana_strokes, whisper, kokoro, llama, on-device, offline AI.
---

# SENSEI On-Device AI Guide

## Stack
| Component | Library | Format | Target perf |
|---|---|---|---|
| LLM | llama.cpp (Kotlin NDK) | Q4_K_M GGUF | >8 tok/s on Pova 4 |
| STT | whisper.cpp (Kotlin NDK) | small.en / tiny | <3s transcribe |
| TTS | Kokoro-82M | ONNX Runtime | <1s first audio |
| SRS | FSRS-4.5 (pure Dart) | in-process | <1ms schedule |
| Pitch | fftea + autocorrelation | in-process | <50ms score |
| RAG | SQLite FTS5 + embeddings | in-DB | <200ms retrieve |

## LLM — llama.cpp integration
```kotlin
// Kotlin side: android/src/main/kotlin/LlamaEngine.kt
// MethodChannel: "dev.sensei/llama"
// Methods: load(modelPath), generate(prompt, maxTokens), unload()
// RAM guard: check available before loading — abort if <2GB free
```

The LLM NEVER decides correctness. It:
- **Selects** a grammar template from the verified store
- **Glues** retrieved vocabulary into conversation turns
- **Generates** free conversation (not graded)

## Whisper — STT
```kotlin
// MethodChannel: "dev.sensei/whisper"
// Methods: transcribe(audioBytes, langCode) -> String
// Audio: 16kHz mono PCM, max 30s per chunk
// Language hint: "ja" for Japanese, "bn" for Bengali
```
STT spike (T-000a) is deferred — needs 20 Bengali test speakers on Pova 4.

## Kokoro — TTS
```kotlin
// MethodChannel: "dev.sensei/tts"
// Methods: synthesize(text, voice) -> audioBytes
// Voices: "ja-native" (Japanese reference), "bn-learner" (optional)
// Output: 22050 Hz, 16-bit PCM
```

## FSRS-4.5 Scheduler (`lib/domain/fsrs.dart`)
```dart
// Pure Dart, no Flutter or platform dependencies
// Key functions:
//   Card schedule(Card card, Rating rating, DateTime now)
//   Duration nextInterval(Card card)
// Ratings: Again=1, Hard=2, Good=3, Easy=4
// Proven: tools/fsrs_reference.mjs → 11/11 pass
```

## Pitch / F0 Engine (`lib/domain/pitch.dart`)
```dart
// accentScore(List<double> learner, List<double> reference) -> int (0-100)
// Uses autocorrelation + parabolic interpolation for sub-sample accuracy
// Speaker-independent contour normalization
// Proven: tools/pitch_reference.mjs → 8/8 pass
// 220 Hz / 330 Hz exact detection; identical contours ~100; opposite ~low
```

## RAG pipeline (planned)
```
Query → FTS5 fulltext search → top-K grammar rules → LLM prompt injection
Index: SQLite FTS5 on grammar_rules table (06_DATABASE §Grammar)
Embedding fallback: sentence-transformers tiny (if FTS5 insufficient)
```

## Device budget (Tecno Pova 4)
```
Total RAM:      8 GB physical
OS + system:    ~2 GB reserved
App heap:       <2 GB
LLM model:      ~2 GB (Q4_K_M 7B)
Whisper model:  ~150 MB (small)
Kokoro model:   ~150 MB (ONNX)
Safety margin:  ~1.5 GB
Peak total:     <6.5 GB ✓

Inference: >8 tok/s (profile with llama-bench before ship)
Cold start: <2s (measure flutter run --profile)
Battery: <15%/hr (measure on device, screen-on test)
```

## Kotlin NDK wiring checklist
- [ ] `CMakeLists.txt` links llama.cpp and whisper.cpp
- [ ] `minSdkVersion = 23` in `android/app/build.gradle`
- [ ] `abiFilters` set to `arm64-v8a` (primary) + `x86_64` (emulator)
- [ ] MethodChannels registered in `MainActivity.kt`
- [ ] Model files in `assets/models/` (gitignored — downloaded on first run)
- [ ] Model download: hash-verified, offline-first (no forced update)
