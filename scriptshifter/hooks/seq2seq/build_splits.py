#!/usr/bin/env python
"""Build train/dev/test splits from data/raw/extracted-<lang>-agg.csv.

Raw rows are (src, rom, count). Pipeline:
  1. Normalize whitespace/punctuation on src and rom (no case folding).
  2. Aggregate exact (src, rom) duplicates by summing counts.
  3. Strict majority-wins on ambiguity: for each src with >1 distinct rom,
     keep the rom with the strictly highest count; drop the src if the top
     count is tied. (Diacritics preserved — "Tihrān" beats "Tihran" because
     it has the higher count, not because we case/fold-normalized.)
  4. Shuffle deterministically and write train/dev/test CSVs to
     data/source/<lang>/.

Run: python build_splits.py            # all langs found in data/raw/
     python build_splits.py per ara    # specific langs
"""

import csv
import random
import re
import sys
from collections import defaultdict
from glob import glob
from os import makedirs, path
from string import punctuation, whitespace

from s2s import CP_RANGE


RAW_DIR = "data/raw"
OUT_DIR = "data/source"
RAW_PATTERN = "extracted-{lang}-agg.csv"

# Split ratios (must sum to 1.0). Matches the existing ~95/2.5/2.5 layout.
TRAIN_FRAC = 0.95
DEV_FRAC = 0.025
TEST_FRAC = 0.025

SEED = 42

# Whitespace runs (incl. tabs, NBSP, etc.) that should collapse to one space.
_WS_RE = re.compile(r"\s+")
# Whitespace adjacent to ASCII punctuation — strip it so " :" and ":" align.
_WS_PUNCT_RE = re.compile(r"\s+([,.;:!?\)\]\}])")
_PUNCT_WS_RE = re.compile(r"([\(\[\{])\s+")


def _foreign_seq(src, lang):
    """
    Return numeric positions of foreign character sequences.

    Foreign sequences are characters not in the CP_RANGE for the given
    language.
    """
    cp_range = CP_RANGE.get(lang, CP_RANGE["latin"])

    ranges = []
    eos = len(src) - 1  # Last character index.
    s, e = None, None  # Start and end markers for foreign sequences.
    for i, ch in enumerate(src):
        # Ignore whitespace and punctuation.
        if ch in punctuation or ch in whitespace:
            if i == eos and s is not None:
                # At the end of a foreign sequence.
                e = i + 1
                # print(f"Setting e to {e}")
                if s is not None:
                    # Add range and reset markers.
                    ranges.append((s, e))
                    s, e = None, None
                else:
                    raise ValueError(
                            "Error computing sequence: missing start marker.")
            continue

        in_range = False
        for min_cp, max_cp in cp_range:
            if ch >= min_cp and ch <= max_cp:
                in_range = True
                break

        if in_range:
            # Character is in range.
            if s is not None:
                # We passed the end of a foreign sequence. Mark it.
                e = i
                # print(f"Setting e to {e}")
            # Else: Continuation of a native sequence.
        else:
            # Character is not in range.
            # print(f"{ch} at #{i} is not in range.")
            if s is None:
                # Stepping into a foreign sequence. Mark the start.
                s = i
                # print(f"Setting s to {s}")
            if i == eos:
                # At the end of a foreign sequence.
                e = i + 1
                # print(f"Setting e to {e}")
            # Else: continuation of a foreign sequence.

        if e is not None:
            if s is not None:
                # Add range and reset markers.
                ranges.append((s, e))
                s, e = None, None
            else:
                raise ValueError(
                        "Error computing sequence: missing start marker.")

    # Verify that either both s and e are None, or both are set.
    if (s is None) ^ (e is None):
        raise ValueError("Error computing sequence: start and end don't match.")

    return ranges


def strip_foreign_seq(pair, lang):
    """
    Strip foreign sequences from pairs.
    """
    ranges = _foreign_seq(pair[0], lang)

    for s, e in ranges:
        if pair[0].find(pair[0][s:e]) >= 0 and pair[0].find(pair[0][s:e]) >= 0:
            pair[0] = pair[0].replace(pair[0][s:e], "")
            pair[1] = pair[1].replace(pair[1][s:e], "")

    return pair


