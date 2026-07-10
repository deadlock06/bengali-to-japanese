"""Tier packager — packages compiled DB into distributable units."""
import hashlib
import json
from pathlib import Path
from typing import Dict, Any

from schemas import ContentPack

class TierPackager:
    """Packages SQLite DB into tiered content packs."""

    def __init__(self, db_path: str, output_dir: str):
        self.db_path = Path(db_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def _checksum(self, path: Path) -> str:
        """Compute SHA-256 of file."""
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()

    def _file_size_mb(self, path: Path) -> float:
        return path.stat().st_size / (1024 * 1024)

    def package_tier0_schema(self, pack_id: str, version: str) -> ContentPack:
        """Package schema-only tier 0."""
        manifest = {
            "tier": 0,
            "type": "schema",
            "description": "Base schema and empty tables",
        }
        return ContentPack(
            pack_id=pack_id,
            version=version,
            title_english="SENSEI Base Schema",
            tier=0,
            checksum_sha256=self._checksum(self.db_path),
            estimated_size_mb=self._file_size_mb(self.db_path),
            db_path=str(self.db_path),
            manifest=manifest
        )

    def package_tier1(self, pack_id: str, version: str,
                      title_bengali: str, title_english: str) -> ContentPack:
        """Package tier 1 content (N5 core)."""
        manifest = {
            "tier": 1,
            "type": "content",
            "jlpt_level": "N5",
            "description": "JLPT N5 core vocabulary, grammar, kanji, and lessons",
        }
        return ContentPack(
            pack_id=pack_id,
            version=version,
            title_bengali=title_bengali,
            title_english=title_english,
            tier=1,
            checksum_sha256=self._checksum(self.db_path),
            estimated_size_mb=self._file_size_mb(self.db_path),
            db_path=str(self.db_path),
            manifest=manifest
        )
