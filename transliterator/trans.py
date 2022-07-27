import logging
import re

from transliterator.tables import load_table


# Match multiple spaces.
MULTI_WS_RE = re.compile(r"\s{2,}")


logger = logging.getLogger(__name__)


class Context:
    """
    Context used within the transliteration and passed to hook functions.
    """
    cur = 0  # Input text cursor.
    dest_ls = []  # Token list making up the output string.

    def __init__(self, src, general, langsec):
        """
        Initialize a context.

        Args:
            src (str): The original text. This is meant to never change.
            general (dict): general section of the current config.
            langsec (dict): Language configuration section being used.
        """
        self.src = src
        self.general = general
        self.langsec = langsec


def transliterate(src, lang, r2s=False):
    """
    Transliterate a single string.

    Args:
        src (str): Source string.

        lang (str): Language name.

    Keyword args:
        r2s (bool): If False (the default), the source is considered to be a
        non-latin script in the language and script specified, and the output
        the Romanization thereof; if True, the source is considered to be
        romanized text to be transliterated into the specified script/language.

    Return:
        str: The transliterated string.
    """
    source_str = "Latin" if r2s else lang
    target_str = lang if r2s else "Latin"
    logger.info(f"Transliteration is from {source_str} to {target_str}.")

    cfg = load_table(lang)
    logger.info(f"Loaded table for {lang}.")

    # General directives.
    general = cfg.get("general", {})

    if not r2s and "script_to_roman" not in cfg:
        raise NotImplementedError(
            f"Script-to-Roman transliteration not yet supported for {lang}."
        )
    elif r2s and "roman_to_script" not in cfg:
        raise NotImplementedError(
            f"Roman-to-script transliteration not yet supported for {lang}."
        )

    langsec = cfg["script_to_roman"] if not r2s else cfg["roman_to_script"]
    langsec_dir = langsec.get("directives", {})
    langsec_hooks = langsec.get("hooks", {})

    ctx = Context(src, general, langsec)

    _run_hook("post_config", ctx, langsec_hooks)

    # Loop through source characters. The increment of each loop depends on
    # the length of the token that eventually matches.
    ignore_list = langsec.get("ignore", [])  # Only present in R2S
    while ctx.cur < len(src):
        # This hook may skip the parsing of the current
        # token or exit the scanning loop altogether.
        hret = _run_hook("begin_input_token", ctx, langsec_hooks)
        if hret == "break":
            break
        if hret == "continue":
            continue
        # Check ignore list first. Find as many subsequent ignore tokens
        # as possible before moving on to looking for match tokens.
        ctx.tk = None
        while True:
            ctx.ignoring = False
            for ctx.tk in ignore_list:
                hret = _run_hook("pre_ignore_token", ctx, langsec_hooks)
                if hret == "break":
                    break
                if hret == "continue":
                    continue

                step = len(ctx.tk)
                if ctx.tk == src[ctx.cur:ctx.cur + step]:
                    # The position matches an ignore token.
                    hret = _run_hook("on_ignore_match", ctx, langsec_hooks)
                    if hret == "break":
                        break
                    if hret == "continue":
                        continue

                    logger.info(f"Ignored token: {ctx.tk}")
                    ctx.dest_ls.append(ctx.tk)
                    ctx.cur += step
                    ctx.ignoring = True
                    break
            # We looked through all ignore tokens, not found any. Move on.
            if not ctx.ignoring:
                break
            # Otherwise, if we found a match, check if the next position may be
            # ignored as well.

        delattr(ctx, "tk")
        delattr(ctx, "ignoring")

        # Begin transliteration token lookup.
        ctx.match = False
        for ctx.src_tk, ctx.dest_tk in langsec["map"]:
            hret = _run_hook("pre_tx_token", ctx, langsec_hooks)
            if hret == "break":
                break
            if hret == "continue":
                continue

            # Longer tokens should be guaranteed to be scanned before their
            # substrings at this point.
            step = len(ctx.src_tk)
            if ctx.src_tk == src[ctx.cur:ctx.cur + step]:
                ctx.match = True
                # This hook may skip this token or break out of the token
                # lookup for the current position.
                hret = _run_hook("on_tx_token_match", ctx, langsec_hooks)
                if hret == "break":
                    break
                if hret == "continue":
                    continue

                # A match is found. Stop scanning tokens, append result, and
                # proceed scanning the source.
                ctx.dest_ls.append(ctx.dest_tk)
                ctx.cur += step
                break

        if ctx.match is False:
            hret = _run_hook("on_no_tx_token_match", ctx, langsec_hooks)
            if hret == "break":
                break
            if hret == "continue":
                continue

            # No match found. Copy non-mapped character (one at a time).
            logger.info(
                f"Token {src[ctx.cur]} at position {ctx.cur} is not mapped."
            )
            ctx.dest_ls.append(src[ctx.cur])
            ctx.cur += 1

    delattr(ctx, "src_tk")
    delattr(ctx, "dest_tk")
    delattr(ctx, "match")
    delattr(ctx, "cur")

    # This hook may take care of the assembly and cause the function to return
    # its own return value.
    hret = _run_hook("pre_assembly", ctx, langsec_hooks)
    if hret is not None:
        return hret

    if langsec_dir.get("capitalize", False):
        ctx.dest_ls[0] = ctx.dest_ls[0].capitalize()

    logger.debug(f"Output list: {ctx.dest_ls}")
    ctx.dest = "".join(ctx.dest_ls)

    # This hook may reassign the output string and/or cause the function to
    # return it immediately.
    hret = _run_hook("post_assembly", ctx, langsec_hooks)
    if hret == "ret":
        return ctx.dest

    # Strip multiple spaces and leading/trailing whitespace.
    ctx.dest = re.sub(MULTI_WS_RE, ' ', ctx.dest.strip())

    return ctx.dest


def _run_hook(hname, ctx, hooks):
    for hook_def in hooks.get(hname, []):
        kwargs = hook_def[1] if len(hook_def > 1) else {}
        ret = hook_def[0](ctx, **kwargs)
        if ret in ("break", "cont"):
            # This will stop parsing hooks functions and tell the caller to
            # break out of the outer loop or skip iteration.
            return ret

    return ret
