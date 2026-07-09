# 07 API & SYNC — Cloud Contract, Sync Bridge, Privacy
<!-- READ WHEN: endpoints, sync logic, conflict resolution, security/compliance. DEPENDS: 00,06. ~1.7K tokens -->

Base: `https://api.sensei.app/v1` (staging: `staging-api.…`). Auth: JWT Bearer via Firebase/Supabase Auth; access TTL 1h, refresh 30d, silent refresh in SDK. TLS 1.3 + cert pinning mandatory. All cloud features optional; app fully degrades offline.

## Endpoints
**POST /sync** — delta progress. Req: `{user_id, last_sync_timestamp, changes:{srs_cards[],conversations[],daily_stats[]}, device_id, app_version}`. Res: `{status, cloud_changes:{…, content_updates[]}, server_timestamp, next_sync_recommended}`. Errors: 401→silent refresh · 429→60s backoff, stay offline · 503→queue & retry · 404 content→use cache. Rate: 60/h/user.

**POST /ai/explain** — smart-router fallback for edge cases only. Req: `{user_query, user_level, context, complexity, preferred_language:"bn"}`. Res: `{explanation, explanation_bn, examples[], tags[], model_used, tokens_used, cost_usd}`. Rate: 20/h/user.
Router: complexity 1–6 offline ($0) · 7–8 GPT-4o-mini · 9–10 GPT-4o (culture/nuance/exam strategy). Cost basis: ~$0.15/M input for 4o-mini, ~$2.50/M for 4o (per-MILLION tokens — 99 D-007). Cloud AI cost/user is trivial (<$0.01/mo); offline is justified by latency/reliability/connectivity, not cost.

**GET /social/leaderboard** `?region&timeframe&limit` → user_rank, top_10[], nearby[]. Opt-in feature only. Rate 100/h.
**GET /content/manifest** — pack manifest (03 §manifest). Rate 10/h, aggressively cached.
**POST /ssw/readiness** — opt-in only, per-share consent recorded: `{user_id, exam_readiness, exam_type, consent_given, consent_timestamp, preferred_agencies[]}` → agency matches + referral. Response must echo `shared_data[]` so the app can show the user exactly what left the device.

## Sync bridge
- **Delta only:** records modified since `last_sync_timestamp`.
- **Conflict resolution:** default device-wins (local is source of truth); user-selectable cloud-wins (device switch). Merge: SRS cards keep the higher stability; conversation logs append both.
- **Offline queue:** `offline_queue` table (06); FIFO drain on connectivity; exponential backoff per item; poison items surfaced in debug overlay after 5 retries.
- Payloads gzip; at rest SQLCipher.

## Data classification & retention
| Class | Examples | Handling |
|---|---|---|
| PII | email, name, device ID, IP | encrypted at rest+transit, minimal retention |
| Sensitive | speech audio, progress, mistakes | local-first; cloud audio deleted immediately post-transcription; local audio 7 days |
| Non-sensitive | prefs, anonymized crash logs | opt-in |
Retention: profile/SRS/conversations — local until deletion, cloud 30d after last sync, instant on request · analytics 90d anonymized · export files local 30d.

## Export & deletion (first-class, offline-capable)
Export: Settings → one tap → ZIP (README.txt, manifest.json, profile/, lessons/, srs/, mistakes/, conversations/, achievements/, brain_map/, summary/progress_summary.pdf in Bengali). Size shown before start; Save/Share; optional password (AES). No support contact ever required.
Deletion: warning (with "export first" route) → confirm checkbox → 7-day grace (cancel by login; "Delete Immediately" needs 2nd confirm) → wipe local DB + cloud (Firebase/Supabase) + log deletion token. Nothing retained post-grace.

## Compliance targets
GDPR (portability, erasure, consent) · Bangladesh Digital Security Act 2018 · Bangladesh Consumer Rights Protection Act 2009 (transparent pricing, no dark patterns) · Play/App Store data policies. Privacy policy: plain language, Bengali-first, in-app.
