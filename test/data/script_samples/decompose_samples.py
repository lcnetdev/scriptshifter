#!/usr/bin/env python

__doc__ = """
Usage: decompose_samples.py

Use this script to normalize Roman map keys to use combining characters
(decomposed glyphs) vs. pre-composed glyphs.

The script will create a new CSV file named according to the source.
E.g. `myscript.csv` → `myscript_norm.csv`.

NOTE: the script does not parse the CSV, it scans it as a plain text file. It
is unlikely but possible that some normalization may lead to an invalid CSV.
"""

from os import path
from unicodedata import normalize
from glob import glob

for fname in glob("*.csv"):
    dest_fname = path.splitext(fname)[0] + "_norm.csv"
    with open(fname) as fh:
        data = fh.read()

    norm_data = normalize("NFD", data)

    with open(dest_fname, "w") as fh:
        fh.write(norm_data)
    print(f"Normalized {fname} to {dest_fname}.")

print("Done.")
