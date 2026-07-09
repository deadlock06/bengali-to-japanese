---
name: integration-adobe
description: >-
  Adobe Creative Cloud integration skill. Auto-activates when working with
  Adobe tools — Illustrator vectors, Photoshop image editing, After Effects
  animation, Premiere video, XD prototyping, Lightroom photo editing, or
  exporting assets from Adobe for use in SENSEI. Also activates on: adobe,
  illustrator, photoshop, after effects, premiere, XD, lightroom, SVG export,
  vector asset, icon design, animation export, app icon, splash screen,
  lottie animation, adobe export, creative cloud, adobe asset, brand asset,
  SENSEI icon, kana illustration, character illustration.
---

# Adobe Creative Cloud Integration Guide

## You have Adobe connected to Claude
The Adobe integration lets Claude work with Adobe Creative Cloud assets —
reading, describing, and helping generate or refine visual assets for SENSEI.

## How Claude uses this integration
Claude can:
- Read and describe Adobe design files
- Generate prompts/specs for Adobe Firefly (AI generation)
- Help write Adobe ExtendScript / UXP scripts for automation
- Suggest export settings for each Adobe app

## SENSEI — Adobe assets by tool

### Illustrator (SVG assets)
```
- App icon (SVG → rasterize at 48dp, 72dp, 96dp, 144dp, 192dp)
- Kana character illustrations (hiragana/katakana mnemonics)
- Onboarding SVG illustrations
- Export: SVG, optimize with SVGO before bundling in Flutter assets/
```

### Photoshop (raster assets)
```
- Play Store feature graphic (1024×500 px, 72 dpi)
- Screenshot backgrounds
- Export: PNG-24, no ICC profile (Android doesn't use it)
```

### After Effects / Lottie (micro-animations)
```
- Correct answer celebration (subtle, not variable-reward)
- Loading spinner for AI inference
- Export: Lottie JSON via Bodymovin plugin
- Flutter: use lottie package (^2.x) — bundle in assets/animations/
- Keep file size < 50 KB per animation
```

### Adobe XD (UI prototyping — see also Figma)
```
- If designs originate in XD: export specs, extract design tokens
- Claude can read XD share links and translate to Flutter widgets
```

## Export settings for Flutter
```
SVG:    File → Export → SVG, Responsive ON, Decimal: 2
PNG:    Export for Web, PNG-24, 2x and 3x variants
Lottie: Composition → Export (Bodymovin), images embedded: false
Fonts:  Export as OTF/TTF → bundle in pubspec.yaml fonts section
```

## SENSEI brand constraints
- All illustrations must work offline (bundled, not CDN)
- Bengali script must render correctly — use Hind Siliguri or Noto Sans Bengali
- No imagery suggesting competition, streak pressure, or FOMO
- Illustrations should feel warm, local, practical (Bangladesh/Kolkata context)
