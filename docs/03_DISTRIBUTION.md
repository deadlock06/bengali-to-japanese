# 03 DISTRIBUTION — Staged Download Architecture (NEW in v4.2)
<!-- READ WHEN: install size, download manager, content packs, P2P sharing, updates. DEPENDS: 00,02. ~2K tokens -->

## The problem this solves
Old spec: 1.7GB monolithic app vs. users with 1–2GB/month data plans. Fatal contradiction. Fix: tiny base APK + tiered, resumable, shareable content packs. User is learning within 60 seconds of a ~45MB install and grows the app gradually.

## Tier plan
| Tier | Contents | Size | Delivery | Unlocked capability |
|---|---|---|---|---|
| **0 — Base APK** | App code, SRS engine, deterministic grader, kana course (hira+kata, stroke SVGs), Unit 1–2 lessons + audio, 100 starter SRS cards, 5 scripted scenarios | **~45MB** | Play Store | Full learning loop, day one, zero extra download |
| **1 — Content packs** | Unit packs (~10–15MB each): lessons, verified explanations, mistake patterns, scenarios, OPUS audio for that unit | ~350MB total, chunked | In-app, per-unit, auto-queued just-in-time | Full N5→N4 curriculum |
| **2 — STT pack** | whisper.cpp base model (quantized) + alignment data | ~150MB | In-app, prompted when user first opens a speaking drill | Automatic pronunciation scoring |
| **3 — LLM pack (optional)** | Qwen3 1.7B GGUF Q4_K_M + LoRA + embedding index | ~1.25GB | In-app, WiFi-only default, explicit opt-in, resumable | Free-form AI conversation |
| **4 — TTS upgrade (optional)** | Kokoro-82M | ~90MB | In-app | Dynamic TTS (else pre-recorded audio only) |

**Total if everything installed: ~1.9GB. Minimum viable forever: 45MB.**

## Download manager requirements
- **Just-in-time prefetch:** when user is ~70% through Unit N, silently queue Unit N+1 pack next time on WiFi (or on data if user opts in with size shown).
- **Resumable + chunked:** HTTP range requests, 4MB chunks, SHA-256 per chunk + per pack (manifest-signed). Survives network drops of days. Never restart a pack from zero.
- **Network policy:** default = WiFi-only for packs >20MB; user can override per-pack with explicit size + estimated data cost shown ("এই প্যাকটি 150MB — আপনার ডেটা প্ল্যানের কথা মাথায় রাখুন").
- **Storage guard:** check free space before queueing; offer to delete completed-unit audio (re-downloadable) if tight; packs stored in app-private storage, survive app updates.
- **Background:** WorkManager (Android) with WiFi + charging constraints for Tier 3.

## Sideload & P2P distribution (KEY for Bangladesh market)
- **Offline pack sharing:** in-app "Share packs" → exports signed pack files via Android Nearby Share / SHAREit / Files by Google / SD card. Receiving app verifies manifest signature before install. One user downloads Tier 3 on university WiFi; a whole dormitory gets it free. This is a feature, market it.
- **Retail/agent preload:** partner with phone shops + SSW agencies to preload full pack set via SD card image. Provide a signed "SENSEI Full Loader" USB/SD tool.
- **APK integrity:** packs are content-only (no code) so P2P sharing never bypasses Play signing.

## Pack manifest format (served at GET /content/manifest, cached)
```json
{ "manifest_version": 3, "min_app_version": "1.0.0",
  "packs": [{ "id": "unit_03", "tier": 1, "version": 2, "size_bytes": 12582912,
    "sha256": "…", "chunks": 3, "depends_on": ["unit_02"],
    "url": "https://cdn.sensei.app/packs/unit_03_v2.pack",
    "title_bn": "ইউনিট ৩", "delta_from": {"1": {"url": "…", "size_bytes": 2097152}} }] }
```
- **Delta updates:** pack updates ship as binary diffs (`delta_from`) — a weekly content update costs ~1–3MB, not a re-download.
- Local DB table `installed_packs(id, version, tier, installed_at, verified)` gates feature availability (capability ladder, 02 §Capability).

## UX rules
- Never block a lesson on a download — always offer what's installed.
- Download screen shows per-pack size, purpose in Bengali, and a running month-to-date app data counter (builds trust with data-poor users).
- Tier 3 pitch is honest: "Optional. Adds free conversation with an AI tutor. Everything else already works."

## Success metrics for this module
Tier-0→Tier-1 conversion >80% within week 1 · pack download failure rate <2% · % of Tier-3 installs acquired via P2P share >30% (proves the channel) · median data used in month 1 <120MB.
