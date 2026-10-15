#!/usr/bin/env python3
"""Builds assets/bibles/{kjv,web}.json from eBible.org verse-per-line files.

Source: https://ebible.org/Scriptures/eng-kjv_vpl.zip and eng-web_vpl.zip
(both public domain). Usage: tool/build_bibles.py <kjv_vpl.txt> <web_vpl.txt>
Output schema:
 {"id":"kjv","name":"King James Version","license":"Public Domain",
  "books":[{"id":"GEN","name":"Genesis","chapters":[["verse 1 text", ...], ...]}]}
Chapter/verse numbers are implicit (index + 1).
"""
import json, re, sys, os

BOOKS = [("GEN","Genesis"),("EXO","Exodus"),("LEV","Leviticus"),("NUM","Numbers"),("DEU","Deuteronomy"),
("JOS","Joshua"),("JDG","Judges"),("RUT","Ruth"),("1SA","1 Samuel"),("2SA","2 Samuel"),("1KI","1 Kings"),
("2KI","2 Kings"),("1CH","1 Chronicles"),("2CH","2 Chronicles"),("EZR","Ezra"),("NEH","Nehemiah"),
("EST","Esther"),("JOB","Job"),("PSA","Psalms"),("PRO","Proverbs"),("ECC","Ecclesiastes"),
("SOL","Song of Solomon"),("ISA","Isaiah"),("JER","Jeremiah"),("LAM","Lamentations"),("EZE","Ezekiel"),
("DAN","Daniel"),("HOS","Hosea"),("JOE","Joel"),("AMO","Amos"),("OBA","Obadiah"),("JON","Jonah"),
("MIC","Micah"),("NAH","Nahum"),("HAB","Habakkuk"),("ZEP","Zephaniah"),("HAG","Haggai"),
("ZEC","Zechariah"),("MAL","Malachi"),("MAT","Matthew"),("MAR","Mark"),("LUK","Luke"),("JOH","John"),
("ACT","Acts"),("ROM","Romans"),("1CO","1 Corinthians"),("2CO","2 Corinthians"),("GAL","Galatians"),
("EPH","Ephesians"),("PHI","Philippians"),("COL","Colossians"),("1TH","1 Thessalonians"),
("2TH","2 Thessalonians"),("1TI","1 Timothy"),("2TI","2 Timothy"),("TIT","Titus"),("PHM","Philemon"),
("HEB","Hebrews"),("JAM","James"),("1PE","1 Peter"),("2PE","2 Peter"),("1JO","1 John"),("2JO","2 John"),
("3JO","3 John"),("JUD","Jude"),("REV","Revelation")]

def build(path, tid, name):
    names = dict(BOOKS)
    data = {b: {} for b, _ in BOOKS}
    pat = re.compile(r"^(\w{3}) (\d+):(\d+) (.*)$")
    for line in open(path, encoding="utf-8"):
        m = pat.match(line.rstrip("\n"))
        if not m or m.group(1) not in data:
            continue
        b, c, v, t = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
        t = re.sub(r"[\[\]]", "", t)          # KJV supplied-word brackets
        t = t.replace("¶", "")                 # KJV paragraph marks
        t = re.sub(r"\s+", " ", t).strip()
        data[b].setdefault(c, {})[v] = t
    books = []
    for b, n in BOOKS:
        chs = []
        for c in range(1, max(data[b]) + 1):
            vs = data[b].get(c, {})
            chs.append([vs.get(v, "") for v in range(1, (max(vs) if vs else 0) + 1)])
        books.append({"id": b, "name": n, "chapters": chs})
    return {"id": tid, "name": name, "license": "Public Domain", "books": books}

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "bibles")
    for src, tid, nm in [(sys.argv[1], "kjv", "King James Version"), (sys.argv[2], "web", "World English Bible")]:
        d = build(src, tid, nm)
        with open(os.path.join(out, tid + ".json"), "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
        n = sum(len(c) for b in d["books"] for c in b["chapters"])
        print(tid, len(d["books"]), "books", n, "verses")
