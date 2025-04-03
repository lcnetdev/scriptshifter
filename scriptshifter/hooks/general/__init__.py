__doc__ = """
General-purpose hooks.
"""

from logging import getLogger
from re import compile

from scriptshifter.trans import MULTI_WS_RE


# Punctuation and brackets.
# TODO add angled brackets, opening and closing quotes, etc.
NORM1_RE = compile(r"\s([.,;:\)\]}])")
NORM2_RE = compile(r"([.,;:\)\]}])(\S)")
NORM3_RE = compile(r"([\(\[\{])\s")
NORM4_RE = compile(r"(\S)([\(\[\{])")

# "Straight" quotes.
# TODO Add single quotes.
NORM5_RE = compile(r"\"\s*([^\"]?)\s*\"")
NORM6_RE = compile(r"(\S)(\"[^\"]?\")")
NORM7_RE = compile(r"(\"[^\"]?\")(\S)")

# Space between symbols.
NORM8_RE = compile(r"([.,;:\(\[\{\)\]}])\s+([.,;:\(\[\{\)\]}])")

logger = getLogger(__name__)


def capitalize_pre_assembly(ctx):
    """
    Capitalize a not-yet-assembled result list according to user options.
    """
    ctx.dest_ls = _capitalize(ctx.dest_ls, ctx.options.get("capitalize"))


def capitalize_post_assembly(ctx):
    """
    Capitalize an already assembled result string according to user options.
    """
    dest_ls = ctx.dest.split(" ")

    dest_ls = _capitalize(dest_ls, ctx.options.get("capitalize"))

    return " ".join(dest_ls)


def normalize_spacing_post_assembly(ctx):
    """
    Remove duplicate and unwanted whitespace around punctuation.
    """
    # De-duplicate whitespace.
    logger.debug(f"Dest pre manipulation: {ctx.dest}")
    # Remove white space between punctuation signs.
    norm = MULTI_WS_RE.sub(r"\1", ctx.dest.strip())
    # Remove space before punctuation and closing brackets.
    norm = NORM1_RE.sub(r"\1", norm)
    # Ensure space after punctuation and closing brackets.
    norm = NORM2_RE.sub(r"\1 \2", norm)
    # Remove space after opening brackets.
    norm = NORM3_RE.sub(r"\1", norm)
    # Ensure space before opening brackets.
    norm = NORM4_RE.sub(r"\1 \2", norm)
    # Remove space inside matched quotes.
    norm = NORM5_RE.sub(r"\"\1\"", norm)
    # Add space before opening double quote.
    norm = NORM6_RE.sub(r"\1 \2", norm)
    # Add space after closing double quote.
    norm = NORM7_RE.sub(r"\1 \2", norm)
    # Remove multiple white space characters.
    # norm = NORM8_RE.sub(r"\1\2", norm)

    return norm


def _capitalize(src, which):
    """
    capitalize first word only or all words.

    NOTE: this function is only used for capitalizing hook-generated
    transliterations, which are not normally processed. Double cap rules are
    not applicable here.
    """
    if which == "first":
        src[0] = src[0].capitalize()
        return src

    if which == "all":
        return [tk[0].upper() + tk[1:] for tk in src]

    return src
