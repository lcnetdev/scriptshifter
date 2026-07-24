from logging import getLogger

from scriptshifter.exceptions import BREAK
from scriptshifter.hooks.general import capitalize_post_assembly
from scriptshifter.hooks.seq2seq.model import S2S


logger = getLogger(__name__)
models = {}  # Models cache.

def s2r_post_config(ctx, src_script):
    if src_script not in models:
        logger.info(f"{src_script} model not yet cached. Loading.")
        models[src_script] = S2S(src_script)

    ctx.dest = models[src_script].transliterate(ctx.src)

    if ctx.dest:
        capitalize_post_assembly(ctx)

    return BREAK
