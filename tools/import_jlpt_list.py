#!/usr/bin/env python3
# JLPT whitelist importer (D-037; executes the D-028 hybrid-pipeline step 1:
# "backbone from open datasets — no invented Japanese").
#
# Downloads the open JLPT vocab deck (jamsinclair/open-anki-jlpt-decks, which
# derives from Jonathan Waller's CC-BY JLPT lists) and emits a level whitelist
# for the content validator: one surface form per line, BOTH the expression
# (kanji form) and the reading (kana form), since lessons use kana surfaces.
#
#   python3 tools/import_jlpt_list.py n3     # → content_factory/n3_whitelist.txt
#   python3 tools/import_jlpt_list.py n2 n1  # multiple levels at once
#
# The whitelist BOUNDS what lessons at that level may teach (D-011). It is not
# itself teaching content — actual N3+ lessons still require authoring + native
# review before verified:true (D-028).
import csv
import io
import sys
import urllib.request

BASE = "https://raw.githubusercontent.com/jamsinclair/open-anki-jlpt-decks/main/src/{lvl}.csv"
OUT = "content_factory/{lvl}_whitelist.txt"

def import_level(lvl: str) -> None:
    url = BASE.format(lvl=lvl)
    print(f"fetching {url} …")
    raw = urllib.request.urlopen(url, timeout=30).read().decode("utf-8")
    rows = list(csv.DictReader(io.StringIO(raw)))
    words: list[str] = []
    seen = set()
    for r in rows:
        for form in (r.get("expression", "").strip(), r.get("reading", "").strip()):
            if form and form not in seen:
                seen.add(form)
                words.append(form)
    path = OUT.format(lvl=lvl)
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"# JLPT {lvl.upper()} whitelist — imported {len(rows)} entries "
                f"({len(words)} surface forms incl. readings)\n")
        f.write("# source: jamsinclair/open-anki-jlpt-decks (from Jonathan "
                "Waller's CC-BY JLPT lists) — dataset-backed, not invented\n")
        f.write("# bounds N-level lesson srs_words (tools/validate_content.mjs);"
                " native review still gates verified:true (D-028)\n")
        f.write("\n".join(words) + "\n")
    print(f"  → {path}: {len(words)} forms from {len(rows)} entries")

if __name__ == "__main__":
    levels = [a.lower() for a in sys.argv[1:]] or ["n3"]
    for lvl in levels:
        import_level(lvl)
