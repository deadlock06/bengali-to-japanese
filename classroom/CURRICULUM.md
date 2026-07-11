---
id: classroom_curriculum
version: 1
title: "SENSEI AI Classroom — Teaching Curriculum & Logic"
status: authoritative for classroom behavior; unit ontology mirrors assets/curriculum/curriculum.json v1
consumers:
  - "CurriculumScreenV4 + curriculum service (T-120)"
  - "BookScreenV4 reader (T-121) — via classroom/BOOK.md chapter anchors"
  - "Sensei chat/talk tutor (D-013 surface 3) — RAG store + response templates"
  - "Director agent (lib/agents/director.dart) — sequencing config"
  - "Content authors — unit specs = authoring briefs"
depends_on: ["docs/00_START_HERE.md", "docs/01_CONSTITUTION.md", "docs/04_AGENTS.md", "docs/05_CONTENT_SCHEMAS.md", "docs/09_UI_STATES.md", "docs/99_DECISIONS.md D-001/004/012/013/015", "docs/CURRICULUM_MAP.md", "assets/curriculum/curriculum.json"]
banned_patterns_audit: "clean (00 D-001)"
---

# SENSEI AI Classroom — Teaching Curriculum

This file is the **teaching brain on paper**: what the classroom teaches (unit specs), in what order (ladder + prereq DAG), and exactly how (loop, agents, moods, grading, Sensei behavior). Code implements this; content authors fill it; the AI is *bounded* by it. If this file and code disagree, flag per 00 work rules — don't silently drift.

## 1. Binding teaching rules (the classroom constitution)

Non-negotiable, inherited from 00/01/04/05/09 + D-001/004/012/013. Every classroom feature must pass all ten:

1. **Curriculum-scoped:** Sensei teaches ONLY content reachable from the learner's position in the unit DAG (§6). Never off-syllabus Japanese.
2. **Whitelist-bounded:** learner-facing JP stays inside `whitelist_ref` of the active unit (jft_a2 at L0–A2, n4 at N4). Enforced by GBNF/whitelist filter, not by prompt hope.
3. **Retrieved, never invented:** grammar explanations come from the verified store (this file + BOOK.md chapters + lesson JSONs). The LLM selects/glues/paraphrases within whitelist; it never authors a new rule. (D-004)
4. **Answer-key grading only:** correctness = deterministic key match (string/kana-normalized). Sensei chat is EXPLANATORY; it never grades. (D-001, D-012)
5. **Deterministic affect:** psych state/mood from accuracy+timing signals per 04/09 thresholds — never LLM-judged. (D-004)
6. **Recommend, never force:** Skip/Hint/Quit visible and free in every phase and mood. No locks — upcoming units render neutral, never 🔒. (D-015 confirmed this for classroom surfaces.)
7. **Fixed rewards only:** 10 XP/lesson · milestone/10 lessons · level/50 retained words. No variable rewards, no streak pressure; streak = neutral history.
8. **i+1 sequencing:** each session mixes ≈70% known / 30% new; "new" only from units whose prerequisites are met.
9. **Bengali-first, Banglish register:** explanations in Bengali script with natural English mixing (register reference = BOOK.md); EN/JA optional, never default.
10. **Offline-first:** every classroom behavior in this file works at Tier 0 (no network). Cloud tutor is opt-in paraphrase-enhancement only.

## 2. The ladder (levels ↔ exams ↔ book parts)

| Level | Name | CEFR | Exam target | Units | Book | Est. effort |
|---|---|---|---|---|---|---|
| L0 | Foundations (script) | pre-A1 | — | L0.1–L0.3 | Part 0 (Ch.1–3) | 3–4 wk |
| A1 | Survival | A1 | Irodori Starter scope | A1.1–A1.4 | Part 1 (Ch.4–7) | 4–6 wk |
| A2 | Daily life & work | A2 | **JFT-Basic** | A2.1–A2.6 + A2.M | Part 2 (Ch.8–14) | 8–10 wk |
| N4 | Expanded grammar | A2+/B1 | **JLPT N4** | N4.1–N4.5 + N4.M | Part 3 (Ch.15–20) | 10–12 wk |
| (beyond) | roadmap only | B1+ | N3→N1 | — | Part 4 | — |

