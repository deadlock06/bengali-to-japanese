# 12 BUSINESS & GTM — Pricing, Launch, Metrics, Costs
<!-- READ WHEN: monetization, marketing, launch ops, KPI questions. DEPENDS: 00,01. ~1.4K tokens -->

## Users
Primary: SSW aspirant — Bangladeshi male 22–35, rural/semi-urban, budget Android, <200MB/mo data, goal JFT-Basic A2 → SSW visa. Secondary: Kolkata university student, JLPT N4/N5. Tertiary: caregiver migrant, Bangladeshi female 25–40, short study bursts, privacy-sensitive.
Constraints to respect in every decision: 2–4GB free storage · 15–30 min sessions 3–5 days/wk · offline for days at a time · Bengali-first literacy.

## Pricing (ethics in 01)
Free $0 (everything core, 15-min soft nudge) · Premium $3.99/mo · Pro $19.99/mo. No microtransactions, no ads.
Revenue model (conservative): Y1 5K users/$22.5K → Y3 75K/$585K → Y5 300K/$4.59M (~$7M cumulative). B2B later: language schools white-label, SSW agency bulk licenses, corporate training.

## Cost reality (corrected — 99 D-006/D-007)
- Cloud AI at correct per-million pricing is trivial (<$0.01/user/mo hybrid). **Offline's justification = latency (0.8–1.5s vs 2–4s), reliability, zero-connectivity capability, determinism — NOT cost savings.** Never argue the cost case in marketing/board decks.
- Content factory: MVP $12–18K (5K pairs + 2K audio) · Year-1 full $40–60K (50K pairs + 10K audio). Highest-risk, highest-reward line item; quality > quantity — one wrong grammar explanation destroys trust.
- Infra: Supabase/Firebase base ~$25/mo + CDN egress for packs (watch this line as P2P share offsets it).

## Pre-launch (Weeks 18–22)
Waitlist 5K via: FB groups ("Bangladesh Japan SSW", "Kolkata JLPT Aspirants"), Bengali YouTube language influencers, Dhaka Univ + Jadavpur campuses. Landing sensei.app/early-access, first 1,000 → 1-mo Premium.
Content: Bengali blogs ("How to Learn Japanese Without Internet", "JFT-Basic A2 Guide", "Dhaka to Tokyo: SSW Journey") + 5×15s reels (kana drill, speaking, SRS, break screen as ethics signal, beta testimonial).
**Distribution GTM (new):** recruit 10 phone shops + 3 SSW agencies as preload partners (03 §Sideload); market "share the app pack with friends — free" as a headline feature.

## Store listing
Name: SENSEI — Japanese for Bengali Speakers. Sub: Offline Tutor. JLPT N5/N4. Exam Ready. **Lead with "45MB install — start learning in 1 minute."** Screenshots: kana stroke screen, SRS, restaurant scenario, break screen (ethics signal), data-export screen (control signal). Bengali description mandatory.

## Launch day
2× backend capacity · CDN warm for packs · rate limits on · Sentry alert >0.1% crash · PagerDuty P0 · dashboard: DAU, sync success, pack failure rate, cost/user, export rate · 2 part-time Bengali support agents · WhatsApp Business primary support channel · canned answers (export, delete, sync, STT, refund) · waitlist email + influencer pushes + Product Hunt.

## 30-day retention comms (all opt-in, default off; banned: guilt, streak-loss, countdowns)
D1 welcome · D3 supportive check-in · D7 progress report · D14 in-app NPS · D21 scenario tip · D30 single Premium offer w/ 3-day trial. Never repeated nagging.

## KPI targets
Learning: JFT pass >60% · N4 pass >50% · 30-day vocab retention >70% · speaking confidence >7/10.
Engagement: 7-day >40% · 30-day >20% · lesson completion >70% · session 15–25min · break acceptance >60%.
Health: offline sessions >50% · sync success >98% · pack failure <2% · export completion >5% · deletion <2% · crash-free >99% · NPS >50 · cloud cost <$0.50/user/mo.
Business: MAU 10K Y1 · premium conversion >8% · churn <5%/mo · LTV >$25 · CAC <$2 · LTV/CAC >12.
Distribution (new): Tier-0→1 conversion >80% wk1 · Tier-3 via P2P >30% · median month-1 data <120MB.

## Risk register (top)
R1 offline AI under-delivers → validation gates + retrieval fallback + router · R2 content cost overrun → phased 5K→50K · R3 Helio G99 perf → spikes first (T-000), quantization, thermal throttling · R4 **STT accuracy (HIGH)** → forced-alignment scoring, text fallback, spike gate · R5 store rejection → ethical review gate · R6 CDN egress cost → P2P + preload channels · R7 competitor copy → niche depth + verified Bengali content moat + agency partnerships.
