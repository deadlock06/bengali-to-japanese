#!/usr/bin/env python3
# Generates bundled Japanese audio for every lesson word + kana using edge-tts
# (free Microsoft neural voice, no API key). Runs at BUILD time; the .mp3 files
# are bundled so the app plays them fully OFFLINE (spec Tier-0 "pre-bundled
# audio"). Re-run after adding content; existing files are skipped.
#   ./.venv-tts/bin/python tools/generate_audio.py
import asyncio, json, os, glob, sys
import edge_tts

VOICE = "ja-JP-NanamiNeural"   # natural female JP voice
OUT_DIR = "assets/audio"
CONTENT = "assets/content"

def collect():
    """→ list of (key, japanese_text). key = stable filename stem."""
    items = {}
    # kana: one clip per character, keyed by romaji (kana_a, kana_ka, …)
    for f in ("hiragana.json", "katakana.json"):
        p = os.path.join(CONTENT, f)
        if not os.path.exists(p): continue
        data = json.load(open(p, encoding="utf-8"))
        script = "hira" if "hira" in f else "kata"
        for k in data.get("items", []):
            items[f"kana_{script}_{k['romaji']}"] = k["char"]
    # Voiced (dakuten) + semi-voiced (handakuten) — the "+25" set the L0.1
    # assessment expects (46 base + 25 voiced/combo, classroom/CURRICULUM.md §6).
    # ぢ/づ reuse じ/ず (じ=ji, ず=zu) — phonetically identical.
    VOICED = {  # romaji key -> (hiragana, katakana)
        "ga": ("が", "ガ"), "gi": ("ぎ", "ギ"), "gu": ("ぐ", "グ"),
        "ge": ("げ", "ゲ"), "go": ("ご", "ゴ"),
        "za": ("ざ", "ザ"), "ji": ("じ", "ジ"), "zu": ("ず", "ズ"),
        "ze": ("ぜ", "ゼ"), "zo": ("ぞ", "ゾ"),
        "da": ("だ", "ダ"), "de": ("で", "デ"), "do": ("ど", "ド"),
        "ba": ("ば", "バ"), "bi": ("び", "ビ"), "bu": ("ぶ", "ブ"),
        "be": ("べ", "ベ"), "bo": ("ぼ", "ボ"),
        "pa": ("ぱ", "パ"), "pi": ("ぴ", "ピ"), "pu": ("ぷ", "プ"),
        "pe": ("ぺ", "ペ"), "po": ("ぽ", "ポ"),
    }
    for r, (hira, kata) in VOICED.items():
        items[f"kana_hira_{r}"] = hira
        items[f"kana_kata_{r}"] = kata
    # B3: yōon combos + sokuon/long-vowel demo units
    YOON = {"kya":("きゃ","キャ"),"kyu":("きゅ","キュ"),"kyo":("きょ","キョ"),
        "sha":("しゃ","シャ"),"shu":("しゅ","シュ"),"sho":("しょ","ショ"),
        "cha":("ちゃ","チャ"),"chu":("ちゅ","チュ"),"cho":("ちょ","チョ"),
        "nya":("にゃ","ニャ"),"nyu":("にゅ","ニュ"),"nyo":("にょ","ニョ"),
        "hya":("ひゃ","ヒャ"),"hyu":("ひゅ","ヒュ"),"hyo":("ひょ","ヒョ"),
        "mya":("みゃ","ミャ"),"myu":("みゅ","ミュ"),"myo":("みょ","ミョ"),
        "rya":("りゃ","リャ"),"ryu":("りゅ","リュ"),"ryo":("りょ","リョ"),
        "gya":("ぎゃ","ギャ"),"gyu":("ぎゅ","ギュ"),"gyo":("ぎょ","ギョ"),
        "ja":("じゃ","ジャ"),"ju":("じゅ","ジュ"),"jo":("じょ","ジョ"),
        "bya":("びゃ","ビャ"),"byu":("びゅ","ビュ"),"byo":("びょ","ビョ"),
        "pya":("ぴゃ","ピャ"),"pyu":("ぴゅ","ピュ"),"pyo":("ぴょ","ピョ")}
    for r, (hira, kata) in YOON.items():
        items[f"kana_hira_{r}"] = hira
        items[f"kana_kata_{r}"] = kata
    items["kana_hira_kitte"] = "きって"; items["kana_hira_okaasan"] = "おかあさん"
    items["kana_kata_kappu"] = "カップ"; items["kana_kata_koohii"] = "コーヒー"

    # scenarios (C2): npc line per node + each choice line
    for pth in glob.glob(os.path.join(CONTENT, "scenario_*.json")):
        d = json.load(open(pth, encoding="utf-8"))
        sid = d["id"]
        for nd in d.get("nodes", []):
            items[f"{sid}_{nd['id']}"] = nd["npc_jp"]
            for k, ch in enumerate(nd.get("choices", [])):
                items[f"{sid}_{nd['id']}_c{k}"] = ch["jp"]

    # pitch minimal-pairs: one clip per item (offline audio for the 🔊 button).
    # NOTE: edge-tts can't reliably render HL vs LH minimal-pair pitch — the
    # clip lets the learner HEAR the word; true contrast needs recorded native
    # audio (post-beta). Still far better than a dead button.
    pp = os.path.join(CONTENT, "pitch_accent.json")
    if os.path.exists(pp):
        for it in json.load(open(pp, encoding="utf-8")).get("items", []):
            items[it["id"]] = it["word"]

    # lesson items: one clip per phrase, keyed by item id
    for p in glob.glob(os.path.join(CONTENT, "lesson_*.json")):
        data = json.load(open(p, encoding="utf-8"))
        for it in data.get("items", []):
            jp = it.get("jp") or it.get("kana")
            if jp:
                items[it["id"]] = jp
    return items

async def synth(key, text):
    out = os.path.join(OUT_DIR, f"{key}.mp3")
    if os.path.exists(out) and os.path.getsize(out) > 0:
        return "skip"
    await edge_tts.Communicate(text, VOICE).save(out)
    return "new"

async def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    items = collect()
    manifest, new, skip = {}, 0, 0
    for key, text in items.items():
        try:
            r = await synth(key, text)
            manifest[key] = f"audio/{key}.mp3"
            new += (r == "new"); skip += (r == "skip")
        except Exception as e:
            print(f"  FAIL {key} ({text}): {e}", file=sys.stderr)
    json.dump(manifest, open(os.path.join(OUT_DIR, "manifest.json"), "w",
              encoding="utf-8"), ensure_ascii=False, indent=0)
    print(f"audio: {len(manifest)} clips ({new} new, {skip} existing) → {OUT_DIR}/")

if __name__ == "__main__":
    asyncio.run(main())
