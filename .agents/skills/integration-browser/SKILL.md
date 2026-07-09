---
name: integration-browser
description: >-
  Claude in Chrome / browser integration skill. Auto-activates when the user
  is viewing a web page and wants Claude to read it, summarize it, extract
  data from it, or interact with it. Also activates on: this page, current tab,
  what does this say, read this, summarize this website, extract from page,
  web search context, browser, chrome, open URL, navigate to, check website,
  MDN, pub.dev, flutter.dev, developer docs, Japanese dictionary, JFT official
  site, JLPT vocab list, KanjiVG, japanese dictionary, jisho.org, wadoku,
  wanikani, NHK accent dictionary, official SENSEI research.
---

# Browser / Claude in Chrome Integration Guide

## You have Claude in Chrome active
Claude in Chrome can read the page you currently have open — giving Claude
direct context from any website without copy-pasting.

## How Claude uses this integration
Claude can:
- Read and summarize the current browser tab
- Extract structured data from web pages (vocabulary lists, API docs, etc.)
- Cross-reference official docs while you work
- Research Japanese language resources in real time

## SENSEI — key research sources Claude watches for

### Japanese language reference
| Site | Use |
|---|---|
| `jisho.org` | Vocabulary lookup, reading, example sentences |
| `nhk.or.jp/bunken/accent` | NHK accent dictionary (pitch patterns) |
| `kanjivg.github.io` | Stroke order data (CC BY-SA — cite attribution) |
| `wadoku.de` | Japanese-German dict with pitch accent data |
| `tatoeba.org` | Example sentences (CC BY) |

### Official exam resources
| Site | Use |
|---|---|
| `jft-basic.jp` | Official JFT-Basic A2 word list and exam format |
| `jlpt.jp` | JLPT N5/N4 official info |
| `mhlw.go.jp` | SSW visa requirements (Japan Ministry of Health) |
| `jitco.or.jp` | Technical intern training program rules |

### Flutter / Dart docs
| Site | Use |
|---|---|
| `pub.dev` | Package lookup, version checking |
| `flutter.dev/docs` | Widget catalog, API reference |
| `dart.dev/guides` | Language spec, null safety |
| `docs.riverpod.dev` | Riverpod provider patterns |

### Supabase / cloud docs
| Site | Use |
|---|---|
| `supabase.com/docs` | API reference, RLS policy syntax |
| `docs.aws.amazon.com` | AWS service docs |
| `vercel.com/docs` | Deployment config reference |

## Content extraction workflow
When Claude reads a vocabulary list from a web page:
1. Extract: Japanese, reading (furigana), English/Bengali meaning
2. Validate: check against JFT-A2 whitelist scope
3. Format: convert to SENSEI JSON schema (see sensei-content skill)
4. Verify: add `"verified": true` only after human confirms source quality

## Attribution rule
Any content extracted from the web must record its source in the JSON:
```json
"source": "jisho.org|2026-07-09",
"verified": true
```
