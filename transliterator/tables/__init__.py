import logging

from functools import cache
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


class Token(str):
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

    def __hash__(self):
        return hash(self.content)


@cache
def list_tables():
    """
    List all the available tables.
    """
    with open(path.join(TABLE_DIR, "index.yml")) as fh:
        tdata = load(fh, Loader=Loader)

    return tdata


@cache
def load_table(tname):
    """
    Load one transliteration table and possible parent.

    The table file is parsed into an in-memory configuration that contains
    the language & script metadata and parsing rules.
    """

    fname = path.join(TABLE_DIR, tname + ".yml")
    if not access(fname, R_OK):
        raise ValueError(f"No transliteration table for {tname}!")

    with open(fname) as fh:
        tdata = load(fh, Loader=Loader)

    # NOTE Only one level of inheritance. No need for recursion for now.
    parent = tdata.get("general", {}).get("inherits", None)
    if parent:
        parent_tdata = load_table(parent)

    if "script_to_roman" in tdata:
        tokens = {
                Token(k): v
                for k, v in tdata["script_to_roman"].get("map", {}).items()}
        if parent:
            # Merge (and override) parent values.
            tokens = {
                Token(k): v for k, v in parent_tdata.get(
                        "script_to_roman", {}).get("map", {})
            } | tokens
        tdata["script_to_roman"]["map"] = tuple(
                (k.content, tokens[k]) for k in sorted(tokens))

    if "roman_to_script" in tdata:
        tokens = {
                Token(k): v
                for k, v in tdata["roman_to_script"].get("map", {}).items()}
        if parent:
            # Merge (and override) parent values.
            tokens = {
                Token(k): v for k, v in parent_tdata.get(
                        "roman_to_script", {}).get("map", {})
            } | tokens
        tdata["roman_to_script"]["map"] = tuple(
                (k.content, tokens[k]) for k in sorted(tokens))

        if parent:
            p_ignore = {
                    Token(t) for t in parent_tdata.get(
                            "roman_to_script", {}).get("ignore", [])}
        else:
            p_ignore = set()

        ignore = {
            Token(t)
            for t in tdata["roman_to_script"].get("ignore", [])
        } | p_ignore

        tdata["roman_to_script"]["ignore"] = [
                t.content for t in sorted(ignore)]

    return tdata
