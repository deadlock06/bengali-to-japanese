"""Kanji validation — stroke data integrity (FIX-B)."""
from typing import List, Tuple, Dict
from schemas import KanjiItem

class KanjiValidator:
    """Validates KanjiVG-derived stroke data."""

    def validate(self, item: KanjiItem) -> Tuple[bool, List[str]]:
        errors = []

        # 1. Stroke count must match strokes array
        if item.stroke_count != len(item.strokes):
            errors.append(f"stroke_count ({item.stroke_count}) != len(strokes) ({len(item.strokes)})")

        # 2. Stroke numbers must be sequential
        expected = list(range(1, item.stroke_count + 1))
        actual = [s.stroke_number for s in item.strokes]
        if actual != expected:
            errors.append(f"Stroke numbers not sequential: {actual}")

        # 3. Each stroke must have valid path data
        for i, stroke in enumerate(item.strokes):
            if not stroke.path or len(stroke.path) < 5:
                errors.append(f"Stroke {i+1} path too short")
            if not stroke.path.startswith(("M", "m")):
                errors.append(f"Stroke {i+1} path missing move command")

        # 4. Must have at least one meaning in Bengali
        if not item.meanings_bengali:
            errors.append("Missing Bengali meanings")

        # 5. Must have at least one reading
        if not item.onyomi and not item.kunyomi:
            errors.append("No readings provided")

        # 6. Radical must be single character
        if len(item.radical) != 1:
            errors.append("Radical must be exactly 1 character")

        return len(errors) == 0, errors

    def validate_batch(self, items: List[KanjiItem]) -> Tuple[List[KanjiItem], Dict[str, List[str]]]:
        valid = []
        errors = {}
        seen_chars = set()

        for item in items:
            if item.character in seen_chars:
                errors[item.id] = [f"Duplicate kanji character: {item.character}"]
                continue
            seen_chars.add(item.character)

            ok, errs = self.validate(item)
            if ok:
                valid.append(item)
            else:
                errors[item.id] = errs

        return valid, errors
