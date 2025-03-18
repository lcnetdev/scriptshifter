# @package ext

__doc__ = """
Yiddish transliteration module.

Courtesy of Isaac Bleaman for the module and Asher Lewis for the LC overrides
of loshn koydesh rules.

https://github.com/ibleaman/yiddish.git

Note the underscore in the module name to disambiguate with the `yiddish`
external package name.
"""


from yiddish import detransliterate, transliterate

from scriptshifter.exceptions import BREAK


def s2r_post_config(ctx):
    """
    Script to Roman.
    """
    ctx.dest = transliterate(
            ctx.src, loc=True,
            loshn_koydesh=ctx.options.get("loshn_koydesh"))

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
