import logging

from functools import cache
# from glob import glob
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


logger = logging.getLogger(__name__)


class Token:
    """
    Token class: minimal unit of text parsing.

    This class overrides the `<` operator for strings, so that sorting is done
    in a way that prioritizes a longer string over a shorter one with identical
    root.
    """
    def __init__(self, content):
        self.content = content

    def __lt__(self, other):
        """
        Operator to sort tokens.

        E.g:

        - ABCD
        - AB
        - A
        - BCDE
        - BCD
        - BEFGH
        - B
        """
        logger.debug(f"a: {self.content}, b: {other.content}")
        self_len = len(self.content)
        other_len = len(other.content)
        min_len = min(self_len, other_len)

        # If one of the strings is entirely contained in the other string...
        if self.content[:min_len] == other.content[:min_len]:
            logger.debug("Roots match.")
            # ...then the longer one takes precedence (is "less")
            return self_len > other_len

        # If the root strings are different, perform a normal comparison.
        return self.content < other.content


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

    if "script_to_roman" in tdata:
        tokens = {
                Token(k): v
                for k, v in tdata["script_to_roman"].get("map", {}).items()}
        tdata["script_to_roman"]["map"] = tuple(
                (k.content, tokens[k]) for k in sorted(tokens))

    if "roman_to_script" in tdata:
        tokens = {
                Token(k): v
                for k, v in tdata["roman_to_script"].get("map", {}).items()}
        tdata["roman_to_script"]["map"] = tuple(
                (k.content, tokens[k]) for k in sorted(tokens))

    return tdata
