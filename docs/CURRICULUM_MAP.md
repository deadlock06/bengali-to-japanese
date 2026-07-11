# SENSEI Curriculum Map — the learning backbone
<!-- Machine version: assets/curriculum/curriculum.json. This is the single source of truth
     for sequencing, whitelist, prerequisites — consumed by RAG, LLM, grader, FSRS, Director, packs. -->

Aligned to the **JF Standard / Irodori** Can-do framework and the **JFT-Basic (A2)** + **JLPT N4** exams.
Anchor the *structure* on these standards; author your *own* verified Bengali content (never copy their text).

Status: ☑ authored (lesson exists) · ◐ partial · ☐ to author.

## L0 · Foundations (script) — pre-A1
| Unit | Can-do (BN) | Prereq | Status |
|---|---|---|---|
| L0.1 হিরাগানা | ৪৬টি হিরাগানা পড়া ও লেখা | — | ☑ hiragana |
| L0.2 কাতাকানা | ৪৬টি কাতাকানা পড়া ও লেখা | L0.1 | ☑ katakana |
| L0.3 সংখ্যা ও সময় | সংখ্যা, দাম, সময়, বার বলা | L0.1 | ☑ numbers_01, time_01 |

## A1 · Survival (Irodori Starter)
| Unit | Can-do (BN) | Prereq | Status |
|---|---|---|---|
| A1.1 Greeting ও self-intro | কর্মস্থলে নিজের পরিচয় দেওয়া | L0.1 | ☑ work_intro_01 |
| A1.2 নাম, দেশ, কাজ | নাম/দেশ/পেশা জিজ্ঞেস ও বলা | A1.1 | ☐ |
| A1.3 Konbini | দোকানে কেনাকাটা | L0.3 | ☑ konbini_01 |
| A1.4 Restaurant | খাবার order, বিল চাওয়া | A1.3 | ☑ restaurant_01 |

## A2 · Daily life & work (Irodori Elementary = **JFT-Basic target**)
| Unit | Can-do (BN) | Prereq | Status |
|---|---|---|---|
| A2.1 কাজ ও ছুটি | সহকর্মীকে অভিবাদন, ছুটি/দেরি জানানো | A1.1 | ☑ workplace_01 |
| A2.2 ক্লিনিক ও স্বাস্থ্য | অসুস্থতা বোঝানো, জরুরি সাহায্য | A1.2 | ☑ clinic_01 |
| A2.3 রাস্তা ও যাতায়াত | রাস্তা জিজ্ঞেস, ট্রেন/স্টেশন | L0.3 | ☐ |
| A2.4 অনুমতি ও অনুরোধ | 〜てもいいですか / 〜てください | A2.1 | ☐ |
| A2.5 অতীত ও পরিকল্পনা | 〜ました / 〜ます দিয়ে বলা | A2.4 | ☐ |
| A2.6 সমস্যা ও ক্ষমা | কাজের সমস্যা বোঝানো, ক্ষমা | A2.1 | ☐ |
| A2.M **JFT-Basic Mock** | আসল CBT format-এ mock | all A2 | ☐ |

## N4 · Expanded grammar (JLPT N4 — care/food/hospitality track)
| Unit | Can-do (BN) | Prereq | Status |
|---|---|---|---|
| N4.1 て-form | ধারাবাহিক কাজ বলা | A2.5 | ☐ |
| N4.2 Plain/casual | casual কথা বলা | N4.1 | ☐ |
| N4.3 সামর্থ্য (potential) | কী করতে পারি বলা | N4.1 | ☐ |
| N4.4 দেওয়া-নেওয়া | あげる/もらう/くれる | N4.2 | ☐ |
| N4.5 Keigo পরিচিতি | ভদ্র service-ভাষা | N4.2 | ☐ |
| N4.M **JLPT N4 Mock** | N4 format mock | all N4 | ☐ |

## Progress today
**8 / 20 units authored.** A learner can currently reach ~half of JFT-Basic A2. Priority to author next:
A1.2 → A2.3 → A2.4 → A2.5 → A2.6 → A2.M (completes the JFT-Basic path end-to-end).

## Every unit must carry (for the AI + validators)
`id · level · can_do{bn,en} · prerequisites[] · exam_tag · whitelist_ref · lesson_id`.
These fields are what let the LLM stay whitelisted, the grader key answers, FSRS order cards, and the Director pick "what next".
