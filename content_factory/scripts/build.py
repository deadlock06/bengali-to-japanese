#!/usr/bin/env python3
"""SENSEI Content Factory — main build pipeline.

Usage:
    python -m scripts.build --sources sources/ --output output/ --tier 1

Pipeline stages:
    1. Load raw source files (JSON/YAML/CSV)
    2. Validate all content (deterministic, no LLM)
    3. Generate FSRS-4.5 cards
    4. Compile into SQLite DB
    5. Package into tiered distribution units
    6. Output checksums and P2P manifest
"""
import argparse
import json
import sys
from pathlib import Path
from typing import List, Dict, Any

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from schemas import (
    VocabularyItem, GrammarPoint, KanjiItem, Lesson,
    JlptLevel, PartOfSpeech, Card
)
from validators.vocabulary_validator import VocabularyValidator
from validators.grammar_validator import GrammarValidator
from validators.kanji_validator import KanjiValidator
from compilers.sqlite_compiler import SQLiteCompiler
from compilers.card_generator import CardGenerator
from packagers.tier_packager import TierPackager

class BuildPipeline:
    """End-to-end content factory pipeline."""

    def __init__(self, sources_dir: str, output_dir: str):
        self.sources_dir = Path(sources_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Validators
        self.vocab_validator = VocabularyValidator()
        self.grammar_validator = GrammarValidator()
        self.kanji_validator = KanjiValidator()

        # Compilers
        self.card_gen = CardGenerator()

    def load_json_sources(self, subdir: str, model_class) -> List[Any]:
        """Load all JSON files from a subdirectory and parse into model instances."""
        items = []
        source_path = self.sources_dir / subdir
        if not source_path.exists():
            print(f"  ⚠️  Source dir not found: {source_path}")
            return items

        for json_file in sorted(source_path.glob("*.json")):
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    data = json.load(f)

                # Support both single object and array of objects
                if isinstance(data, list):
                    for entry in data:
                        items.append(model_class(**entry))
                elif isinstance(data, dict):
                    items.append(model_class(**data))
            except Exception as e:
                print(f"  ❌ Failed to load {json_file}: {e}")

        print(f"  ✓ Loaded {len(items)} {model_class.__name__} items from {subdir}")
        return items

    def validate(self, vocab: List[VocabularyItem], grammar: List[GrammarPoint],
                 kanji: List[KanjiItem]) -> Dict[str, Any]:
        """Run all validators and report."""
        print("\n🔍 VALIDATION")

        valid_vocab, vocab_errors = self.vocab_validator.validate_batch(vocab)
        print(f"  Vocabulary: {len(valid_vocab)}/{len(vocab)} valid")
        if vocab_errors:
            for vid, errs in list(vocab_errors.items())[:5]:
                print(f"    {vid}: {errs}")

        valid_grammar, grammar_errors = self.grammar_validator.validate_batch(grammar)
        print(f"  Grammar: {len(valid_grammar)}/{len(grammar)} valid")
        if grammar_errors:
            for gid, errs in list(grammar_errors.items())[:5]:
                print(f"    {gid}: {errs}")

        valid_kanji, kanji_errors = self.kanji_validator.validate_batch(kanji)
        print(f"  Kanji: {len(valid_kanji)}/{len(kanji)} valid")
        if kanji_errors:
            for kid, errs in list(kanji_errors.items())[:5]:
                print(f"    {kid}: {errs}")

        return {
            "vocab": {"valid": valid_vocab, "errors": vocab_errors},
            "grammar": {"valid": valid_grammar, "errors": grammar_errors},
            "kanji": {"valid": valid_kanji, "errors": kanji_errors},
        }

    def compile(self, valid_vocab, valid_grammar, valid_kanji, valid_lessons) -> str:
        """Compile validated content into SQLite DB."""
        print("\n🔨 COMPILATION")

        db_path = self.output_dir / "sensei_content.db"

        with SQLiteCompiler(str(db_path)) as compiler:
            # Insert content
            compiler.insert_vocabulary(valid_vocab)
            compiler.insert_grammar(valid_grammar)
            compiler.insert_kanji(valid_kanji)
            compiler.insert_lessons(valid_lessons)

            # Generate and insert cards
            cards = self.card_gen.generate_all(valid_vocab, valid_grammar, valid_kanji)
            compiler.insert_cards(cards)

            # Metadata
            compiler.set_metadata("build_version", "1.0.0")
            compiler.set_metadata("content_factory", "sensei_v4.2")
            compiler.set_metadata("schema_frozen", "true")

            stats = compiler.get_stats()
            print(f"  ✓ Compiled DB: {db_path}")
            for table, count in stats.items():
                print(f"    {table}: {count} rows")

        return str(db_path)

    def package(self, db_path: str, tier: int) -> str:
        """Package compiled DB into tiered distribution unit."""
        print("\n📦 PACKAGING")

        packager = TierPackager(db_path, str(self.output_dir))

        if tier == 0:
            pack = packager.package_tier0_schema(
                pack_id="pak_sensei_base",
                version="1.0.0"
            )
        elif tier == 1:
            pack = packager.package_tier1(
                pack_id="pak_sensei_n5_core",
                version="1.0.0",
                title_bengali="JLPT N5 কোর কন্টেন্ট",
                title_english="JLPT N5 Core Content"
            )
        else:
            raise ValueError(f"Tier {tier} not yet implemented")

        print(f"  ✓ Packaged: {pack.pack_id}")
        print(f"    Size: {pack.estimated_size_mb:.2f} MB")
        print(f"    SHA256: {pack.checksum_sha256[:16]}...")

        return pack.pack_id

    def run(self, tier: int = 1) -> Dict[str, Any]:
        """Execute full pipeline."""
        print("=" * 60)
        print("SENSEI Content Factory v4.2")
        print("=" * 60)

        # Stage 1: Load
        print("\n📥 LOADING SOURCES")
        vocab = self.load_json_sources("vocabulary", VocabularyItem)
        grammar = self.load_json_sources("grammar", GrammarPoint)
        kanji = self.load_json_sources("kanji", KanjiItem)
        lessons = self.load_json_sources("lessons", Lesson)

        # Stage 2: Validate
        validation = self.validate(vocab, grammar, kanji)

        # Stage 3: Compile
        db_path = self.compile(
            validation["vocab"]["valid"],
            validation["grammar"]["valid"],
            validation["kanji"]["valid"],
            lessons
        )

        # Stage 4: Package
        pack_id = self.package(db_path, tier)

        print("\n" + "=" * 60)
        print("BUILD COMPLETE")
        print("=" * 60)

        return {
            "db_path": db_path,
            "pack_id": pack_id,
            "validation": validation,
        }


def main():
    parser = argparse.ArgumentParser(description="SENSEI Content Factory Build Pipeline")
    parser.add_argument("--sources", default="sources", help="Source content directory")
    parser.add_argument("--output", default="output", help="Output directory")
    parser.add_argument("--tier", type=int, default=1, choices=[0, 1, 2, 3, 4],
                        help="Tier level to package")
    args = parser.parse_args()

    pipeline = BuildPipeline(args.sources, args.output)
    result = pipeline.run(tier=args.tier)

    print(f"\nOutput: {result['db_path']}")
    print(f"Pack: {result['pack_id']}")


if __name__ == "__main__":
    main()
