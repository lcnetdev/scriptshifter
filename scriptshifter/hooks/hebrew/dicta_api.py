from os import environ

from requests import post

from scriptshifter.exceptions import BREAK
from scriptshifter.tools import capitalize

EP = environ.get("TXL_DICTA_EP")
DEFAULT_GENRE = "rabbinic"


def s2r_post_config(ctx):
    """
    Romanize Hebrew text using the Dicta API service.
    """
    ctx.warnings = []
    rsp = post(
            EP,
            data={
                "data": ctx.src,
                "genre": ctx.options.get("genre", DEFAULT_GENRE)
            })
    rsp.raise_for_status()

    rom = rsp.json().get("transliteration")

    if rom:
        if ctx.options["capitalize"] == "all":
            rom = capitalize(rom)
        elif ctx.options["capitalize"] == "first":
            rom = rom[0].upper() + rom[1:]
    else:
        ctx.warnings.append("Upstream service returned empty result.")

    ctx.dest = rom

    return BREAK