**Exam facts the classroom cites (verified 2026-07):**
- JFT-Basic: CBT · 60 min · ~50 Q in 4 sections (Script&Vocab / Conversation&Expression / Listening / Reading) · 10–250 pts · **pass 200** (SSW). **From Aug 2026:** bands 145–174 = A1, 175–199 = A2.1, 200–250 = A2.2. Sessions run year-round incl. Bangladesh.
- JLPT N4: paper · ~115 min · 3 sections · 180 pts (90+ AND per-section minimums) · ~1,500 words · ~300 kanji · July + December, Dhaka available.

## 3. The teaching loop (how Sensei stages every unit)

Classroom = presentation layer over the existing engine (D-015). Per lesson, the **5-phase micro-loop** (09):

| Phase | Time | Engine | Classroom staging (Sensei behavior) |
|---|---|---|---|
| 1. Intro | ~30s | exposure section | Sensei presents target item: JP + kana + romaji + BN meaning + one cultural/usage note. Banglish framing line, e.g. "আজকে একটা দরকারি phrase — কাজে প্রতিদিন লাগবে।" |
| 2. Recognition | ~30s | MC audio→meaning / text→audio | Sensei asks; grading = answer key. Correct → fixed positive ack. Wrong → show correct, queue mistake_pattern, NO shame copy. |
| 3. Production | ~60s | speak (Tier 2+ aligned scoring; Tier 0–1 record-and-self-compare) or finger-write kana | Always offers: hint ladder · syllable breakdown · slow model · skip. `skip_allowed: true` ALWAYS. |
| 4. Context | ~60s | word-block build / gap-fill | Wrong placement = visual nudge (never "failure"). Sensei may glue a retrieved contrast note (e.g. で vs に from BOOK Ch.8/10). |
| 5. SRS | bg | FSRS-4.5 schedules recognition+production cards from `srs_words` | Sensei closes: "আজকের শব্দগুলো review deck এ ঢুকলো — কালকে আবার দেখা হবে ওদের সাথে।" |

**Session templates** (Director picks by available time + state; all exits free):
- **Quick (≈10 min):** SRS due (≤15 cards) → 1 micro-loop on weakest item → close summary.
- **Standard (≈25 min):** SRS due → 2–3 new items (i+1 mix) → context drill → close.
- **Deep (≈45 min):** standard + scenario run or mock-section (A2.M/N4.M path) + weakness review. 20-min break banner applies (01).

**Sequencing algorithm (Director config):**
1. Eligible units = prerequisites met (per §6 DAG). 2. Rank: exam-path priority (A2.M path first for SSW-goal users per D-015 goal maps) → weakest can_do coverage → FSRS due pressure. 3. Inside a unit: lesson items in authored order; re-inject items whose mistake_patterns fired. 4. Never present an item whose JP contains un-taught script (kana gate: L0.1/L0.2 first, always).

## 4. Psych-state playbook (deterministic; classroom moods per D-012)

Triggers (04/09) → mood → behavior. Copy examples below are the **pre-authored pool** Sensei SELECTS from (never generates fresh motivational copy — rule 3):

