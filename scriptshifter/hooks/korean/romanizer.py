# @package ext.korean
#

__doc__ = """
Korean transcription functions.

Ported from K-Romanizer: https://library.princeton.edu/eastasian/k-romanizer

Only script-to-Roman is possible for Korean.

Note that Korean Romanization must be done separately for strings containing
only personal names and strings that do not contain personal names, due to
ambiguities in the language. A non-deterministic approach using machine
learning that separates words depending on context is being attempted by other
parties, and it may be possible to eventually integrate such services here in
the future, technology and licensing permitting. At the moment there are no
such plans.

Many thanks to Hyoungbae Lee for kindly providing the original K-Romanizer
program and assistance in porting it to Python.
"""

from os import path

from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader

from scriptshifter.exceptions import BREAK
from scriptshifter.hooks.korean import KROM_HOOK_BASEDIR


DATA_FP = path.join(KROM_HOOK_BASEDIR, "data.yml")


def s2r_nonames_post_config(ctx):
    """ Romanize a regular string NOT containing personal names. """
    ctx.dest = _romanize_nonames(ctx)

    return BREAK


def s2r_names_post_config(ctx):
    """
    Romanize a string containing ONLY Korean personal names.

    One or more names can be transcribed. A comma or middle dot (U+00B7) is
    to be used as separator for multiple names.
    """
    ctx.dest = _romanize_names(ctx)

    return BREAK


def _romanize_nonames(ctx):
    return "Nothing here yet."


def _romanize_names(ctx):
    return "Nothing Here Yet."
