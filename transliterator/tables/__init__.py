import logging

from functools import cache
from importlib import import_module
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

# Available hook names.
HOOKS = (
    "post_config",
    "begin_input_token",
    "pre_ignore_token",
    "on_ignore_match",
    "pre_tx_token",
    "on_tx_token_match",
    "on_no_tx_token_match",
    "pre_assembly",
    "post_assembly",
)
# Package path where hook functions are kept.
HOOK_PKG_PATH = "transliterator.hooks"

logger = logging.getLogger(__name__)


class ConfigError(Exception):
    """ Raised when a malformed configuration is detected. """


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

        if "hooks" in tdata["script_to_roman"]:
            tdata["script_to_roman"]["hooks"] = load_hook_fn(
                    tname, tdata["script_to_roman"])

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

        if "hooks" in tdata["roman_to_script"]:
            tdata["roman_to_script"]["hooks"] = load_hook_fn(
                    tname, tdata["script_to_roman"])

    return tdata


def load_hook_fn(cname, sec):
    """
    Load hook functions from configuration file.

    Args:
        lang (str): The language key for the configuration.

        sec (dict): The `script_to_roman` or `roman_to_script` section
        that may contain the `hooks` key to be parsed.

    Return:
        dict: Dictionary of hook name and list of hook functions pairs.
    """
    hook_fn = {}
    for cfg_hook, cfg_hook_fns in sec.get("hooks", {}).items():
        if cfg_hook not in HOOKS:
            raise ConfigError(f"{cfg_hook} is not a valid hook name!")

        hook_fn[cfg_hook] = []
        # There may be more than one function in each hook. They are
        # executed in the order they are found.
        for cfg_hook_fn in cfg_hook_fns:
            modname, fnname = path.splitext(cfg_hook_fn[0])
            fnname = fnname.lstrip(".")
            fn_kwargs = cfg_hook_fn[1]
            try:
                fn = getattr(import_module(
                        "." + modname, HOOK_PKG_PATH), fnname)
            except NameError:
                raise ConfigError(
                    f"Hook function {fnname} defined in {cname} configuration "
                    f"not found in module {HOOK_PKG_PATH}.{modname}!"
                )
            hook_fn[cfg_hook].append((fn, fn_kwargs))

    return hook_fn
