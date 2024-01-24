import logging
import re

from scriptshifter.exceptions import BREAK, CONT
from scriptshifter.tables import WORD_BOUNDARY, load_table


# Match multiple spaces.
MULTI_WS_RE = re.compile(r"\s{2,}")

# Cursor bitwise flags.
CUR_BOW = 1 << 0
CUR_EOW = 1 << 1

logger = logging.getLogger(__name__)


class Context:
    """
    Context used within the transliteration and passed to hook functions.
    """
    @property
    def src(self):
        return self._src

    @src.setter
    def src(self, _):
        raise NotImplementedError("Atribute is read-only.")

    @src.deleter
    def src(self):
        raise NotImplementedError("Atribute is read-only.")

    def __init__(self, src, general, langsec, options={}):
        """
        Initialize a context.

        Args:
            src (str): The original text. Read-only.
            general (dict): general section of the current config.
            langsec (dict): Language configuration section being used.
            options (dict): extra options as a dict.
        """
        self._src = src
        self.general = general
        self.options = options
        self.langsec = langsec
        self.dest_ls = []
        self.warnings = []


def transliterate(src, lang, t_dir="s2r", capitalize=False, options={}):
    """
    Transliterate a single string.

    Args:
        src (str): Source string.

        lang (str): Language name.

        t_dir (str): Transliteration direction. Either `s2r` for
            script-to-Roman (default) or `r2s`  for Roman-to-script.

        capitalize: capitalize words: one of `False` (no change - default),
            `"first"` (only first letter), or `"all"` (first letter of each
            word).

        options: extra script-dependent options. Defaults to the empty map.

    Keyword args:
        r2s (bool): If False (the default), the source is considered to be a
        non-latin script in the language and script specified, and the output
        the Romanization thereof; if True, the source is considered to be
        romanized text to be transliterated into the specified script/language.

    Return:
        str: The transliterated string.
    """
    source_str = "Latin" if t_dir == "r2s" else lang
    target_str = lang if t_dir == "r2s" else "Latin"
    logger.info(f"Transliteration is from {source_str} to {target_str}.")

    cfg = load_table(lang)
    logger.info(f"Loaded table for {lang}.")

    # General directives.
    general = cfg.get("general", {})

    if t_dir == "s2r" and "script_to_roman" not in cfg:
        raise NotImplementedError(
            f"Script-to-Roman transliteration not yet supported for {lang}."
        )
    elif t_dir == "r2s" and "roman_to_script" not in cfg:
        raise NotImplementedError(
            f"Roman-to-script transliteration not yet supported for {lang}."
        )

    langsec = (
            cfg["script_to_roman"] if t_dir == "s2r"
            else cfg["roman_to_script"])
    # langsec_dir = langsec.get("directives", {})
    langsec_hooks = langsec.get("hooks", {})

    src = src.strip()
    options["capitalize"] = capitalize
    ctx = Context(src, general, langsec, options)

    # This hook may take over the whole transliteration process or delegate it
    # to some external process, and return the output string directly.
    if _run_hook("post_config", ctx, langsec_hooks) == BREAK:
        return getattr(ctx, "dest", ""), ctx.warnings

    if "normalize" in ctx.langsec:
        _normalize_src(ctx)

    if _run_hook("post_normalize", ctx, langsec_hooks) == BREAK:
        return getattr(ctx, "dest", ""), ctx.warnings

    # Loop through source characters. The increment of each loop depends on
    # the length of the token that eventually matches.
    ignore_list = langsec.get("ignore", [])  # Only present in R2S
    ctx.cur = 0
    word_boundary = langsec.get("word_boundary", WORD_BOUNDARY)
    while ctx.cur < len(ctx.src):
        # Reset cursor position flags.
        # Carry over extended "beginning of word" flag.
        ctx.cur_flags = 0
        cur_char = ctx.src[ctx.cur]

        # Look for a word boundary and flag word beginning/end it if found.
        if (ctx.cur == 0 or ctx.src[ctx.cur - 1] in word_boundary) and (
                cur_char not in word_boundary):
            # Beginning of word.
            logger.debug(f"Beginning of word at position {ctx.cur}.")
            ctx.cur_flags |= CUR_BOW
        if (
            ctx.cur == len(ctx.src) - 1
            or ctx.src[ctx.cur + 1] in word_boundary
        ) and (cur_char not in word_boundary):
            # End of word.
            logger.debug(f"End of word at position {ctx.cur}.")
            ctx.cur_flags |= CUR_EOW

        # This hook may skip the parsing of the current
        # token or exit the scanning loop altogether.
        hret = _run_hook("begin_input_token", ctx, langsec_hooks)
        if hret == BREAK:
            logger.debug("Breaking text scanning from hook signal.")
            break
        if hret == CONT:
            logger.debug("Skipping scanning iteration from hook signal.")
            continue

        # Check ignore list. Find as many subsequent ignore tokens
        # as possible before moving on to looking for match tokens.
        ctx.tk = None
        while True:
            ctx.ignoring = False
            for ctx.tk in ignore_list:
                hret = _run_hook("pre_ignore_token", ctx, langsec_hooks)
                if hret == BREAK:
                    break
                if hret == CONT:
                    continue

                step = len(ctx.tk)
                if ctx.tk == ctx.src[ctx.cur:ctx.cur + step]:
                    # The position matches an ignore token.
                    hret = _run_hook("on_ignore_match", ctx, langsec_hooks)
                    if hret == BREAK:
                        break
                    if hret == CONT:
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
            if hret == BREAK:
                break
            if hret == CONT:
                continue

            step = len(ctx.src_tk)

            # If the first character of the token is greater (= higher code
            # point value) than the current character, then break the loop
            # without a match, because we know there won't be any more match
            # due to the alphabetical ordering.
            if ctx.src_tk[0] > cur_char:
                logger.debug(
                        f"{ctx.src_tk} is after "
                        f"{ctx.src[ctx.cur:ctx.cur + step]}. Breaking loop.")
                break

            # Longer tokens should be guaranteed to be scanned before their
            # substrings at this point.
            if ctx.src_tk == ctx.src[ctx.cur:ctx.cur + step]:
                ctx.match = True
                # This hook may skip this token or break out of the token
                # lookup for the current position.
                hret = _run_hook("on_tx_token_match", ctx, langsec_hooks)
                if hret == BREAK:
                    break
                if hret == CONT:
                    continue

                # A match is found. Stop scanning tokens, append result, and
                # proceed scanning the source.

                # Capitalization.
                if (
                    (ctx.options["capitalize"] == "first" and ctx.cur == 0)
                    or
                    (
                        ctx.options["capitalize"] == "all"
                        and ctx.cur_flags & CUR_BOW
                    )
                ):
                    logger.info("Capitalizing token.")
                    double_cap = False
                    for dcap_rule in ctx.langsec.get("double_cap", []):
                        if ctx.dest_tk == dcap_rule:
                            ctx.dest_tk = ctx.dest_tk.upper()
                            double_cap = True
                            break
                    if not double_cap:
                        ctx.dest_tk = ctx.dest_tk[0].upper() + ctx.dest_tk[1:]

                ctx.dest_ls.append(ctx.dest_tk)
                ctx.cur += step
                break

        if ctx.match is False:
            delattr(ctx, "match")
            hret = _run_hook("on_no_tx_token_match", ctx, langsec_hooks)
            if hret == BREAK:
                break
            if hret == CONT:
                continue

            # No match found. Copy non-mapped character (one at a time).
            logger.info(
                    f"Token {cur_char} (\\u{hex(ord(cur_char))[2:]}) "
                    f"at position {ctx.cur} is not mapped.")
            ctx.dest_ls.append(cur_char)
            ctx.cur += 1
        else:
            delattr(ctx, "match")
        delattr(ctx, "cur_flags")

    delattr(ctx, "cur")

    # This hook may take care of the assembly and cause the function to return
    # its own return value.
    hret = _run_hook("pre_assembly", ctx, langsec_hooks)
    if hret is not None:
        return hret, ctx.warnings

    logger.debug(f"Output list: {ctx.dest_ls}")
    ctx.dest = "".join(ctx.dest_ls)

    # This hook may reassign the output string and/or cause the function to
    # return it immediately.
    hret = _run_hook("post_assembly", ctx, langsec_hooks)
    if hret == "ret":
        return ctx.dest, ctx.warnings

    # Strip multiple spaces and leading/trailing whitespace.
    ctx.dest = re.sub(MULTI_WS_RE, ' ', ctx.dest.strip())

    return ctx.dest, ctx.warnings


def _normalize_src(ctx):
    for nk, nv in ctx.langsec.get("normalize", {}).items():
        ctx._src = ctx.src.replace(nk, nv)
    logger.debug(f"Normalized source: {ctx.src}")


def _run_hook(hname, ctx, hooks):
    ret = None
    for hook_def in hooks.get(hname, []):
        kwargs = hook_def[1] if len(hook_def) > 1 else {}
        ret = hook_def[0](ctx, **kwargs)
        if ret in (BREAK, CONT):
            # This will stop parsing hooks functions and tell the caller to
            # break out of the outer loop or skip iteration.
            return ret

    return ret
