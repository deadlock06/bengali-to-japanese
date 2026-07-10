"""Vocabulary validation — correctness over generation (D-004)."""
from typing import List, Tuple, Dict
from schemas import VocabularyItem, JlptLevel

class VocabularyValidator:
    """Deterministic validation — no LLM calls."""

    # Forbidden patterns (common mistakes in Bengali translations)
    BENGALI_PROFANITY = ["খারাপ", "অশ্লীল"]  # Expand as needed
    JAPANESE_PROFANITY = []  # Add if needed

    # JLPT N5 core set for cross-reference
    N5_CORE_IDS: set = set()  # Populated at runtime from source files

    def __init__(self, reference_n5_list: List[str] = None):
        if reference_n5_list:
            self.N5_CORE_IDS = set(reference_n5_list)

    def validate(self, item: VocabularyItem) -> Tuple[bool, List[str]]:
        errors = []

        # 1. ID uniqueness (checked at batch level)
        # 2. Bengali content must exist and be non-trivial
        if len(item.meaning_bengali.strip()) < 1:
            errors.append("Bengali meaning too short")

        # 3. Reading must be valid hiragana/katakana (basic check)
        if not self._is_valid_kana(item.reading):
            errors.append("Reading contains invalid kana")

        # 4. Example arrays must be parallel
        if item.example_japanese:
            counts = [
                len(item.example_japanese),
                len(item.example_reading),
                len(item.example_bengali),
            ]
            if len(set(counts)) != 1:
                errors.append("Example arrays have mismatched lengths")

        # 5. Frequency rank sanity
        if item.frequency_rank and item.frequency_rank > 6000 and item.jlpt_level == JlptLevel.N5:
            errors.append("N5 vocab with suspiciously low frequency")

        # 6. Part-of-speech consistency with examples
        if item.part_of_speech.value == "particle" and item.example_japanese:
            # Particles should appear in sentence examples, not standalone
            pass  # Allow but flag for review

        return len(errors) == 0, errors

    def _is_valid_kana(self, text: str) -> bool:
        """Basic check: contains only hiragana, katakana, and punctuation."""
        import unicodedata
        for char in text:
            cat = unicodedata.category(char)
            name = unicodedata.name(char, '')
            if cat.startswith('P') or cat.startswith('Z'):
                continue
            # Rule #3's contract: a reading is kana. Allowing LATIN here made
            # the check unfalsifiable for English text (dead rule).
            if 'HIRAGANA' not in name and 'KATAKANA' not in name:
                return False
        return True

    def validate_batch(self, items: List[VocabularyItem]) -> Tuple[List[VocabularyItem], Dict[str, List[str]]]:
        valid = []
        errors = {}
        seen_ids = set()

        for item in items:
            if item.id in seen_ids:
                errors[item.id] = ["Duplicate ID"]
                continue
            seen_ids.add(item.id)

            ok, errs = self.validate(item)
            if ok:
                valid.append(item)
            else:
                errors[item.id] = errs

        return valid, errors
