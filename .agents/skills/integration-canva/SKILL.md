---
name: integration-canva
description: >-
  Canva integration skill. Auto-activates when creating or editing marketing
  materials, social media graphics, app store assets, presentation slides,
  promotional content, or visual content for SENSEI. Also activates on:
  canva, graphic design, social post, app store screenshot, play store graphic,
  feature graphic, banner, poster, flyer, presentation, slide deck, marketing
  asset, brand kit, SENSEI marketing, GTM assets, launch graphics,
  12_BUSINESS_GTM, promotional image, thumbnail, logo, visual identity.
---

# Canva Integration Guide

## You have Canva connected to Claude
The Canva integration lets Claude create, read, and edit Canva designs directly
from the conversation — no manual export/import needed.

## How Claude uses this integration
Claude can:
- Create new designs from templates
- Edit existing Canva designs
- Generate marketing copy to go with designs
- Suggest layouts for SENSEI promotional materials

## SENSEI — Canva assets needed
Per `docs/12_BUSINESS_GTM.md`, SENSEI needs these visual assets:

### App Store / Play Store
- **Feature graphic** (1024×500 px) — hero image showing Bengali+Japanese UI
- **Screenshots** (×5, portrait) — Kana screen, Lesson, Review, Pitch, Progress
- **Icon** (512×512 px) — sensei character mark, works at 48dp

### Social / Marketing
- **Twitter/X card** (1200×628 px)
- **Facebook post** (1200×630 px)
- **WhatsApp shareable** (square, Bengali text) — for Bangladesh community spread

### In-app (if needed)
- Onboarding illustrations (SVG preferred — bundles small, offline)
- Achievement badges (SVG, predictable/mastery-based — no variable rewards)

## Brand constraints for SENSEI
- **Bengali-first** — all marketing copy leads with Bengali (বাংলা)
- **Tone:** Warm, honest, practical. Not gamified/hype. Target: job-seeking workers.
- **Colors:** Derive from `docs/09_UI_STATES.md` UI palette
- **No dark pattern imagery:** no streak flames, no trophies that imply competition

## Marketing copy rules (01_CONSTITUTION)
✅ OK: "Learn Japanese that gets you the job" / "শিখুন, আপনার নিজের গতিতে"  
❌ Never: "Don't fall behind!" / "Limited spots!" / "Others are ahead of you"
