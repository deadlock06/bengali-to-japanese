#!/usr/bin/env python3
# Book ↔ classroom parity: appends (idempotently) an auto-generated
# "📱 ক্লাসরুম শব্দভাণ্ডার" section to every unit chapter of assets/book/book.json
# containing the unit's COMPLETE current lesson vocabulary (all items of all
# lesson files wired to that unit in curriculum.json). Re-run after ANY content
# change — the marker heading is replaced, authored prose is never touched.
#   python3 tools/sync_book_vocab.py
import json

MARKER = "📱 এই ইউনিটের পুরো ক্লাসরুম শব্দভাণ্ডার (app-synced)"

cur = json.load(open("assets/curriculum/curriculum.json", encoding="utf-8"))
book = json.load(open("assets/book/book.json", encoding="utf-8"))

# lesson id -> items
import glob
lessons = {}
for p in glob.glob("assets/content/lesson_*.json"):
    d = json.load(open(p, encoding="utf-8"))
    lessons[d["id"]] = d["items"]

unit_lessons = {}
for u in cur["units"]:
    lid = u.get("lesson_id") or ""
    ids = [x.strip() for x in lid.split(",") if x.strip() and not x.strip().startswith("kana_")]
    if ids:
        unit_lessons[u["id"]] = ids

synced, total_rows = 0, 0
for ch in book["chapters"]:
    unit = ch.get("unit")
    if unit not in unit_lessons:
        continue
    blocks = ch["blocks"]
    # idempotent: drop a previously generated section (marker → end)
    for i, b in enumerate(blocks):
        if b.get("t") == "h" and b.get("c") == MARKER:
            blocks = blocks[:i]
            break
    rows = [["জাপানি", "Romaji", "বাংলা", "কখন/কেন"]]
    for lid in unit_lessons[unit]:
        for it in lessons.get(lid, []):
            rows.append([it["jp"], it["romaji"], it["meaning"]["bn"], it["note"]["bn"]])
    n = len(rows) - 1
    blocks += [
        {"t": "h", "c": MARKER},
        {"t": "p", "c": f"এই {n}টি শব্দ/বাক্যই AI ক্লাসরুম এই ইউনিটে শেখায় — এখানে পড়ো, ক্লাসরুমে অনুশীলন করো, review deck-এ ধরে রাখো। যেকোনো লাইন select করলে সেনসেই বুঝিয়ে দেবে।"},
        {"t": "table", "rows": rows},
        {"t": "p", "c": "★ এই তালিকা app-এর verified lesson content থেকে স্বয়ংক্রিয়ভাবে মেলানো (tools/sync_book_vocab.py) — বই আর ক্লাসরুম সবসময় এক।"},
    ]
    ch["blocks"] = blocks
    synced += 1
    total_rows += n

json.dump(book, open("assets/book/book.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
print(f"synced {synced} unit chapters, {total_rows} vocab rows")
