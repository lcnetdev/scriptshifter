__doc__ = """
General-purpose hooks.
"""

from logging import getLogger
from re import compile, search

from scriptshifter.tables import get_lang_dcap


# Match multiple spaces.
MULTI_WS_RE = compile(r"(\s){2,}")

# Punctuation and brackets.
# TODO add angled brackets, opening and closing quotes, etc.
NORM1_RE = compile(r"\s([.,;:\)\]}])")
NORM2_RE = compile(r"([,;\)\]}])(\S)")
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

    NOTE: this function capitalizes every token. This is not what is wanted
    most of the time. The capitalize_post_assembly function, instead, separates
    words by spaces before applying capitalization.
    """
    _capitalize_ls(ctx)


def capitalize_post_assembly(ctx, **kwargs):
    """
    Capitalize an already assembled result string according to user options.
    """
    scope = ctx.options.get("capitalize")
    if scope == "first":
        double_caps = get_lang_dcap(ctx.conn, ctx.lang_id)
        ctx.dest = _capitalize_token(ctx.dest, double_caps)
    elif scope == "all":
        ctx.dest_ls = ctx.dest.split(" ")  # Re-tokenize list after assembly.

        _capitalize_ls(ctx)
        ctx.dest = " ".join(ctx.dest_ls)


def normalize_spacing_post_assembly(ctx):
    """
    Remove duplicate and unwanted whitespace around punctuation.

    NOTE: This is called by default by transliterate() immediately after the
    `post_assembly` hook.
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

    ctx.dest = norm


def _capitalize_ls(ctx):
    """
    capitalize first word only or all words.

    NOTE: this function is only used for capitalizing hook-generated
    transliterations, which are not normally processed. Double cap rules are
    not applicable here.
    """
    double_caps = get_lang_dcap(ctx.conn, ctx.lang_id)
    scope = ctx.options.get("capitalize")
    cap = ctx.dest_ls

    if scope == "first":
        ctx.dest_ls[0] = _capitalize_token(ctx.dest_ls[0], double_caps)

    if scope == "all":
        logger.debug(f"Tokens for capitalization: {cap}")
        ctx.dest_ls = [
                _capitalize_token(tk, double_caps=double_caps)
                for tk in cap]


def _capitalize_token(tk, double_caps=[]):
    first_letter_match = search(r'\w',  tk, 1)
    first_letter_pos = first_letter_match.start() if first_letter_match else 0

    # TODO
    for dcap_rule in (double_caps or []):
        pass

    if first_letter_pos == 0:
        cap = tk[0].upper() + tk[1:]
    else:
        cap = (
                tk[:first_letter_pos] +
                tk[first_letter_pos].upper() +
                tk[(first_letter_pos + 1):])

    return cap
