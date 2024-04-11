__doc__ = """Chinese hooks."""


from logging import getLogger
from os import path
from re import I, compile, search, sub

from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


HOOK_DIR = path.dirname(path.realpath(__file__))

logger = getLogger(__name__)


def merge_numerals_pre_config(tdata):
    """
    Add numerals mapping to configuration.

    This overrides the existing character mappings.
    """
    num_map_yml = path.join(HOOK_DIR, "numerals.yml")
    with open(num_map_yml, "r") as fh:
        num_map = load(fh, Loader=Loader)

    tdata["script_to_roman"]["map"].update(num_map)


def parse_numerals(ctx):
    """
    Parse Chinese numerals in the already romanized result.

    This is run at post-assembly.
    """
    # Only apply to specific MARC fields.
    use_num_v = ctx.options.get("marc_field") in ("245", "830")

    # tokens = split(r"[\W^#]", ctx.dest)  # Original logic.
    tokens = [tk.strip() for tk in ctx.dest_ls]
    tk_ct = len(tokens)
    token_ptn = compile(r"^([A-Za-z]+)#([0-9]*)$")

    output = ""

    # Use manual loop as i is manipulated inside it.
    i = 0

    while i < tk_ct:
        tk_i = tokens[i]
        if search(token_ptn, tk_i):
            # When a numerical token (containing #) is reached, the inner loop
            # consumes it and all consecutive numerical tokens found after it.
            # Two versions of the string are maintained. The textVersion is
            # the original pinyin (minus the # suffixes). In the numVersion,
            # characters representing numbers are converted to Arabic
            # numerals. When a non-numerical token (or end of string) is
            # encountered, the string of numerical tokens is evaluated to
            # determine which version should be used in the output string.
            # The outer loop then continues where the inner loop left off.
            logger.debug(f"Match number: {tk_i}")
            text_v = num_v = ""
            for j in range(i, tk_ct):
                tk_j = tokens[j]
                m = search(token_ptn, tk_j)
                # if m:
                #     logger.debug(f"m[1]: {m[1]} - m[2]: {m[2]}")
                # a token without # (or the end of string) is reached
                if not m or j == tk_ct - 1:
                    logger.debug(f"Next token is not numeric: {tk_j}")
                    # If this runs, then we are on the last token and it is
                    # numeric. Add text after # (if present) to numerical
                    # version
                    if m:
                        text_v += m[1] + " "
                        num_v += m[2] if len(m[2]) else m[1]
                        # Append white space.
                        num_v += " "
                    elif j == tk_ct - 1:
                        # if last token is non-numerical, just tack it on.
                        logger.debug(f"Last token is non-numerical: {tk_j}")
                        text_v += tk_j
                        num_v += tk_j
                    # evaluate numerical string that has been constructed so
                    # far. Use num version for ordinals and date strings
                    if (
                        search("^di [0-9]", num_v, flags=I) or
                        search("[0-9] [0-9] [0-9] [0-9]", num_v) or
                        search("[0-9]+ nian [0-9]+ yue", num_v, flags=I) or
                        search("\"[0-9]+ yue [0-9]+ ri", num_v, flags=I)
                    ):
                        use_num_v = True
                        # At this point, string may contain literal
                        # translations of Chinese numerals Convert these to
                        # Arabic numerals (for example "2 10 7" = "27").
                        mult_ptn = compile(r"(\b[0-9]) ([1-9]0+)")
                        sum_ptn = compile("([1-9]0+) ([0-9]+)")
                        while _m := search("[0-9] 10+|[1-9]0+ [1-9]", num_v):
                            logger.debug(f"Match number combination: {_m}")
                            if m := mult_ptn.search(num_v):
                                logger.debug(f"Multiply: {m[1]}, {m[2]}")
                                parsed = int(m[1]) * int(m[2])
                                num_v = mult_ptn.sub(str(parsed), num_v, 1)
                            elif m := sum_ptn.search(num_v):
                                logger.debug(f"Add: {m[1]}, {m[2]}")
                                parsed = int(m[1]) + int(m[2])
                                num_v = sum_ptn.sub(str(parsed), num_v, 1)
                            else:
                                break
                        # A few other tweaks
                        num_v = sub(
                                "([0-9]) ([0-9]) ([0-9]) ([0-9])",
                                r"\1\2\3\4", num_v)
                        if ctx.options.get("marc_field") in ("245", "830"):
                            # TODO optimize without loop.
                            while search("[0-9] [0-9]", num_v):
                                num_v = sub("([0-9]) ([0-9])", r"\1\2", num_v)

                    logger.debug(f"num_v: {num_v}")
                    logger.debug(f"text_v: {text_v}")
                    output += num_v if use_num_v else text_v

                    # if the end of the string is not reached, backtrack to the
                    # delimiter after the last numerical token (i.e. two tokens
                    # ago).
                    #
                    # Else, we are at the end of the string, so we are done!
                    i = j - 1 if j < tk_ct - 1 else j
                    break

                # this is run when we are not yet at the end of the string and
                # have not yet reached a non-numerical token. This is identical
                # to the code that is run above when the last token is numeric.
                m = search(token_ptn, tk_j)
                text_v += m[1] + " "
                num_v += m[2] if len(m[2]) else m[1]
                num_v += " "

        else:
            logger.debug(f"No match: adding {tk_i}.")
            output += tk_i + " "

        i += 1

    print(f"Use num version: {use_num_v}")
    ctx.dest = output
