import logging

# This requires ArabicTransliterator to be installed as a package.
from arabic.ArabicTransliterator import ALA_LC_Transliterator as Trans
from mishkal.tashkeel.tashkeel import TashkeelClass

from scriptshifter.exceptions import BREAK


__doc__ = """ Integrate external ArabicTransliterator library. """


logger = logging.getLogger(__name__)


def s2r_post_config(ctx):
    trans = Trans()
    vocalizer = TashkeelClass()
    voc = vocalizer.tashkeel(ctx.src)
    ctx.dest = trans.do(voc.strip())

    return BREAK