def normalize_text(s):
    """Light normalization: strip, collapse whitespace, tighten punct spacing.

    Deliberately does NOT casefold or alter diacritics — diacritics are part
    of the romanization signal we want to preserve.
    """
    s = s.strip()
    s = _WS_RE.sub(" ", s)
    s = _WS_PUNCT_RE.sub(r"\1", s)
    s = _PUNCT_WS_RE.sub(r"\1", s)
    return s


def discover_langs():
    """Return language codes for every extracted-*-agg.csv in RAW_DIR."""
    langs = []
    for fpath in sorted(glob(path.join(RAW_DIR, "extracted-*-agg.csv"))):
        base = path.basename(fpath)
        lang = base[len("extracted-"):-len("-agg.csv")]
        langs.append(lang)
    return langs


def load_raw(lang):
    """Read raw rows, normalize, and aggregate duplicates by summed count."""
    fpath = path.join(RAW_DIR, RAW_PATTERN.format(lang=lang))
    counts = defaultdict(int)
    total = 0
    with open(fpath, newline="") as fh:
        reader = csv.reader(fh)
        for row in reader:
            if len(row) < 2:
                continue
            row = strip_foreign_seq(row, lang)
            src = normalize_text(row[0])
            rom = normalize_text(row[1])
            if not src or not rom:
                continue
            try:
                c = int(row[2]) if len(row) >= 3 and row[2] else 1
            except ValueError:
                c = 1
            counts[(src, rom)] += c
            total += 1
    print(f"[{lang}] raw rows: {total}, unique (src,rom) post-normalize: {len(counts)}")
    return counts


def resolve_majority(counts):
    """Strict majority-wins disambiguation.

    For each src with multiple rom variants, keep the rom with the strictly
    highest count. Tie at the top → drop the src entirely.
    """
    by_src = defaultdict(dict)  # src -> {rom: count}
    for (src, rom), c in counts.items():
        by_src[src][rom] = c

    kept = []
    unambiguous = 0
    resolved = 0
    tied_drops = 0
    for src, rom_counts in by_src.items():
        if len(rom_counts) == 1:
            rom = next(iter(rom_counts))
            kept.append((src, rom))
            unambiguous += 1
            continue
        # Sort roms by descending count.
        ranked = sorted(rom_counts.items(), key=lambda kv: kv[1], reverse=True)
        top_rom, top_c = ranked[0]
        runner_c = ranked[1][1]
        if top_c > runner_c:
            kept.append((src, top_rom))
            resolved += 1
        else:
            tied_drops += 1

    print(
        f"  unambiguous srcs: {unambiguous}; "
        f"majority-resolved: {resolved}; "
        f"tied-and-dropped: {tied_drops}; "
        f"kept pairs: {len(kept)}"
    )
    return kept


def split(pairs):
    rng = random.Random(SEED)
    pairs = list(pairs)
    rng.shuffle(pairs)
    n = len(pairs)
    n_test = int(round(n * TEST_FRAC))
    n_dev = int(round(n * DEV_FRAC))
    n_train = n - n_dev - n_test
    return {
        "train": pairs[:n_train],
        "dev": pairs[n_train:n_train + n_dev],
        "test": pairs[n_train + n_dev:],
    }


def write_split(lang, name, rows):
    out_path = path.join(OUT_DIR, lang, f"{name}.csv")
    makedirs(path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerows(rows)
    print(f"  wrote {len(rows):>7} rows -> {out_path}")


def build(lang):
    print(f"=== {lang} ===")
    counts = load_raw(lang)
    pairs = resolve_majority(counts)
    splits = split(pairs)
    for name, rows in splits.items():
        write_split(lang, name, rows)


def main(argv):
    assert abs((TRAIN_FRAC + DEV_FRAC + TEST_FRAC) - 1.0) < 1e-9, \
        "split fractions must sum to 1.0"
    langs = argv[1:] if len(argv) > 1 else discover_langs()
    if not langs:
        print(f"No raw files found in {RAW_DIR}.", file=sys.stderr)
        sys.exit(1)
    for lang in langs:
        build(lang)


if __name__ == "__main__":
    main(sys.argv)
