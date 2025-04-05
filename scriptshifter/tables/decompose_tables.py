#!/usr/bin/env python

__doc__ = """
Usage: decompose_tables.py [CONFIG_FILE_PATH]

Use this script to normalize Roman map keys to use combining characters
(decomposed glyphs) vs. pre-composed glyphs.

The script will create a new YAML file named according to the source.
E.g. `myscript.yml` → `myscript_norm.yml`.

NOTE: Check the YAML syntax as issues with indentation have been detected.
Also, the original key order may be displaced, and whitespace and comments may
disappear.
"""

from argparse import ArgumentParser
from os import path
from unicodedata import normalize
from yaml import load, dump
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


parser = ArgumentParser()
parser.add_argument("src_fname")
args = parser.parse_args()

dest_fname = path.splitext(args.src_fname)[0] + "_norm.yml"
with open(args.src_fname) as fh:
    data = load(fh, Loader=Loader)

data["roman_to_script"]["map"] = {
        normalize("NFD", k): v
        for k, v in data["roman_to_script"]["map"].items()}
data["script_to_roman"]["map"] = {
        k: normalize("NFD", v)
        for k, v in data["script_to_roman"]["map"].items()}

with open(dest_fname, "w") as fh:
    dump(data, fh, indent=2)

print("Done.")
