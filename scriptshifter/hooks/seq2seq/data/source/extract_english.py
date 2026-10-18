#!/usr/bin/env python3
"""Extract lines with unambiguously English words from source CSVs.

For each `data/source/<lang>/<split>.csv`, produce two sibling files:
    <split>_clean.csv         — rows with no English word match
    <split>_english_hits.csv  — rows that matched

The Roman side is normalized to NFC before matching so word boundaries
work correctly in the presence of combining diacritics in the NFD source.
"""
import csv
import json
import re
import sys
import unicodedata
from os import path


# English words that discriminate hits from clean rows. Derived by:
#   1. Finding all words that appear in the previous
#      `normalized/<lang>/train_english_hits.csv` but NOT in the current
#      post-removal `normalized/<lang>/train.csv`.
#   2. Hand-curated additions of clearly-English words seen in misses, with
#      spot-checks against post-removal data to avoid matching legitimate
#      ALA-LC transliterations.
#
# Ambiguous words (also valid ALA-LC tokens) are deliberately omitted:
#   sayyid, duktur, yazd, ahmad, amir, sharif, said, may, caliph, prophet,
#   music, world, press, book, world, prophet, caliph, writer, directed,
#   economic, states, distribution, mahmoud, hussein, hossein,
#   mohammed, assembly, revolution, strategic, president, mohammed, etc.
with open(path.join(path.dirname(__file__), "english_word_list.json")) as _fh:
    WORDS = set(json.load(_fh))

# Compile the alternation pattern. `\b` is Unicode-aware; the Roman side is
# normalized to NFC before matching so composed diacritics (e.g. "ī") are
# single word characters and don't create spurious boundaries inside tokens
# like "iqlīmay".
PATTERN = re.compile(
    r"\b(" + "|".join(re.escape(w) for w in WORDS) + r")\b",
    re.IGNORECASE,
)


def contains_english(roman_text: str) -> bool:
    return bool(PATTERN.search(unicodedata.normalize("NFC", roman_text)))


def process(src_path: str) -> tuple[int, int]:
    base, ext = path.splitext(src_path)
    clean_path = f"{base}_clean{ext}"
    hits_path = f"{base}_english_hits{ext}"

    n_clean = 0
    n_hits = 0
    with (
        open(src_path, newline="") as src_fh,
        open(clean_path, "w", newline="") as clean_fh,
        open(hits_path, "w", newline="") as hits_fh,
    ):
        reader = csv.reader(src_fh)
        clean_w = csv.writer(clean_fh)
        hits_w = csv.writer(hits_fh)
        for row in reader:
            if len(row) < 2:
                clean_w.writerow(row)
                n_clean += 1
                continue
            if contains_english(row[1]):
                hits_w.writerow(row)
                n_hits += 1
            else:
                clean_w.writerow(row)
                n_clean += 1
    return n_clean, n_hits


DATA_ROOT = path.join(
    path.dirname(path.dirname(path.abspath(__file__))),
    "scriptshifter", "hooks", "seq2seq", "data", "source",
)
# Resolve against the project when run from /tmp.
if not path.isdir(DATA_ROOT):
    DATA_ROOT = (
        "/Users/scossu/personal/code/scriptshifter/"
        "scriptshifter/hooks/seq2seq/data/source"
    )


def main():
    print(f"Vocab size: {len(WORDS)} words")
    print(f"Scanning {DATA_ROOT}\n")
    for lang in ("ara", "per"):
        for split in ("train", "dev", "test"):
            src = path.join(DATA_ROOT, lang, f"{split}.csv")
            if not path.exists(src):
                print(f"  skip (missing): {src}")
                continue
            n_clean, n_hits = process(src)
            total = n_clean + n_hits
            pct = (100 * n_hits / total) if total else 0.0
            print(
                f"  {lang}/{split}.csv: {total:>7} rows → "
                f"clean={n_clean:>7}, hits={n_hits:>6} ({pct:4.1f}%)"
            )


if __name__ == "__main__":
    sys.exit(main())
