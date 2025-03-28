from os import environ

from requests import post

from scriptshifter.exceptions import BREAK, UpstreamError
from scriptshifter.hooks.general import capitalize_post_assembly

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

    ctx.dest = rsp.json().get("transliteration")
    if ctx.dest:
        ctx.dest = capitalize_post_assembly(ctx)

    return BREAK
