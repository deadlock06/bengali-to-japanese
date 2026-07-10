"""Card generator — deterministic FSRS-4.5 card creation from content."""
from typing import List, Dict
from schemas import (
    VocabularyItem, GrammarPoint, KanjiItem, Lesson,
    Card, CardType
)

class CardGenerator:
    """Generates review cards with proper difficulty calibration. No LLM calls."""

    # Difficulty mapping: how hard is this card type for Bengali speakers?
    BASE_DIFFICULTY = {
        CardType.VOCAB_RECOGNIZE: -1.0,   # Easiest: see Japanese, pick Bengali
        CardType.VOCAB_RECALL: 0.5,       # Medium: see Bengali, write Japanese
        CardType.GRAMMAR_RECOGNITION: 0.0, # Medium: pick correct form
        CardType.GRAMMAR_PRODUCTION: 2.0,  # Hard: construct sentence
        CardType.KANJI_MEANING: 0.0,       # Medium: kanji -> meaning
        CardType.KANJI_READING: 1.5,      # Hard: kanji -> reading
        CardType.KANJI_STROKE: 2.5,       # Hardest: draw from memory (FIX-B)
        CardType.LISTENING: 1.0,          # Hard: audio -> meaning
        CardType.SPEAKING: 2.0,           # Hard: forced alignment (D-002)
    }

    def generate_from_vocab(self, item: VocabularyItem) -> List[Card]:
        """Generate 2-4 cards per vocabulary item."""
        cards = []
        base_tags = ["vocab", item.jlpt_level.value, item.part_of_speech.value]

        # Card 1: Recognition (Japanese → Bengali)
        cards.append(Card(
            id=f"crd_{item.id}_recognize",
            card_type=CardType.VOCAB_RECOGNIZE,
            source_id=item.id,
            front_japanese=item.japanese,
            front_bengali=f"এর অর্থ কী?",  # "What does this mean?"
            back_japanese=item.japanese,
            back_reading=item.reading,
            back_bengali=item.meaning_bengali,
            back_english=item.meaning_english,
            base_difficulty=self.BASE_DIFFICULTY[CardType.VOCAB_RECOGNIZE],
            tags=base_tags + ["recognize"]
        ))

        # Card 2: Recall (Bengali → Japanese)
        cards.append(Card(
            id=f"crd_{item.id}_recall",
            card_type=CardType.VOCAB_RECALL,
            source_id=item.id,
            front_bengali=f"বাংলায়: {item.meaning_bengali}",
            back_japanese=item.japanese,
            back_reading=item.reading,
            back_bengali=item.meaning_bengali,
            back_english=item.meaning_english,
            acceptable_answers=[item.japanese, item.reading],
            base_difficulty=self.BASE_DIFFICULTY[CardType.VOCAB_RECALL],
            tags=base_tags + ["recall"]
        ))

        # Card 3: Listening (if audio available)
        if item.audio_id:
            cards.append(Card(
                id=f"crd_{item.id}_listen",
                card_type=CardType.LISTENING,
                source_id=item.id,
                front_bengali="শুনুন এবং অর্থ বলুন",  # "Listen and say the meaning"
                front_audio_id=item.audio_id,
                back_japanese=item.japanese,
                back_reading=item.reading,
                back_bengali=item.meaning_bengali,
                base_difficulty=self.BASE_DIFFICULTY[CardType.LISTENING],
                tags=base_tags + ["listening"]
            ))

        # Card 4: Speaking (forced alignment)
        cards.append(Card(
            id=f"crd_{item.id}_speak",
            card_type=CardType.SPEAKING,
            source_id=item.id,
            front_bengali=f"উচ্চারণ করুন: {item.reading}",  # "Pronounce: ..."
            back_japanese=item.japanese,
            back_reading=item.reading,
            back_bengali=item.meaning_bengali,
            base_difficulty=self.BASE_DIFFICULTY[CardType.SPEAKING],
            tags=base_tags + ["speaking"]
        ))

        return cards

    def generate_from_grammar(self, item: GrammarPoint) -> List[Card]:
        """Generate 2-3 cards per grammar point."""
        cards = []
        base_tags = ["grammar", item.jlpt_level.value]

        # Card 1: Recognition — identify correct usage
        if item.examples:
            ex = item.examples[0]
            cards.append(Card(
                id=f"crd_{item.id}_recognize",
                card_type=CardType.GRAMMAR_RECOGNITION,
                source_id=item.id,
                front_bengali=f"সঠিক বাক্তি চিহ্নিত করুন",  # "Identify correct sentence"
                front_japanese=getattr(ex, "japanese", "") or "",
                back_bengali=getattr(ex, "bengali", None) or item.explanation_bengali,
                back_english=getattr(ex, "english", None),
                base_difficulty=self.BASE_DIFFICULTY[CardType.GRAMMAR_RECOGNITION],
                tags=base_tags + ["recognize"]
            ))

        # Card 2: Production — fill in blank
        # Extract pattern with blank
        pattern = item.structure_pattern.replace("[N]", "_____").replace("[V]", "_____").replace("[ADJ]", "_____")
        cards.append(Card(
            id=f"crd_{item.id}_produce",
            card_type=CardType.GRAMMAR_PRODUCTION,
            source_id=item.id,
            front_bengali=f"শূন্যস্থান পূরণ করুন: {pattern}",
            back_bengali=item.explanation_bengali,
            base_difficulty=self.BASE_DIFFICULTY[CardType.GRAMMAR_PRODUCTION],
            tags=base_tags + ["produce"]
        ))

        return cards

    def generate_from_kanji(self, item: KanjiItem) -> List[Card]:
        """Generate 2-3 cards per kanji."""
        cards = []
        base_tags = ["kanji", item.jlpt_level.value]

        # Card 1: Meaning (Kanji → Bengali)
        meaning_text = ", ".join(item.meanings_bengali[:2])
        cards.append(Card(
            id=f"crd_{item.id}_meaning",
            card_type=CardType.KANJI_MEANING,
            source_id=item.id,
            front_japanese=item.character,
            front_bengali="এর অর্থ কী?",
            back_bengali=meaning_text,
            base_difficulty=self.BASE_DIFFICULTY[CardType.KANJI_MEANING],
            tags=base_tags + ["meaning"]
        ))

        # Card 2: Reading (Kanji → onyomi/kunyomi)
        readings = item.onyomi + item.kunyomi
        if readings:
            cards.append(Card(
                id=f"crd_{item.id}_reading",
                card_type=CardType.KANJI_READING,
                source_id=item.id,
                front_japanese=item.character,
                front_bengali="পড়া কী?",  # "What is the reading?"
                back_reading=readings[0],
                back_bengali=meaning_text,
                acceptable_answers=readings,
                base_difficulty=self.BASE_DIFFICULTY[CardType.KANJI_READING],
                tags=base_tags + ["reading"]
            ))

        # Card 3: Stroke order (FIX-B)
        cards.append(Card(
            id=f"crd_{item.id}_stroke",
            card_type=CardType.KANJI_STROKE,
            source_id=item.id,
            front_bengali=f"{item.character} লিখুন ({item.stroke_count} টি stroke)",
            back_japanese=item.character,
            back_bengali=meaning_text,
            base_difficulty=self.BASE_DIFFICULTY[CardType.KANJI_STROKE],
            tags=base_tags + ["stroke"]
        ))

        return cards

    def generate_from_lesson(self, lesson: Lesson) -> List[Card]:
        """Generate review cards for all new content in a lesson."""
        # This is a stub — in production, lesson cards reference pre-generated vocab/grammar/kanji cards
        return []

    def generate_all(self, vocab: List[VocabularyItem], grammar: List[GrammarPoint],
                     kanji: List[KanjiItem]) -> List[Card]:
        """Generate complete card deck from all content."""
        all_cards = []
        for item in vocab:
            all_cards.extend(self.generate_from_vocab(item))
        for item in grammar:
            all_cards.extend(self.generate_from_grammar(item))
        for item in kanji:
            all_cards.extend(self.generate_from_kanji(item))
        return all_cards
