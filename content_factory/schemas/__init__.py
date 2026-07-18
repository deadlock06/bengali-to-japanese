"""SENSEI Content Factory — Pydantic schemas v4.2"""
from enum import Enum
from typing import List, Dict, Optional, Any
from pydantic import BaseModel, Field

class JlptLevel(str, Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"

class PartOfSpeech(str, Enum):
    NOUN = "noun"
    VERB = "verb"
    ADJECTIVE = "adjective"
    ADVERB = "adverb"
    PARTICLE = "particle"
    EXPRESSION = "expression"
    INTERJECTION = "interjection"
    PRONOUN = "pronoun"
    AUXILIARY = "auxiliary"
    COUNTER = "counter"

class CardType(str, Enum):
    VOCAB_RECOGNIZE = "vocab_recognize"
    VOCAB_RECALL = "vocab_recall"
    GRAMMAR_RECOGNITION = "grammar_recognition"
    GRAMMAR_PRODUCTION = "grammar_production"
    KANJI_MEANING = "kanji_meaning"
    KANJI_READING = "kanji_reading"
    KANJI_STROKE = "kanji_stroke"
    LISTENING = "listening"
    SPEAKING = "speaking"

class AudioType(str, Enum):
    VOCABULARY = "vocabulary"
    GRAMMAR = "grammar"
    LESSON = "lesson"
    FORCED_ALIGNMENT = "forced_alignment"

class ExamItemType(str, Enum):
    """Official JLPT exam item types (jlpt.jp "Composition of test items").
    Mirrors lib/domain/models.dart ItemType; drives item-type-granular mocks."""
    # Vocabulary
    KANJI_READING = "kanji_reading"
    ORTHOGRAPHY = "orthography"
    WORD_FORMATION = "word_formation"
    CONTEXTUAL = "contextual"
    PARAPHRASE = "paraphrase"
    USAGE = "usage"
    # Grammar
    GRAMMAR_FORM = "grammar_form"
    SENTENCE_COMPOSITION = "sentence_composition"
    TEXT_GRAMMAR = "text_grammar"
    # Reading
    READING_SHORT = "reading_short"
    READING_MID = "reading_mid"
    READING_LONG = "reading_long"
    READING_INTEGRATED = "reading_integrated"
    READING_THEMATIC = "reading_thematic"
    INFO_RETRIEVAL = "info_retrieval"
    # Listening
    LISTEN_TASK = "listen_task"
    LISTEN_KEYPOINT = "listen_keypoint"
    LISTEN_OUTLINE = "listen_outline"
    LISTEN_VERBAL = "listen_verbal"
    LISTEN_QUICK = "listen_quick"
    LISTEN_INTEGRATED = "listen_integrated"

# ─── Vocabulary ─────────────────────────────────────────────

class VocabularyItem(BaseModel):
    id: str
    japanese: str
    reading: str
    meaning_bengali: str
    meaning_english: Optional[str] = None
    part_of_speech: PartOfSpeech
    jlpt_level: JlptLevel
    example_japanese: List[str] = []
    example_reading: List[str] = []
    example_bengali: List[str] = []
    example_english: List[str] = []
    tags: List[str] = []
    frequency_rank: Optional[int] = None
    lesson_refs: List[str] = []
    audio_id: Optional[str] = None
    # Optional JLPT exam item-type tag → serialized as `item_type` in the app's
    # lesson JSON (lib/domain/models.dart LessonItem.itemType). Back-compatible.
    exam_item_type: Optional[ExamItemType] = None

# ─── Grammar ────────────────────────────────────────────────

class GrammarExample(BaseModel):
    japanese: str
    reading: Optional[str] = None
    bengali: Optional[str] = None
    english: Optional[str] = None
    highlights: List[Dict[str, Any]] = []

class GrammarPitfall(BaseModel):
    wrong: str
    why_bengali: str
    correction: str

class GrammarPoint(BaseModel):
    id: str
    title_japanese: str
    title_bengali: str
    structure_pattern: str
    explanation_bengali: str
    explanation_english: Optional[str] = None
    jlpt_level: JlptLevel
    prerequisite_ids: List[str] = []
    unlocks_ids: List[str] = []
    examples: List[GrammarExample] = []
    pitfalls: List[GrammarPitfall] = []
    related_vocab: List[str] = []
    lesson_refs: List[str] = []

# ─── Kanji ──────────────────────────────────────────────────

class KanjiStroke(BaseModel):
    stroke_number: int
    path: str
    stroke_type: str

class KanjiItem(BaseModel):
    id: str
    character: str
    meanings_bengali: List[str]
    meanings_english: List[str] = []
    onyomi: List[str] = []
    kunyomi: List[str] = []
    jlpt_level: JlptLevel
    stroke_count: int
    radical: str
    strokes: List[KanjiStroke] = []
    stroke_order_diagram: Optional[str] = None
    common_words: List[str] = []
    lesson_refs: List[str] = []

# ─── Lesson ─────────────────────────────────────────────────

class LessonBlock(BaseModel):
    block_type: str
    content_refs: List[str] = []
    duration_seconds: int
    instructions_bengali: str
    instructions_english: Optional[str] = None
    alignment_text: Optional[str] = None
    card_ids: List[str] = []

class Lesson(BaseModel):
    id: str
    title_bengali: str
    title_japanese: str
    title_english: Optional[str] = None
    jlpt_level: JlptLevel
    lesson_number: int
    prerequisite_lessons: List[str] = []
    blocks: List[LessonBlock] = []
    estimated_duration_minutes: int
    tags: List[str] = []
    new_vocab: List[str] = []
    new_grammar: List[str] = []
    new_kanji: List[str] = []

# ─── Card ───────────────────────────────────────────────────

class Card(BaseModel):
    id: str
    card_type: CardType
    source_id: str
    lesson_id: Optional[str] = None
    front_bengali: str
    front_japanese: Optional[str] = None
    front_audio_id: Optional[str] = None
    back_japanese: Optional[str] = None
    back_reading: Optional[str] = None
    back_bengali: str
    back_english: Optional[str] = None
    acceptable_answers: List[str] = []
    base_difficulty: float = 0.0
    tags: List[str] = []
    initial_state: Optional[Dict[str, Any]] = None

# ─── Audio ──────────────────────────────────────────────────

class AudioManifest(BaseModel):
    id: str
    audio_type: AudioType
    text_japanese: str
    text_reading: Optional[str] = None
    mp3_path: Optional[str] = None
    wav_path: Optional[str] = None
    duration_ms: int
    voice_id: str
    sample_rate: int = 24000
    source_vocab_id: Optional[str] = None
    source_grammar_id: Optional[str] = None
    source_lesson_id: Optional[str] = None
    is_forced_alignment: bool = False
    alignment_phonemes: Optional[str] = None

# ─── Content Pack ───────────────────────────────────────────

class ContentPack(BaseModel):
    pack_id: str
    version: str
    title_bengali: Optional[str] = None
    title_english: Optional[str] = None
    tier: int = 0
    checksum_sha256: str = ""
    estimated_size_mb: float = 0.0
    db_path: Optional[str] = None
    manifest: Dict[str, Any] = {}
