# classroom/ — AI Classroom content source (IMPORTANT — do not delete)

The two authoritative content files the AI Classroom hub (D-013) integrates:

| File | What | Integrates into |
|---|---|---|
| `BOOK.md` | **Bhasha Go** — the Bengali→Japanese book. 5 parts · 20 chapters (1:1 with curriculum units) · 10 appendices · answer key. Register: Bengali script + natural English mixing. | BookScreenV4 reader (**T-121**) + Sensei RAG chunks |
| `CURRICULUM.md` | The teaching curriculum & logic: 10 binding rules, ladder, 5-phase loop staging, psych-state playbook w/ pre-authored Banglish copy pools, 20 unit specs (grammar/mistakes/scaffold/assessment), mock specs, Sensei chat contracts, integration map. | Curriculum service (**T-120**) + Director config + AiCheckScreen mocks |

Chapter ↔ unit keying: each BOOK chapter header carries `unit: <id>`; CURRICULUM §6 carries `book:Ch.N` back-refs. Machine ontology stays `assets/curriculum/curriculum.json` (sync notes: CURRICULUM §10).

Status: v1, 2026-07-11. Verified-content rules apply (05): new JP material needs native BN-JP review before `verified: true`. Banned-pattern audit clean (D-001).
