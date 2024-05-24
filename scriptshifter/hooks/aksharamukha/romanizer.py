# @package ext

__doc__ = """
Transliterate a number of Indian and other Asian scripts using Aksharamukha:
https://github.com/virtualvinodh/aksharamukha-python """


from logging import getLogger

from aksharamukha.transliterate import process

from scriptshifter.exceptions import BREAK


logger = getLogger(__name__)


def s2r_post_config(ctx, src_script, pre=[], post=[]):
    # options = detect_preoptions(ctx.src, src_script)
    pre_options = pre + [
            n for n, v in ctx.options.items() if v and n != "capitalize"]
    ctx.dest = process(
            src_script, "RomanLoC", ctx.src,
            pre_options=pre_options, post_options=post)

    return BREAK


def r2s_post_config(ctx, dest_script, pre=[], post=[]):
    post_options = post + [
            n for n, v in ctx.options.items() if v and n != "capitalize"]
    ctx.dest = process(
            "RomanLoC", dest_script, ctx.src,
            pre_options=pre, post_options=post_options)

    return BREAK
