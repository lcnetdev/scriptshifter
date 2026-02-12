# @package ext

__doc__ = """
Transliterate Kanji, Katakana, and Hiragana into Romaji. """


from logging import getLogger

from pykakasi import kakasi

from scriptshifter.exceptions import BREAK


logger = getLogger(__name__)
trans = kakasi()


def s2r_post_config(ctx, src_code):
    if src_code not in "HKJ":
        raise ValueError(f"Source script code {src_code} not supported.")
    trans.setMode(src_code, "a")
    # TODO Use option switch: “Hepburn” , “Kunrei” or “Passport”
    trans.setMode("r", "Hepburn")
    trans.setMode("C", ctx.options["capitalize"] is not False)

    ctx.dest = trans.getConverter().do(ctx.src)

    return BREAK
