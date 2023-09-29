from json import dumps
from os import environ

from requests import post

from scriptshifter.exceptions import BREAK

EP = environ.get("TXL_DICTA_EP")
DEFAULT_GENRE = "rabbinic"


def s2r_post_config(ctx):
    """
    Romanize Hebrew text using the Dicta API service.
    """
    ctx.warnings = []
    rsp = post(
            EP,
            data=dumps({
                "data": ctx.src,
                "genre": ctx.options.get("genre", DEFAULT_GENRE)
            }))
    rsp.raise_for_status()

    rom = rsp.json().get("transliteration")
    ctx.dest = rom

    if not rom:
        ctx.warnings.append("Upstream service returned empty result.")

    return BREAK
