__doc__ = """
General-purpose hooks.
"""

from logging import getLogger
from re import compile

from scriptshifter.trans import MULTI_WS_RE


NORM_MAP = (
    (" .", "."),
    (" ;", ";"),
    (" ,", ","),
    ("( ", "("),
    ("[ ", "["),
    ("{ ", "{"),
    (" )", ")"),
    (" ]", "]"),
    (" }", "}"),
    ("- -", "--"),
)

NORM1_RE = compile(r"([.,;:\)\]}])\s")
NORM2_RE = compile(r"(\S)([.,;:\)\]}])")
NORM3_RE = compile(r"\s([\)\]\}])")
NORM4_RE = compile(r"([\)\]\}])(\S)")

logger = getLogger(__name__)


def normalize_spacing_post_assembly(ctx):
    """
    Remove duplicate and unwanted whitespace around punctuation.
    """
    # De-duplicate whitespace.
    logger.debug(f"Dest pre manipulation: {ctx.dest}")
    norm = MULTI_WS_RE.sub(r"\1", ctx.dest.strip())
    norm = NORM1_RE.sub(r"\1", norm)
    norm = NORM2_RE.sub(r"\1 \2", norm)
    norm = NORM3_RE.sub(r"\1", norm)
    norm = NORM4_RE.sub(r"\1 \2", norm)

    # Normalize spacing around punctuation and parentheses.
    for a, b in NORM_MAP:
        norm = norm.replace(a, b)

    return norm
