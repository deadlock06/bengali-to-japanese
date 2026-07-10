"""Unit tests for SENSEI content validators."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from schemas import VocabularyItem, GrammarPoint, KanjiItem, KanjiStroke, JlptLevel, PartOfSpeech
from validators.vocabulary_validator import VocabularyValidator
from validators.grammar_validator import GrammarValidator
from validators.kanji_validator import KanjiValidator

def test_vocab_validator():
    validator = VocabularyValidator()

    # Valid item
    valid = VocabularyItem(
        id="voc_test_1",
        japanese="テスト",
        reading="てすと",
        meaning_bengali="পরীক্ষা",
        meaning_english="test",
        part_of_speech=PartOfSpeech.NOUN,
        jlpt_level=JlptLevel.N5,
        example_japanese=["テストです"],
        example_reading=["てすとです"],
        example_bengali=["এটি পরীক্ষা"],
        example_english=["this is a test"]
    )
    ok, errs = validator.validate(valid)
    assert ok, f"Valid item failed: {errs}"

    # Invalid: mismatched examples
    invalid = VocabularyItem(
        id="voc_test_2",
        japanese="テスト",
        reading="てすと",
        meaning_bengali="পরীক্ষা",
        part_of_speech=PartOfSpeech.NOUN,
        jlpt_level=JlptLevel.N5,
        example_japanese=["テストです", "二つ目"],
        example_reading=["てすとです"],  # Mismatched!
        example_bengali=["এটি পরীক্ষা"]
    )
    ok, errs = validator.validate(invalid)
    assert not ok, "Should fail on mismatched examples"
    assert "mismatched" in str(errs).lower()

    # Invalid: bad kana
    bad_kana = VocabularyItem(
        id="voc_test_3",
        japanese="テスト",
        reading="test",  # Latin, not kana
        meaning_bengali="পরীক্ষা",
        part_of_speech=PartOfSpeech.NOUN,
        jlpt_level=JlptLevel.N5
    )
    ok, errs = validator.validate(bad_kana)
    assert not ok, "Should fail on non-kana reading"

    print("✓ VocabularyValidator: all tests passed")

def test_grammar_validator():
    validator = GrammarValidator()

    # Valid grammar
    valid = GrammarPoint(
        id="grm_test_1",
        title_japanese="〜は",
        title_bengali="বিষয় marker",
        structure_pattern="[N] + は + [V]",
        explanation_bengali="এটি একটি বিষয় marker যা বাক্যের বিষয় চিহ্নিত করে। এটি বাংলায় সরাসরি অনুবাদ হয় না।",
        jlpt_level=JlptLevel.N5,
        # Validator requires >= 2 examples showing variation.
        examples=[{
            "japanese": "私は学生",
            "reading": "わたしはがくせい",
            "bengali": "আমি ছাত্র",
            "english": "I am a student",
            "highlights": [{"start": 2, "end": 3, "color": "#ff0000"}]
        }, {
            "japanese": "これは本",
            "reading": "これはほん",
            "bengali": "এটি একটি বই",
            "english": "This is a book",
            "highlights": [{"start": 2, "end": 3, "color": "#ff0000"}]
        }],
        pitfalls=[{
            "wrong": "私が学生 (topic)",
            "why_bengali": "বিষয় চিহ্নিত করতে は ব্যবহার করতে হবে",
            "correction": "私は学生"
        }]
    )
    ok, errs = validator.validate(valid)
    assert ok, f"Valid grammar failed: {errs}"

    # Invalid: no placeholders
    no_pattern = GrammarPoint(
        id="grm_test_2",
        title_japanese="〜は",
        title_bengali="বিষয় marker",
        structure_pattern="noun wa verb",  # No [N] placeholder
        explanation_bengali="এটি একটি বিষয় marker।",
        jlpt_level=JlptLevel.N5,
        examples=[{"japanese": "test", "highlights": [{"start": 0, "end": 1, "color": "#ff0000"}]}],
        pitfalls=[]
    )
    ok, errs = validator.validate(no_pattern)
    assert not ok, "Should fail on missing placeholders"

    # Invalid: short explanation
    short_exp = GrammarPoint(
        id="grm_test_3",
        title_japanese="〜は",
        title_bengali="বিষয়",
        structure_pattern="[N] + は",
        explanation_bengali="ছোট",  # Too short
        jlpt_level=JlptLevel.N5,
        examples=[{"japanese": "test", "highlights": [{"start": 0, "end": 1, "color": "#ff0000"}]}],
        pitfalls=[]
    )
    ok, errs = validator.validate(short_exp)
    assert not ok, "Should fail on short explanation"

    print("✓ GrammarValidator: all tests passed")

def test_kanji_validator():
    validator = KanjiValidator()

    # Valid kanji
    valid = KanjiItem(
        id="kan_test_1",
        character="一",
        meanings_bengali=["এক"],
        onyomi=["いち"],
        kunyomi=["ひと"],
        jlpt_level=JlptLevel.N5,
        stroke_count=1,
        radical="一",
        strokes=[KanjiStroke(stroke_number=1, path="M 30 50 L 70 50", stroke_type="horizontal")]
    )
    ok, errs = validator.validate(valid)
    assert ok, f"Valid kanji failed: {errs}"

    # Invalid: stroke mismatch
    mismatch = KanjiItem(
        id="kan_test_2",
        character="二",
        meanings_bengali=["দুই"],
        onyomi=["に"],
        jlpt_level=JlptLevel.N5,
        stroke_count=2,
        radical="二",
        strokes=[KanjiStroke(stroke_number=1, path="M 30 35 L 70 35", stroke_type="horizontal")]
        # Only 1 stroke but count says 2
    )
    ok, errs = validator.validate(mismatch)
    assert not ok, "Should fail on stroke count mismatch"

    # Invalid: non-sequential strokes
    bad_order = KanjiItem(
        id="kan_test_3",
        character="三",
        meanings_bengali=["তিন"],
        onyomi=["さん"],
        jlpt_level=JlptLevel.N5,
        stroke_count=3,
        radical="一",
        strokes=[
            KanjiStroke(stroke_number=1, path="M 30 25 L 70 25", stroke_type="horizontal"),
            KanjiStroke(stroke_number=3, path="M 30 50 L 70 50", stroke_type="horizontal"),  # Skip 2
            KanjiStroke(stroke_number=2, path="M 30 75 L 70 75", stroke_type="horizontal")
        ]
    )
    ok, errs = validator.validate(bad_order)
    assert not ok, "Should fail on non-sequential strokes"

    print("✓ KanjiValidator: all tests passed")

def test_batch_validation():
    """Test batch validation with duplicates."""
    items = [
        VocabularyItem(id="voc_dup", japanese="A", reading="あ", meaning_bengali="এ", part_of_speech=PartOfSpeech.NOUN, jlpt_level=JlptLevel.N5),
        VocabularyItem(id="voc_dup", japanese="B", reading="い", meaning_bengali="ই", part_of_speech=PartOfSpeech.NOUN, jlpt_level=JlptLevel.N5),
    ]
    validator = VocabularyValidator()
    valid, errors = validator.validate_batch(items)
    assert len(valid) == 1, "Should accept first, reject duplicate"
    assert "voc_dup" in errors, "Should report duplicate"

    print("✓ Batch validation: all tests passed")

if __name__ == "__main__":
    test_vocab_validator()
    test_grammar_validator()
    test_kanji_validator()
    test_batch_validation()
    print("\n🎉 All validator tests passed!")
