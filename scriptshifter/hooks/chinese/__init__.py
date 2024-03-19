__doc__ = """Chinese hooks."""


from re import I, compile, match, split, sub


def parse_numerals(ctx):
    """
    Parse Chinese numerals in the already romanized result.

    This is run at post-assembly.
    """
    # Only apply to specific MARC fields.
    use_num_v = ctx.options.get("marc_field") in ("245", "830")

    tokens = split(r"[\W^#]", ctx.dest)
    tk_ct = len(tokens)

    token_ptn = compile("^([A-Za-z]+)#([0-9]*)$")

    output = ""

    # Use manual loop as i is manipulated inside it.
    i = 0
    while i < tk_ct:
        tk_i = tokens[i]
        if match(token_ptn, tk_i):
            text_v = num_v = ""
            for j, tk_j in enumerate(tokens):
                m = match(token_ptn, tk_j)
                # a token without # (or the end of string) is reached
                if ((j % 2 == 0 and not m) or j == len(tokens) - 1):
                    # If this runs, then we are on the last token and it is
                    # numeric. Add text after # (if present) to numerical
                    # version
                    if m:
                        text_v += m[1]
                        num_v += m[2] if m[2] else m[1]
                    elif j == tk_ct - 1:
                        # if last token is non-numerical, just tack it on.
                        text_v += tk_j
                        num_v += tk_j
                    elif len(text_v) and len(num_v):
                        # if not at end of string yet and token is
                        # non-numerical, remove the last delimiter that was
                        # appended (outer loop will pick up at this point)
                        text_v = text_v[:-1]
                        num_v = num_v[:-1]
                    # evaluate numerical string that has been constructed so
                    # far. Use num version for ordinals and date strings
                    if (
                        match("^di [0-9]", num_v, flags=I) or
                        match("[0-9] [0-9] [0-9] [0-9]", num_v) or
                        match("[0-9]+ nian [0-9]+ yue", num_v, flags=I) or
                        match("\"[0-9]+ yue [0-9]+ ri", num_v, flags=I)
                    ):
                        use_num_v = True
                        # At this point, string may contain literal
                        # translations of Chinese numerals Convert these to
                        # Arabic numerals (for example "2 10 7" = "27").
                        while (
                                match(num_v, "[0-9] 10+") or
                                match(num_v, "[1-9]0+ [1-9]")):
                            m = match(num_v, "([0-9]+) ([1-9]0+)")
                            if m:
                                parsed_sum = int(m[1]) + int(m[2])
                                num_v = sub(
                                        "[0-9]+ [1-9]0+", str(parsed_sum),
                                        num_v, 1)
                            else:
                                mb = match(num_v, "([1-9]0+) ([0-9]+)")
                                if mb:
                                    parsed_sum_b = int(m[1]) + int(m[2])
                                    num_v = sub(
                                            "[1-9]0+ [0-9]+",
                                            str(parsed_sum_b), num_v, 1)
                                else:
                                    break
                        # A few other tweaks
                        num_v = sub(
                                "([0-9]) ([0-9]) ([0-9]) ([0-9])",
                                r"\1\2\3\4", num_v)
                        if ctx.options.get("marc_field") in ("245", "830"):
                            # TODO optimize without loop.
                            while match("[0-9] [0-9]", num_v):
                                num_v = sub("([0-9]) ([0-9])", r"\1\2", num_v)

                    output += num_v if use_num_v else text_v

                    # if the end of the string is not reached, backtrack to the
                    # delimiter after the last numerical token (i.e. two tokens
                    # ago)

                    i = j - 2 if j < tk_ct - 1 else j
                    break

                # this is run when we are not yet at the end of the string and
                # have not yet reached a non-numerical token. This is identical
                # to the code that is run above when the last token is numeric.

                if j % 2 == 0:
                    m = match(token_ptn, tk_j)
                    text_v += m[1]
                    num_v += m[2] if m[2] else m[1]
                else:
                    text_v += tk_j
                    num_v += tk_j

        else:
            output += tk_i

    ctx.dest = output
