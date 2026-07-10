"""Grammar validation — structural pattern enforcement."""
from typing import List, Tuple, Dict
from schemas import GrammarPoint

class GrammarValidator:
    """Ensures grammar explanations teach structure, not just translation."""

    # Required pattern markers in structure_pattern
    PATTERN_MARKERS = ["[", "]", "+", "→"]

    def validate(self, item: GrammarPoint) -> Tuple[bool, List[str]]:
        errors = []

        # 1. Structure pattern must contain placeholders
        if not any(m in item.structure_pattern for m in self.PATTERN_MARKERS):
            errors.append("structure_pattern missing placeholders [N], [V], etc.")

        # 2. Bengali explanation must be substantial
        if len(item.explanation_bengali.strip()) < 50:
            errors.append("Bengali explanation too short (< 50 chars)")

        # 3. Must have at least 2 examples showing variation
        if len(item.examples) < 2:
            errors.append("Need >= 2 examples")

        # 4. Examples must have highlights
        for i, ex in enumerate(item.examples):
            highlights = getattr(ex, "highlights", None)
            if not highlights:
                errors.append(f"Example {i} missing highlights")

        # 5. Pitfalls must explain WHY in Bengali
        for i, pit in enumerate(item.pitfalls):
            why = getattr(pit, "why_bengali", None)
            if not why or len(why) < 10:
                errors.append(f"Pitfall {i} missing Bengali explanation")

        # 6. Prerequisite chain must not self-reference
        if item.id in item.prerequisite_ids:
            errors.append("Self-referencing prerequisite")

        return len(errors) == 0, errors

    def validate_batch(self, items: List[GrammarPoint]) -> Tuple[List[GrammarPoint], Dict[str, List[str]]]:
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
