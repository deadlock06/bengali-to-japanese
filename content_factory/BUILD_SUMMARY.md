# SENSEI Content Factory — Build Summary

## Build Info
- Date: 2026-07-10
- Pipeline: SENSEI Content Factory v4.2
- Tier: 1 (JLPT N5 Core)

## Content Stats
- Vocabulary: 20 items (20 valid)
- Grammar: 3 points (3 valid)
- Kanji: 5 characters (5 valid)
- Lessons: 3 lessons
- Cards: 81 generated

## Output
- Database: `output/sensei_content.db`
- Package: `pak_sensei_n5_core`
- Size: ~0.16 MB
- SHA256: see build output

## Files Reconstructed
The uploaded files had mismatched names/content. This build reconstructs the proper structure:
- `schemas/` — Pydantic v2 models (reconstructed from imports)
- `validators/` — Deterministic validators (no LLM)
- `compilers/` — SQLite compiler + Card generator
- `packagers/` — Tier packager
- `scripts/` — Build pipeline
- `sources/` — JSON content files
- `output/` — Compiled `.db` + manifest

## Fixes Applied
1. Relative imports → absolute imports for package-less execution
2. Pydantic v2 model access (`getattr` instead of dict `.get()`)
3. JSON serialization for Pydantic models in SQLite compiler
4. Bengali meaning length threshold lowered (single-char words like "না" are valid)