| State | Trigger (deterministic) | Classroom mood | Sensei does | Sample lines (Banglish, per persona) |
|---|---|---|---|---|
| FLOW | acc 70–85%, engaged, <20min | warm neutral | hold difficulty; OFFER continue, never push | Sensei: "ভালো চলছে। এই গতিতেই।" · Didi/Bhai: "বাহ, আজ তো দারুণ যাচ্ছে!" · Friend: "ফর্মে আছিস আজকে 🔥" · Coach: "Sweet spot এ আছো — ধরে রাখো।" |
| STRUGGLE | acc <60% or 3+ same-pattern miss or hesitation >3s | soft, slowed | drop to review items; offer scaffold ladder (ask first: "এটা নিয়ে সাহায্য লাগবে?") | Didi/Bhai: "এই pattern টা সবারই প্রথমে কঠিন লাগে। একটা সহজ উদাহরণ দিয়ে দেখি?" · Sensei: "আগে একটু ঝালাই করি। ভিত শক্ত তো সব শক্ত।" |
| BURNOUT | tap speed <50% baseline, error spike, >40min | dim, calm | recommend end + break screen (dismissible); if continue → easy review only | Didi/Bhai: "আজ অনেকটা হয়েছে। বিরতি নিলে মাথা নিজেই গুছিয়ে নেয়।" [Take a Break] / [I'm Okay, Continue] |
| BOREDOM | acc >90%, autopilot, >20min | brighter | offer (not push) harder pattern / new unit / scenario | Coach: "এগুলো তোমার কাছে পানি হয়ে গেছে। নতুন কিছু try করবে?" · Friend: "চ্যালেঞ্জ নিবি একটা? 😏" |

Mood shifts are ambient (color/copy per 09 transitions) — never blocking, never shaming, Skip/Hint/Quit untouched. Persona voice: user-picked, may suggest switch, never auto-switches; anxiety signals → reduce intensity (04).

## 5. Unit spec format

Every unit below carries the 05 curriculum-layer contract: `id · level · can_do{bn,en} · prerequisites[] · exam_tag · whitelist_ref · lesson_files (assets/content) · book_chapter (classroom/BOOK.md anchor) · grammar[] · vocab_domains (+target count) · mistake_patterns[] · scaffold[] · assessment{}`. `mistake_patterns` here are authoring briefs — instantiate as 05 mistake-pattern JSONs when wiring remediation. Status: ☑ lesson JSON exists · ◐ partial · ✍ book-only (lesson JSON to author).

## 6. Unit specs (the 20-unit DAG)

### L0.1 হিরাগানা — ☑
`level:L0 · prereq:[] · exam:foundation · whitelist:jft_a2 · lessons:hiragana.json · book:Ch.1 · words:46+9`
**can_do (bn):** ৪৬টি হিরাগানা পড়া ও লেখা **(en):** Read and write the 46 hiragana
**grammar:** none (script) — sokuon っ, yōon ゃゅょ, dakuten, long vowels
**vocab_domains:** script anchors (あさ, みず, ねこ…)
**mistake_patterns:** は-as-wa confusion · long-vs-short vowel (おばさん/おばあさん) · し=shi not si · stroke-order inversions
**scaffold:** row-song (あかさたな…) → trace w/ stroke anim → minimal-pair audio
**assessment:** kana recognition MC (all 46 + 25 voiced/combo) ≥90%; finger-write 10 random kana pass by stroke-match

### L0.2 কাতাকানা — ☑
`level:L0 · prereq:[L0.1] · exam:foundation · whitelist:jft_a2 · lessons:katakana.json · book:Ch.2 · words:46+10`
**can_do (bn):** ৪৬টি কাতাকানা পড়া ও লেখা; নিজের নাম লেখা **(en):** Read/write 46 katakana; write own name
**grammar:** ー long-vowel mark; foreign-sound combos (ファ, ティ…)
**vocab_domains:** loanwords daily life (コーヒー, バス, コンビニ, スマホ…)
**mistake_patterns:** シ/ツ/ソ/ン shape confusion · reading loanwords as English · dropping ー (ビル/ビール)
**scaffold:** hiragana↔katakana pairing → shape-family drill (シン vs ツソ) → name-building wizard
**assessment:** recognition ≥90%; write own name + バングラデシュ correctly

### L0.3 সংখ্যা ও সময় — ◐ (numbers/time JSONs are stubs — expand to spec)
`level:L0 · prereq:[L0.1] · exam:foundation · whitelist:jft_a2 · lessons:lesson_numbers.json, lesson_time.json · book:Ch.3 · words:40`
**can_do (bn):** সংখ্যা, দাম, সময় ও বার বলা **(en):** Say numbers, prices, time, days
**grammar:** number composition (compositional 1–99,999) · まん unit · 〜じ/〜ふん · counter preview
**vocab_domains:** numbers, えん, いくら, clock, weekdays
**mistake_patterns:** よじ/くじ exceptions · さんびゃく/ろっぴゃく sound changes · じゅう vs じゆう
**scaffold:** digit-builder blocks → price listening w/ screen fallback → clock drag
**assessment:** hear price → pick amount (8/10); say time from clock face (key-matched kana)

### A1.1 Greetings ও self-intro — ☑
`level:A1 · prereq:[L0.1] · exam:JFT-A1 · whitelist:jft_a2 · lessons:work_intro_01.json, lesson_greetings.json · book:Ch.4 · words:30`
**can_do (bn):** কর্মস্থলে নিজের পরিচয় দিতে পারা **(en):** Introduce yourself at work
**grammar:** AはBです · 〜じん · よろしくおねがいします formula · おじぎ pragmatics
**vocab_domains:** greetings full set (verified), self-intro
**mistake_patterns:** です misplaced (not sentence-final) · はじめまして repeated to same person · おはよう time-rule (first meeting, not morning)
**scaffold:** chunk the 4-line jikoshoukai → syllable slowdown → bow-timing video/anim
**assessment:** order word-blocks [わたし/は/名前/です]; produce full self-intro (speak, key: expected transcript)

### A1.2 নাম, দেশ, কাজ — ✍ (book Ch.5 is the authoring brief)
`level:A1 · prereq:[A1.1] · exam:JFT-A1 · whitelist:jft_a2 · lessons:TO-AUTHOR (lesson_intro_qa) · book:Ch.5 · words:35`
**can_do (bn):** নাম, দেশ ও পেশা জিজ্ঞেস ও বলা **(en):** Ask and give name, country, occupation
**grammar:** sentence+か question · はい/いいえ、ちがいます · の possession · から きました · さん rule
**vocab_domains:** occupations (かいしゃいん, ぎのうじっしゅうせい, とくていぎのう, かいごし…), countries
**mistake_patterns:** さん on own name · overusing あなた · の order inversion
**scaffold:** Q↔A flip cards → dorm-intro roleplay tree
**assessment:** build 3 questions (blocks); answer 3 asked (MC + speak)

### A1.3 Konbini — ☑
`level:A1 · prereq:[L0.3] · exam:JFT-A1 · whitelist:jft_a2 · lessons:lesson_konbini.json, lesson_shopping.json · book:Ch.6 · words:40`
**can_do (bn):** দোকানে কেনাকাটা করা **(en):** Buy something at a store
**grammar:** これ/それ/あれ/どれ · を object · で means (カードで) · ください vs おねがいします
**vocab_domains:** verified shopping set (これをください, ふくろ, げんきん, レシート…) + konbini foods
**mistake_patterns:** これ for far objects · だいじょうぶです ambiguity (=no thanks) · money-tray etiquette (cultural, non-graded note)
**scaffold:** cashier-question listening set (3 standard Qs) → counter roleplay
**assessment:** scenario: complete purchase (4-turn scripted tree, key-matched); listening: pick what cashier asked (8/10)

### A1.4 Restaurant — ☑ (restaurant_01 stub + book Ch.7 = expansion brief)
`level:A1 · prereq:[A1.3] · exam:JFT-A1 · whitelist:jft_a2 · lessons:restaurant_01.json (stub) · book:Ch.7 · words:40`
**can_do (bn):** খাবার order, বিল চাওয়া **(en):** Order food, ask for the bill
**grammar:** [item]を[count]ください · と linking · generic counters ひとつ〜いつつ · いただきます/ごちそうさま pragmatics
**vocab_domains:** menu items, おすすめ (verified), おかいけい, halal-check phrase ぶたにくははいっていますか
**mistake_patterns:** counter dropped · tipping/etiquette notes · すみません to call staff (not clap/boy!)
**scaffold:** menu-picture ordering → count-builder → full meal roleplay
**assessment:** order 2 items w/ counts (blocks+speak); halal question production (key match)

### A2.1 কাজ ও ছুটি — ☑
`level:A2 · prereq:[A1.1] · exam:JFT-A2 · whitelist:jft_a2 · lessons:workplace_01.json, lesson_work_requests.json(part) · book:Ch.8 · words:45`
**can_do (bn):** সহকর্মীকে অভিবাদন, ছুটি/দেরি জানানো **(en):** Greet coworkers, request leave, report lateness
**grammar:** ます/ません present-future · time-に vs place-で · やすんでもいいですか (chunk) · おさきに しつれいします pragmatics
**vocab_domains:** workplace verbs (はたらきます, はじめます, おわります), やすみ, おくれます, きゅうけい
**mistake_patterns:** で/に swap (mist: place-action needs で) · announcing leave instead of asking · silent lateness (culture-critical: 報連相)
**scaffold:** morning-routine script → leave-request dialogue tree w/ reason slot
**assessment:** LINE-style lateness message (blocks); leave request (speak, key); で/に gap-fill 8/10

### A2.2 ক্লিনিক ও স্বাস্থ্য — ☑
`level:A2 · prereq:[A1.2] · exam:JFT-A2 · whitelist:jft_a2 · lessons:lesson_clinic.json(stub), lesson_emergency.json · book:Ch.9 · words:45`
**can_do (bn):** অসুস্থতা বোঝানো, জরুরি সাহায্য **(en):** Explain illness, get emergency help
**grammar:** [body]がいたいです · がある/がでる symptoms · 〜たいです want · いつから+time-から · も
**vocab_domains:** verified emergency set (たすけて, きゅうきゅうしゃ, けいさつ, じしん…), body parts ×9, symptoms
**mistake_patterns:** びょういん/びよういん minimal pair · pain without location · 119 vs 110 swap (safety-critical — drill to 100%)
**scaffold:** body-map tap → symptom builder ([part]+が+いたい) → emergency call sim
**assessment:** emergency drill 3/3 at 100% (safety exception to 80% bar) · clinic dialogue (symptom+since+want) key-matched

### A2.3 রাস্তা ও যাতায়াত — ☑ (lessons exist; link into curriculum.json lesson_id at T-120)
`level:A2 · prereq:[L0.3] · exam:JFT-A2 · whitelist:jft_a2 · lessons:lesson_directions.json, lesson_transport.json · book:Ch.10 · words:50`
**can_do (bn):** রাস্তা জিজ্ঞেস, ট্রেন/স্টেশন ব্যবহার **(en):** Ask directions, use trains/stations
**grammar:** あります/います animacy · [place]に[thing]があります · direction-answer chunks (いって/まがって) · かかります duration/cost
**vocab_domains:** verified directions+transport sets (16 items), direction words, IC card domain
**mistake_patterns:** あります/います swap · nodding-without-understanding (teach もういちど おねがいします recovery) · local/express train trap
**scaffold:** map-trace listening (follow instructions on mini-map) → station staff roleplay
**assessment:** listening: follow 2-step directions on map (6/8); produce 3 transport questions (key)

### A2.4 অনুমতি ও অনুরোধ — ☑ (lesson_work_requests covers core; extend per book Ch.11)
`level:A2 · prereq:[A2.1] · exam:JFT-A2 · whitelist:jft_a2 · lessons:lesson_work_requests.json · book:Ch.11 · words:40`
**can_do (bn):** 〜てもいいですか / 〜てください ব্যবহার **(en):** Ask permission and make requests
**grammar:** て+もいいですか · て+ください · ない+でください · ちょっと… = soft no · these as CHUNKS (rule-machinery deferred to N4.1 — i+1!)
**vocab_domains:** verified request set (もういちど, ゆっくり, てつだって, これでいいですか…)
**mistake_patterns:** commanding tone w/ ください · pushing past ちょっと… · skipping しつもんがあります opener
**scaffold:** 5-step learning script (ask→show→slow→do→confirm) as guided scenario
**assessment:** permission vs request sort (10/10 MC); produce both forms for 3 verbs (chunk bank provided)

### A2.5 অতীত ও পরিকল্পনা — ✍ (smalltalk lesson = partial; book Ch.12 = brief)
`level:A2 · prereq:[A2.4] · exam:JFT-A2 · whitelist:jft_a2 · lessons:lesson_smalltalk.json(part) + TO-AUTHOR (lesson_past_plans) · book:Ch.12 · words:45`
**can_do (bn):** 〜ました / 〜ます দিয়ে অতীত ও plan বলা **(en):** Talk about what you did / will do
**grammar:** ました/ませんでした · time-words · ね/よ particles · い-adj past 〜かった · weekend-story formula [সাথে]と[কোথায়]で[কী]をしました
**vocab_domains:** verified smalltalk set + activities (かいもの, えいが, クリケット…)
**mistake_patterns:** しますした× (suru past) · ね/よ swap · one-word answers (pragmatics: extend to sentence)
**scaffold:** timeline-tap (きのう/きょう/あした) → story-builder slots
**assessment:** convert 5 verbs to past (blocks); tell weekend 3-sentence story (speak, template-keyed)

### A2.6 সমস্যা ও ক্ষমা — ☑ (safety lesson exists; apology core from book Ch.13)
`level:A2 · prereq:[A2.1] · exam:JFT-A2 · whitelist:jft_a2 · lessons:lesson_work_safety.json + TO-AUTHOR (lesson_apology) · book:Ch.13 · words:40`
**can_do (bn):** কাজের সমস্যা বোঝানো, ক্ষমা চাওয়া **(en):** Report a work problem and apologize
**grammar:** apology ladder (すみません→ごめんなさい→もうしわけありません) · report formula すみません+[what]+もうしわけありません · てしまいました (chunk preview) · 禁止 sign-reading
**vocab_domains:** verified safety set ×8 + mistake verbs (まちがえました, こわれました, おとしました, わすれました)
**mistake_patterns:** excuse-before-apology order · ごめんなさい to boss · hiding injury (safety-critical note けが+労災)
**scaffold:** 30-second-after-mistake script drill → apology-level sorter
**assessment:** report drill 3 scenarios (formula key); safety-sign MC 10/10 (safety bar); apology-level match 6/6

### A2.M JFT-Basic Mock — ✍ (engine: AiCheckScreen → real mock per NEXT DO-6)
`level:A2 · prereq:[A2.1..A2.6 all] · exam:JFT-Basic · whitelist:jft_a2 · lessons:mock spec below · book:Ch.14 · words:0`
**can_do (bn):** আসল CBT format-এ mock দেওয়া **(en):** Take a full mock in real CBT format
**mock spec:** 4 sections ×12 Q · 60 min timer · item pool sampled ONLY from verified lesson content + this curriculum's vocab · grading = answer key · report per-section % + band estimate (145/175/200 cut lines) + weakest-2 can_dos → Director queues those units for review. Banglish result copy from fixed templates ("Listening এ আরেকটু সময় দিলে ২০০ পেরোবে — এই সপ্তাহে শোনার drill গুলো করি?") — no shame variants exist.

### N4.1 て-form — ✍
`level:N4 · prereq:[A2.5] · exam:JLPT-N4 · whitelist:n4 · lessons:TO-AUTHOR · book:Ch.15 · words:50`
**can_do (bn):** ধারাবাহিক কাজ বলা **(en):** Link actions with te-form
**grammar:** 3 verb groups · て rules (って/んで/いて/いで/して + いって exception) · sequence te-chaining · ています progressive/state · retro-explains A2.4 chunks
**mistake_patterns:** group misclassification (ります→group1 hint) · いきます→いきて× · over-chaining >3
**scaffold:** group-sorter game → te-song (って×3 んで×3) → morning-routine builder
**assessment:** convert 10 verbs (8/10); chain 3 actions (blocks); ています production ×3

### N4.2 Plain form — ✍
`level:N4 · prereq:[N4.1] · exam:JLPT-N4 · whitelist:n4 · lessons:TO-AUTHOR · book:Ch.16 · words:50`
**can_do (bn):** casual কথা বলা ও বোঝা **(en):** Speak casually with friends
**grammar:** dict form = plain · た from て · ない form · だ/じゃない · plain+とおもいます/まえに/かもしれません · register radar (who gets plain)
**mistake_patterns:** plain to boss (pragmatic-critical) · おいしいだ× · staying stiff with friends
**scaffold:** LINE-chat simulator (reading casual) → polite↔plain flip drill
**assessment:** flip 10 both directions (8/10); register judgment MC (boss/friend scenarios) 9/10

### N4.3 Potential — ✍
`level:N4 · prereq:[N4.1] · exam:JLPT-N4 · whitelist:n4 · lessons:TO-AUTHOR · book:Ch.17 · words:45`
**can_do (bn):** কী করতে পারি বলা **(en):** Say what you can do
**grammar:** noun+ができます · potential conjugation (group rules) · を→が shift · honest-CV pragmatics (できません+でも べんきょうしています)
**mistake_patterns:** をできます× · false はい under pressure · ら-dropping (recognize れる, produce られる)
**scaffold:** skill-inventory builder (real user skills) → interview roleplay
**assessment:** conjugate 6 (5/6); produce 3 real can/cannot statements (template key)

### N4.4 দেওয়া-নেওয়া — ✍
`level:N4 · prereq:[N4.2] · exam:JLPT-N4 · whitelist:n4 · lessons:TO-AUTHOR · book:Ch.18 · words:40`
**can_do (bn):** あげる/もらう/くれる ব্যবহার **(en):** Express giving and receiving
**grammar:** 3-verb direction system (くれる=toward-me) · て+trio benefactives · [giver]に/から もらう · おみやげ pragmatics
**mistake_patterns:** あげる for toward-me× · もらう particle · してあげます to superiors (condescension trap)
**scaffold:** arrow-diagram drag (who→whom) → gratitude-story prompts
**assessment:** pick verb for 6 arrowed scenes (6/6); produce 2 てくれました real sentences

### N4.5 Keigo পরিচিতি — ✍
`level:N4 · prereq:[N4.2] · exam:JLPT-N4 · whitelist:n4 · lessons:TO-AUTHOR · book:Ch.19 · words:45`
**can_do (bn):** ভদ্র service-ভাষা ব্যবহার **(en):** Use polite service language with customers
**grammar:** 3 branches (teineigo/sonkeigo/kenjougo) · big-five exchanges · service-set as chunks · self-humble/other-honor rule
**mistake_patterns:** honorific on own action (めしあがります for self×) · keigo panic (fallback rule: correct です・ます beats broken keigo) · service-set to friends
**scaffold:** branch-sorter → konbini-shift roleplay (user plays STAFF side — perspective flip)
**assessment:** branch ID 8/10; service-set sequence 4/4 (chunk key); keigo self-intro production

### N4.M JLPT N4 Mock — ✍
`level:N4 · prereq:[N4.1..N4.5 all] · exam:JLPT-N4 · whitelist:n4 · lessons:mock spec · book:Ch.20 · words:0`
**can_do (bn):** N4 format-এ full mock **(en):** Take a full N4 mock
**mock spec:** 3 sections (vocab / grammar-reading / listening) scaled ×60 · per-section minimum flags (mirror real fail rule) · timer per section · pool: n4 whitelist + Ch.15–19 grammar keys · report: 180-scale estimate + section bars + weakest-2 can_dos → Director. Same fixed-template Banglish result copy policy as A2.M.

## 7. SRS & rewards policy

- **Scheduler:** FSRS-4.5 (lib/domain/fsrs.dart) — untouched by classroom; classroom only feeds ratings.
- **Card entry:** an item's recognition card enters on first correct recognition; production card on first completed production (skip ≠ entry, no penalty — item simply re-offered later).
- **Card types:** recognition (JP→BN) + production (BN→JP) per 05 SRS schema; mood affects *selection* only, never FSRS math (D-003).
- **Due handling in classroom:** session opens with due review (template §3); Sensei frames review as "দেখা-সাক্ষাৎ" not debt: "আজ ৭টা পুরনো বন্ধু অপেক্ষা করছে।" Never "overdue/পিছিয়ে গেছ" copy.
- **Rewards (fixed, mastery-tied, D-001):** correct → instant ack · lesson complete → 10 XP · 10 lessons → milestone (passport-stamp motif per D-015) · 50 retained words → level · mock-readiness rise → SSW progress marker. No other reward exists; nothing is random.

## 8. Grading & assessment rules

1. Every graded item carries a deterministic key: exact string, kana-normalized match (romaji folded, ー/っ normalized), block order, or MC index. Speak items: expected_transcript match (Tier 2+ STT alignment; Tier 0–1 self-compare, ungraded).
2. Pass bars: default ≥80% per assessment; **safety-critical items 100%** (A2.2 emergency numbers, A2.6 safety signs) — retry freely, no penalty, but can_do not marked done below bar.
3. Wrong answer → correct form shown + mistake_pattern logged → remediation queue (Director). NEVER: red flash, streak-loss, shame copy.
4. can_do marked ✅ when its assessment passed once + its srs_words ≥70% retention at next review — mastery = performance + memory, matching "remembered because chosen" (01).
5. Mocks (A2.M/N4.M): item pools sampled from verified content only; results feed Director; certificates/bands are ESTIMATES, labeled honestly ("estimate — আসল exam এ কম-বেশি হতে পারে").

## 9. Sensei chat/talk behavior spec (D-013 surface 3)

**May:** re-explain current item from retrieved store (BOOK chapter anchor + lesson notes) · give ONE more example from whitelist vocab · play/slow pronunciation (TTS) · answer "why" with retrieved contrast notes · switch persona tone on request.
**May not:** grade · invent grammar rules or vocab outside whitelist · discuss off-curriculum topics (polite redirect template) · generate motivational copy outside the §4 pool · block exit (sheet dismissible always).

**Quick-chip contracts (SenseiChatSheet):**
- **আবার বুঝিয়ে দাও** → retrieve current item's grammar note (BOOK anchor) → paraphrase within whitelist → end with comprehension offer: "এবার কি একটু clear? আরেকভাবে বলব?"
- **একটা উদাহরণ** → retrieve next unused example from item's example pool (pre-authored; LLM may swap whitelist nouns only, e.g. コーヒー→おちゃ).
- **উচ্চারণ** → play TTS normal → slow → syllable breakdown text (scaffold ladder rung 2) → offer record-and-compare.
**Off-scope redirect (fixed):** "এটা আজকের lesson এর বাইরে — কিন্তু ভালো প্রশ্ন! [unit] এ পৌঁছালে এটা আসবে। এখনকার টায় ফিরি?"
**Voice mode:** STT in → same contracts; TTS out (Kokoro) — audio-first parity, offline (08).

## 10. Integration map (who reads what)

| Consumer | Reads | Notes |
|---|---|---|
| CurriculumScreenV4 (T-120) | curriculum.json units + this §6 for status/assessment copy | replace demo units; NO lock icons (§1.6); "চালিয়ে যাও" targets Director's recommended unit |
| BookScreenV4 reader (T-121) | classroom/BOOK.md | chapters keyed `unit:` in header line — deep-link lesson↔chapter both ways; render MD; Bengali-numeral chapter tiles already in UI |
| Sensei chat | §4 line pool, §9 contracts, BOOK anchors as RAG chunks | chunk BOOK.md by `## Chapter` + `### section` headings; tag chunks w/ unit id + whitelist_ref |
| Director | §3 sequencing algorithm + §6 DAG | today: pure-function config in lib/agents/director.dart; goal-maps (D-015) reorder emphasis only |
| AiCheckScreen → mocks | §6 A2.M/N4.M specs + §8.5 | replaces demo coin-flip (NEXT_SESSION DO-6) |
| validate_content.mjs (T-104) | §6 unit fields ↔ lesson JSONs | new lessons to author: lesson_intro_qa (A1.2), lesson_past_plans (A2.5), lesson_apology (A2.6), N4 set ×5; each must carry level/can_do_id/prereq/whitelist_ref per 05 |
| curriculum.json sync | §6 status column | A2.3 lesson_id null→lesson_directions,lesson_transport; A2.4→lesson_work_requests; A2.6 partial→lesson_work_safety (do at T-120 wiring, single commit) |

## 11. Authoring pipeline for remaining units

1. Book chapter (done — Ch.5,12,13-part,15–19) = pedagogical brief. 2. Draft lesson JSON per 05 schema (8+ items, all fields, srs_words) — vocab ONLY from whitelist_ref. 3. `node tools/validate_content.mjs` → 0 warnings. 4. Native BN-JP reviewer sign-off → `verified: true` (05 rule #10; book front-matter flips same flag). 5. Wire lesson_id into curriculum.json + this file's status. 6. Audio: record per 05 rules #2/#8 (1–10s opus) — batch at T-107 pipeline.
Priority order (completes JFT path first): A1.2 → A2.5 → A2.6-apology → A2.M engine → N4.1…N4.5 → N4.M.

## 12. Status & changelog

- v1 (2026-07-11): Full 20-unit specs authored against curriculum.json v1 + verified lesson JSONs. BOOK.md v1 written in lockstep (all 20 units have chapters; 8 have complete verified lesson JSONs, 4 partial/stubs, 8 to author). Register: Bengali-script Banglish throughout learner-facing copy. Exam facts current as of 2026-07 (incl. Aug-2026 JFT band change).
- Known follow-ups: native review pass · lesson JSONs per §11 · T-120/T-121 wiring · l10n of fixed copy pools into arb files.
