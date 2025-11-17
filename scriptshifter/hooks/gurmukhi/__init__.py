from logging import getLogger
from os import path
from re import compile

from yaml import load as yload
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


logger = getLogger(__name__)

MOD_BASEDIR = path.dirname(__file__)

with open(path.join(MOD_BASEDIR, "gurmukhi_nasalization_pre.yml")) as fh:
    nas_config = {"initial": {}, "default": {}}

    for k, v in yload(fh, Loader=Loader).items():
        if "%" in k:
            nas_config["initial"][compile(k.replace("%", "\\b"))] = v
        else:
            nas_config["default"][k] = v


def nasalize_post_normalize(ctx):
    """
    Preprocess Roman input to get a uniform nasalization.

    The result is not a correct romanization: it is an intermediate stage
    to be passed to the Gurmukhi table.
    """
    for k, v in nas_config["initial"].items():
        ctx.src = k.sub(v, ctx.src)
    for k, v in nas_config["default"].items():
        ctx.src = ctx.src.replace(k, v)

    if ctx.orig != ctx.src:
        logger.debug(f"Corrected nasalization: {ctx.orig} -> {ctx.src}")
