# @package ext

__doc__ = """
Transliterate a number of Indian and other Asian scripts using Aksharamukha:
https://github.com/virtualvinodh/aksharamukha-python """


from logging import getLogger

from aksharamukha.transliterate import process

from scriptshifter.exceptions import BREAK


logger = getLogger(__name__)


def s2r_post_config(ctx, src_script):
    # options = detect_preoptions(ctx.src, src_script)
    options = [n for n, v in ctx.options.items() if v and n != "capitalize"]
    logger.info(f"Options for {src_script}: {options}")
    ctx.dest = process(src_script, "IAST", ctx.src, pre_options=options)

    return BREAK


def r2s_post_config(ctx, dest_script):
    ctx.dest = process("IAST", dest_script, ctx.src)

    return BREAK
