# @package ext

__doc__ = """
Yiddish transliteration module.

Courtesy of Isaac Bleaman and Asher Lewis.

https://github.com/ibleaman/yiddish.git

Note the underscore in the module name to disambiguate with the `yiddish`
external package name.
"""


from yiddish import detransliterate, transliterate

from scriptshifter.exceptions import BREAK
from scriptshifter.tools import capitalize


def s2r_post_config(ctx):
    """
    Script to Roman.
    """

    rom = transliterate(
            ctx.src, loc=True,
            loshn_koydesh=ctx.options.get("loshn_koydesh"))

    if ctx.options["capitalize"] == "all":
        rom = capitalize(rom)
    elif ctx.options["capitalize"] == "first":
        rom = rom[0].upper() + rom[1:]

    ctx.dest = rom

    return BREAK


def r2s_post_config(ctx):
    """
    Roman to script.

    NOTE: This doesn't support the `loc` option.
    """

    ctx.dest = detransliterate(
            ctx.src,
            loshn_koydesh=ctx.options.get("loshn_koydesh"))

    return BREAK
