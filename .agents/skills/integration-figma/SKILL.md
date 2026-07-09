---
name: integration-figma
description: >-
  Figma integration skill. Auto-activates whenever working with UI design,
  Figma files, design tokens, components, prototypes, design handoff, or
  translating designs into Flutter/CSS code. Also activates on: figma,
  design file, UI component, screen design, mockup, prototype, design token,
  color style, typography style, auto-layout, frame, component set, variant,
  design spec, handoff, inspect mode, SENSEI UI, screen layout, kana screen
  design, review screen design, pitch screen design, onboarding UI, Bengali UI.
---

# Figma Integration Guide

## You have Figma connected to Claude
The Figma integration lets Claude read your design files directly — extracting
component specs, colors, spacing, and typography without manual copy-paste.

## How Claude uses this integration
Claude can:
- Read design tokens (colors, spacing, typography) from Figma files
- Extract component specs and translate to Flutter widgets
- Check consistency between design and implementation
- Generate Flutter widget code from Figma frames

## SENSEI — Figma role
Figma is the source of truth for SENSEI's UI design:
- Screen layouts → Flutter widgets in `lib/presentation/`
- Design tokens → Flutter `ThemeData` constants
- Component specs → `lib/presentation/widgets.dart`

## Design → Flutter translation rules
```dart
// Figma auto-layout row → Row(children: [...])
// Figma auto-layout column → Column(children: [...])
// Figma frame with clip → ClipRRect / ClipPath
// Figma text style → TextStyle in ThemeData
// Figma color style → Color constants in AppColors

// Example: Figma "Body/Bengali" text style
// → TextStyle(fontSize: 16, fontFamily: 'Hind Siliguri', height: 1.5)
```

## SENSEI design constraints
All designs must follow these UI/UX rules (from `docs/09_UI_STATES.md`):
- **[Skip] [Pause] [Quit]** always visible on lesson/review screens — ≤1 tap
- **Bengali-first** — Bengali text is larger/primary; English gloss is dimmed beneath
- **No dark patterns** — no streak counters that guilt, no locked content UI
- **Budget device** — target 360×800 dp (Tecno Pova 4 screen), avoid heavy shadows

## Font stack for SENSEI
```dart
// Bengali: Hind Siliguri or Noto Sans Bengali
// Japanese: Noto Sans JP (for kana/kanji display)
// Latin: Inter or Roboto (UI chrome)
// All fonts must be bundled in assets (offline-first — no Google Fonts CDN)
```

## When Claude reads your Figma file
Provide the Figma file URL or share it via the Figma connector.
Claude will extract: frame names, component tree, color values, spacing, text styles.
Then Claude generates the corresponding Flutter widget code.
