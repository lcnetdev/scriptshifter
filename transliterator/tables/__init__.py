from functools import cache
from glob import glob
from os import path, access, R_OK

from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


__doc__ = """
Transliteration tables.

These tables contain all transliteration information, grouped by script and
language (or language and script? TBD)
"""


TABLE_DIR = path.join(path.dirname(path.realpath(__file__)), "data")


@cache
def load_table(tname):
    """
    Load one transliteration table.

    The table file is parsed into an in-memory configuration that contains
    the language & script metadata and parsing rules.
    """

    fname = path.join(TABLE_DIR, tname + ".yml")
    if not access(fname, R_OK):
        raise ValueError(f"No transliteration table for {tname}!")

    with open(fname) as fh:
        tdata = load(fh, Loader=Loader)

    # TODO Rearrange parsing tokens alphabetically, but so that the longest
    # ones come first. E.g.
    # - ABCD
    # - AB
    # - A
    # - BCDE
    # - BCD
    # - BEFGH
    # - B

    return tdata
