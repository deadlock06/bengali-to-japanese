"""SQLite compiler — converts validated schemas into app-ready .db files."""
import sqlite3
import json
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime

from schemas import (
    VocabularyItem, GrammarPoint, KanjiItem, 
    Lesson, Card, AudioManifest, ContentPack
)

class SQLiteCompiler:
    """Compiles all content into a single SQLite database for offline use."""

    SCHEMA_SQL = """
    -- Vocabulary table
    CREATE TABLE IF NOT EXISTS vocabulary (
        id TEXT PRIMARY KEY,
        japanese TEXT NOT NULL,
        reading TEXT NOT NULL,
        meaning_bengali TEXT NOT NULL,
        meaning_english TEXT,
        part_of_speech TEXT NOT NULL,
        jlpt_level TEXT NOT NULL,
        example_japanese TEXT,  -- JSON array
        example_reading TEXT,   -- JSON array
        example_bengali TEXT,   -- JSON array
        example_english TEXT,   -- JSON array
        tags TEXT,              -- JSON array
        frequency_rank INTEGER,
        lesson_refs TEXT,       -- JSON array
        audio_id TEXT
    );

    -- Grammar table
    CREATE TABLE IF NOT EXISTS grammar (
        id TEXT PRIMARY KEY,
        title_japanese TEXT NOT NULL,
        title_bengali TEXT NOT NULL,
        structure_pattern TEXT NOT NULL,
        explanation_bengali TEXT NOT NULL,
        explanation_english TEXT,
        jlpt_level TEXT NOT NULL,
        prerequisite_ids TEXT,  -- JSON array
        unlocks_ids TEXT,       -- JSON array
        examples TEXT,          -- JSON array
        pitfalls TEXT,          -- JSON array
        related_vocab TEXT,     -- JSON array
        lesson_refs TEXT        -- JSON array
    );

    -- Kanji table
    CREATE TABLE IF NOT EXISTS kanji (
        id TEXT PRIMARY KEY,
        character TEXT NOT NULL UNIQUE,
        meanings_bengali TEXT NOT NULL,  -- JSON array
        meanings_english TEXT,           -- JSON array
        onyomi TEXT,                     -- JSON array
        kunyomi TEXT,                    -- JSON array
        jlpt_level TEXT NOT NULL,
        stroke_count INTEGER NOT NULL,
        radical TEXT NOT NULL,
        strokes TEXT,                    -- JSON array of {stroke_number, path, stroke_type}
        stroke_order_diagram TEXT,
        common_words TEXT,               -- JSON array
        lesson_refs TEXT                 -- JSON array
    );

    -- Lessons table
    CREATE TABLE IF NOT EXISTS lessons (
        id TEXT PRIMARY KEY,
        title_bengali TEXT NOT NULL,
        title_japanese TEXT NOT NULL,
        title_english TEXT,
        jlpt_level TEXT NOT NULL,
        lesson_number INTEGER NOT NULL,
        prerequisite_lessons TEXT,  -- JSON array
        blocks TEXT,                -- JSON array
        estimated_duration_minutes INTEGER NOT NULL,
        tags TEXT,                  -- JSON array
        new_vocab TEXT,             -- JSON array
        new_grammar TEXT,           -- JSON array
        new_kanji TEXT              -- JSON array
    );

    -- Cards table (FSRS-4.5)
    CREATE TABLE IF NOT EXISTS cards (
        id TEXT PRIMARY KEY,
        card_type TEXT NOT NULL,
        source_id TEXT NOT NULL,
        lesson_id TEXT,
        front_bengali TEXT NOT NULL,
        front_japanese TEXT,
        front_audio_id TEXT,
        back_japanese TEXT,
        back_reading TEXT,
        back_bengali TEXT NOT NULL,
        back_english TEXT,
        acceptable_answers TEXT,    -- JSON array
        base_difficulty REAL DEFAULT 0.0,
        tags TEXT,                  -- JSON array
        initial_state TEXT          -- JSON object (FSRS params)
    );

    -- Audio manifest table
    CREATE TABLE IF NOT EXISTS audio_manifests (
        id TEXT PRIMARY KEY,
        audio_type TEXT NOT NULL,
        text_japanese TEXT NOT NULL,
        text_reading TEXT,
        mp3_path TEXT,
        wav_path TEXT,
        duration_ms INTEGER NOT NULL,
        voice_id TEXT NOT NULL,
        sample_rate INTEGER DEFAULT 24000,
        source_vocab_id TEXT,
        source_grammar_id TEXT,
        source_lesson_id TEXT,
        is_forced_alignment INTEGER DEFAULT 0,
        alignment_phonemes TEXT
    );

    -- Metadata table
    CREATE TABLE IF NOT EXISTS metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );

    -- Indices for performance
    CREATE INDEX IF NOT EXISTS idx_vocab_jlpt ON vocabulary(jlpt_level);
    CREATE INDEX IF NOT EXISTS idx_vocab_pos ON vocabulary(part_of_speech);
    CREATE INDEX IF NOT EXISTS idx_grammar_jlpt ON grammar(jlpt_level);
    CREATE INDEX IF NOT EXISTS idx_kanji_jlpt ON kanji(jlpt_level);
    CREATE INDEX IF NOT EXISTS idx_lessons_jlpt ON lessons(jlpt_level);
    CREATE INDEX IF NOT EXISTS idx_cards_type ON cards(card_type);
    CREATE INDEX IF NOT EXISTS idx_cards_source ON cards(source_id);
    """

    def __init__(self, db_path: str):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(str(self.db_path))
        self.conn.row_factory = sqlite3.Row
        self._init_schema()

    def _init_schema(self):
        """Create tables and indices."""
        self.conn.executescript(self.SCHEMA_SQL)
        self.conn.commit()

    def _to_json(self, obj: Any) -> str:
        """Serialize lists/dicts/Pydantic models to JSON."""
        if obj is None:
            return None
        # Handle Pydantic v2 models
        if hasattr(obj, "model_dump"):
            return json.dumps(obj.model_dump(), ensure_ascii=False)
        # Handle lists of Pydantic models
        if isinstance(obj, list) and obj and hasattr(obj[0], "model_dump"):
            return json.dumps([item.model_dump() for item in obj], ensure_ascii=False)
        return json.dumps(obj, ensure_ascii=False)

    def insert_vocabulary(self, items: List[VocabularyItem]) -> int:
        """Insert validated vocabulary items."""
        cursor = self.conn.cursor()
        for item in items:
            cursor.execute("""
                INSERT OR REPLACE INTO vocabulary 
                (id, japanese, reading, meaning_bengali, meaning_english, part_of_speech,
                 jlpt_level, example_japanese, example_reading, example_bengali, example_english,
                 tags, frequency_rank, lesson_refs, audio_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item.id, item.japanese, item.reading, item.meaning_bengali,
                item.meaning_english, item.part_of_speech.value, item.jlpt_level.value,
                self._to_json(item.example_japanese), self._to_json(item.example_reading),
                self._to_json(item.example_bengali), self._to_json(item.example_english),
                self._to_json(item.tags), item.frequency_rank,
                self._to_json(item.lesson_refs), item.audio_id
            ))
        self.conn.commit()
        return len(items)

    def insert_grammar(self, items: List[GrammarPoint]) -> int:
        cursor = self.conn.cursor()
        for item in items:
            cursor.execute("""
                INSERT OR REPLACE INTO grammar
                (id, title_japanese, title_bengali, structure_pattern, explanation_bengali,
                 explanation_english, jlpt_level, prerequisite_ids, unlocks_ids, examples,
                 pitfalls, related_vocab, lesson_refs)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item.id, item.title_japanese, item.title_bengali, item.structure_pattern,
                item.explanation_bengali, item.explanation_english, item.jlpt_level.value,
                self._to_json(item.prerequisite_ids), self._to_json(item.unlocks_ids),
                self._to_json(item.examples), self._to_json(item.pitfalls),
                self._to_json(item.related_vocab), self._to_json(item.lesson_refs)
            ))
        self.conn.commit()
        return len(items)

    def insert_kanji(self, items: List[KanjiItem]) -> int:
        cursor = self.conn.cursor()
        for item in items:
            strokes_json = [{
                "stroke_number": s.stroke_number,
                "path": s.path,
                "stroke_type": s.stroke_type
            } for s in item.strokes]
            cursor.execute("""
                INSERT OR REPLACE INTO kanji
                (id, character, meanings_bengali, meanings_english, onyomi, kunyomi,
                 jlpt_level, stroke_count, radical, strokes, stroke_order_diagram,
                 common_words, lesson_refs)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item.id, item.character, self._to_json(item.meanings_bengali),
                self._to_json(item.meanings_english), self._to_json(item.onyomi),
                self._to_json(item.kunyomi), item.jlpt_level.value, item.stroke_count,
                item.radical, self._to_json(strokes_json), item.stroke_order_diagram,
                self._to_json(item.common_words), self._to_json(item.lesson_refs)
            ))
        self.conn.commit()
        return len(items)

    def insert_lessons(self, items: List[Lesson]) -> int:
        cursor = self.conn.cursor()
        for item in items:
            blocks_json = [b.model_dump() for b in item.blocks]
            cursor.execute("""
                INSERT OR REPLACE INTO lessons
                (id, title_bengali, title_japanese, title_english, jlpt_level,
                 lesson_number, prerequisite_lessons, blocks, estimated_duration_minutes,
                 tags, new_vocab, new_grammar, new_kanji)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item.id, item.title_bengali, item.title_japanese, item.title_english,
                item.jlpt_level.value, item.lesson_number,
                self._to_json(item.prerequisite_lessons), self._to_json(blocks_json),
                item.estimated_duration_minutes, self._to_json(item.tags),
                self._to_json(item.new_vocab), self._to_json(item.new_grammar),
                self._to_json(item.new_kanji)
            ))
        self.conn.commit()
        return len(items)

    def insert_cards(self, items: List[Card]) -> int:
        cursor = self.conn.cursor()
        for item in items:
            cursor.execute("""
                INSERT OR REPLACE INTO cards
                (id, card_type, source_id, lesson_id, front_bengali, front_japanese,
                 front_audio_id, back_japanese, back_reading, back_bengali, back_english,
                 acceptable_answers, base_difficulty, tags, initial_state)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item.id, item.card_type.value, item.source_id, item.lesson_id,
                item.front_bengali, item.front_japanese, item.front_audio_id,
                item.back_japanese, item.back_reading, item.back_bengali,
                item.back_english, self._to_json(item.acceptable_answers),
                item.base_difficulty, self._to_json(item.tags),
                self._to_json(item.initial_state)
            ))
        self.conn.commit()
        return len(items)

    def insert_audio_manifests(self, items: List[AudioManifest]) -> int:
        cursor = self.conn.cursor()
        for item in items:
            cursor.execute("""
                INSERT OR REPLACE INTO audio_manifests
                (id, audio_type, text_japanese, text_reading, mp3_path, wav_path,
                 duration_ms, voice_id, sample_rate, source_vocab_id, source_grammar_id,
                 source_lesson_id, is_forced_alignment, alignment_phonemes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item.id, item.audio_type.value, item.text_japanese, item.text_reading,
                item.mp3_path, item.wav_path, item.duration_ms, item.voice_id,
                item.sample_rate, item.source_vocab_id, item.source_grammar_id,
                item.source_lesson_id, int(item.is_forced_alignment), item.alignment_phonemes
            ))
        self.conn.commit()
        return len(items)

    def set_metadata(self, key: str, value: str):
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO metadata (key, value, updated_at)
            VALUES (?, ?, ?)
        """, (key, value, datetime.utcnow().isoformat()))
        self.conn.commit()

    def get_stats(self) -> Dict[str, int]:
        """Return row counts for all tables."""
        cursor = self.conn.cursor()
        tables = ["vocabulary", "grammar", "kanji", "lessons", "cards", "audio_manifests"]
        stats = {}
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            stats[table] = cursor.fetchone()[0]
        return stats

    def close(self):
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
