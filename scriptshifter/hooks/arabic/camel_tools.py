from camel_tools.utils.charmap import CharMapper
from camel_tools.utils.dediac import dediac_ar
from camel_tools.utils.normalize import (
        normalize_unicode,
        normalize_alef_maksura_ar,
        normalize_alef_ar,
        normalize_teh_marbuta_ar)

from scriptshifter.exceptions import BREAK


def s2r_post_config(ctx):
    # Unicode normalization
    src = normalize_unicode(ctx.src)

    # Orthographic normalization
    src = normalize_alef_maksura_ar(src)
    src = normalize_alef_ar(src)
    src = normalize_teh_marbuta_ar(src)

    # Dediacritization.
    src = dediac_ar(src)

    # Conversion proper.
    ar2bw = CharMapper.builtin_mapper("ar2bw")
    ctx.dest = ar2bw(src)

    return BREAK
