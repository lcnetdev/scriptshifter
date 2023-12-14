from os import environ

from requests import post

from scriptshifter.exceptions import BREAK, UpstreamError
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
            json={
                "data": ctx.src,
                "genre": ctx.options.get("genre", DEFAULT_GENRE)
            })
    try:
        rsp.raise_for_status()
    except Exception:
        raise UpstreamError("Error received from Dicta service.")

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
