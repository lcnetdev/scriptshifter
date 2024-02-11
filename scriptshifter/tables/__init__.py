import logging
import re

from functools import cache
from importlib import import_module
from os import environ, path, access, R_OK

from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader

from scriptshifter.exceptions import ConfigError


__doc__ = """
Transliteration tables.

These tables contain all transliteration information, grouped by script and
language (or language and script? TBD)
"""


DEFAULT_TABLE_DIR = path.join(path.dirname(path.realpath(__file__)), "data")
# Can be overridden for tests.
TABLE_DIR = environ.get("TXL_CONFIG_TABLE_DIR", DEFAULT_TABLE_DIR)

# Available hook names.
HOOKS = (
    "post_config",
    "post_normalize",
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
HOOK_PKG_PATH = "scriptshifter.hooks"
# Default characters defining a word boundary. This is configurable per-table.
WORD_BOUNDARY = " \n\t:;.,\"'-()[]{}"

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
        # logger.debug(f"a: {self.content}, b: {other.content}")
        self_len = len(self.content)
        other_len = len(other.content)
        min_len = min(self_len, other_len)

        # If one of the strings is entirely contained in the other string...
        if self.content[:min_len] == other.content[:min_len]:
            # logger.debug("Roots match.")
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
    Load one transliteration table and possible parents.

    The table file is parsed into an in-memory configuration that contains
    the language & script metadata and parsing rules.
    """

    fname = path.join(TABLE_DIR, tname + ".yml")
    if not access(fname, R_OK):
        raise ValueError(f"No transliteration table for {tname}!")

    with open(fname) as fh:
        tdata = load(fh, Loader=Loader)

    # NOTE Only one level of inheritance. No need for recursion for now.
    parents = tdata.get("general", {}).get("parents", [])

    if "script_to_roman" in tdata:
        if "double_cap" in tdata["script_to_roman"]:
            tdata["script_to_roman"]["double_cap"] = tuple(
                    tdata["script_to_roman"]["double_cap"])

        tokens = {}
        for parent in parents:
            parent_tdata = load_table(parent)
            # Merge parent tokens. Child overrides parents, and a parent listed
            # later override ones listed earlier.
            tokens |= {
                Token(k): v for k, v in parent_tdata.get(
                        "script_to_roman", {}).get("map", {})
            }
            # Merge and/or remove double cap rules.
            tdata["script_to_roman"]["double_cap"] = tuple((
                set(parent_tdata.get(
                    "script_to_roman", {}
                ).get("double_cap", set())) |
                set(tdata["script_to_roman"].get("double_cap", set()))
            ) - set(tdata["script_to_roman"].get("no_double_cap", set())))
        if "no_double_cap" in tdata["script_to_roman"]:
            del tdata["script_to_roman"]["no_double_cap"]

        tokens |= {
                Token(k): v
                for k, v in tdata["script_to_roman"].get("map", {}).items()}
        tdata["script_to_roman"]["map"] = tuple(
                (k.content, tokens[k]) for k in sorted(tokens))

        # Normalization.
        normalize = {}

        # Inherit normalization rules.
        for parent in parents:
            parent_langsec = load_table(parent)["script_to_roman"]
            normalize |= parent_langsec.get("normalize", {})

        for k, v in tdata["script_to_roman"].get("normalize", {}).items():
            for vv in v:
                normalize[Token(vv)] = k

        tdata["script_to_roman"]["normalize"] = dict(sorted(normalize.items()))

        # Hook function.
        if "hooks" in tdata["script_to_roman"]:
            tdata["script_to_roman"]["hooks"] = load_hook_fn(
                    tname, tdata["script_to_roman"])

    if "roman_to_script" in tdata:
        tokens = {}
        for parent in parents:
            parent_tdata = load_table(parent)
            # Merge parent tokens. Child overrides parents, and a parent listed
            # later override ones listed earlier.
            tokens |= {
                Token(k): v for k, v in parent_tdata.get(
                        "roman_to_script", {}).get("map", {})
            }
        tokens |= {
            Token(k): v
            for k, v in tdata["roman_to_script"].get("map", {}).items()
        }
        tdata["roman_to_script"]["map"] = tuple(
                (k.content, tokens[k]) for k in sorted(tokens))

        # Ignore regular expression patterns.
        # Patterns are evaluated in the order they are listed in the config.
        ignore_ptn = [
                re.compile(ptn)
                for ptn in tdata["roman_to_script"].get("ignore_ptn", [])]
        for parent in parents:
            parent_tdata = load_table(parent)
            # NOTE: duplicates are not removed.
            ignore_ptn = [
                re.compile(ptn)
                for ptn in parent_tdata.get(
                        "roman_to_script", {}).get("ignore_ptn", [])
            ] + ignore_ptn
        tdata["roman_to_script"]["ignore_ptn"] = ignore_ptn

        # Ignore plain strings.
        ignore = {
            Token(t)
            for t in tdata["roman_to_script"].get("ignore", [])
        }
        for parent in parents:
            parent_tdata = load_table(parent)
            # No overriding occurs with the ignore list, only de-duplication.
            ignore |= {
                Token(t) for t in parent_tdata.get(
                        "roman_to_script", {}).get("ignore", [])
            }
        tdata["roman_to_script"]["ignore"] = [
                t.content for t in sorted(ignore)]

        # Hooks.
        if "hooks" in tdata["roman_to_script"]:
            tdata["roman_to_script"]["hooks"] = load_hook_fn(
                    tname, tdata["roman_to_script"])

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
            fn_kwargs = cfg_hook_fn[1] if len(cfg_hook_fn) > 1 else {}
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
