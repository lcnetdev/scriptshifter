from logging import getLogger
from os import path

from yaml import load as yload
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


logger = getLogger(__name__)

MOD_BASEDIR = path.dirname(__file__)

with open(path.join(MOD_BASEDIR, "tibetan_roman_preprocess.yml")) as fh:
    pre_map = yload(fh, Loader=Loader)


def post_normalize(ctx):
    """
    Preprocess Roman input to convert legacy mappings.

    Occurrences of ṅ, ñ, ś, and ź are converted to ng, ny, sh, and zh,
    respectively.
    """
    for k, v in pre_map.items():
        ctx.src = ctx.src.replace(k, v)

    if ctx.orig != ctx.src:
        logger.debug(f"Corrected Roman source: {ctx.orig} -> {ctx.src}")
