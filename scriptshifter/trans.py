import logging

from importlib import import_module
from re import Pattern, compile
from unicode_data import normalize as precomp_normalize

from scriptshifter.exceptions import BREAK, CONT
from scriptshifter.tables import (
        BOW, EOW, WORD_BOUNDARY, FEAT_R2S, FEAT_S2R, HOOK_PKG_PATH,
        get_connection, get_lang_dcap, get_lang_general, get_lang_hooks,
        get_lang_ignore, get_lang_map, get_lang_normalize)


# Match multiple spaces.
MULTI_WS_RE = compile(r"(\s){2,}")

logger = logging.getLogger(__name__)


class Context:
    """
    Context used within the transliteration and passed to hook functions.

    Use within a `with` block for proper cleanup.
    """
    @property
    def src(self):
        return self._src

    @src.setter
    def src(self):
        raise NotImplementedError("Attribute is read-only.")

    @src.deleter
    def src(self):
        raise NotImplementedError("Attribute is read-only.")

    def __init__(self, lang, src, t_dir, options={}):
        """
        Initialize a context.

        Args:
            src (str): The original text. Read-only.
            t_dir (int): the direction of transliteration.
                    Either FEAT_R2S or FEAT_S2R.
            options (dict): extra options as a dict.
        """
        self.lang = lang
        self._src = src
        self.t_dir = t_dir
        self.conn = get_connection()
        with self.conn as conn:
            general = get_lang_general(conn, self.lang)
        self.general = general["data"]
        self.lang_id = general["id"]
        self.options = options
        self.hooks = get_lang_hooks(self.conn, self.lang_id, self.t_dir)
        self.dest_ls = []
        self.warnings = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.conn.close()


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
    # Map t_dir to constant.
    t_dir = FEAT_S2R if t_dir == "s2r" else FEAT_R2S

    source_str = "Roman" if t_dir == FEAT_R2S else lang
    target_str = lang if t_dir == FEAT_R2S else "Roman"
    logger.info(f"Transliteration is from {source_str} to {target_str}.")

    src = src.strip()
    options["capitalize"] = capitalize
    with Context(lang, src, t_dir, options) as ctx:

        if t_dir == FEAT_S2R and not ctx.general["has_s2r"]:
            raise NotImplementedError(
                f"Script-to-Roman not yet supported for {lang}."
            )
        if t_dir == FEAT_R2S and not ctx.general["has_r2s"]:
            raise NotImplementedError(
                f"Roman-to-script not yet supported for {lang}."
            )

        # Normalize case before post_config and rule-based normalization.
        if not ctx.general["case_sensitive"]:
            ctx._src = ctx.src.lower()

        # This hook may take over the whole transliteration process or delegate
        # it to some external process, and return the output string directly.
        if _run_hook("post_config", ctx) == BREAK:
            return getattr(ctx, "dest", ""), ctx.warnings

        # _normalize_src returns the results of the post_normalize hook.
        if _normalize_src(
                ctx, get_lang_normalize(ctx.conn, ctx.lang_id)) == BREAK:
            return getattr(ctx, "dest", ""), ctx.warnings

        logger.debug(f"Normalized source: {ctx.src}")
        lang_map = list(get_lang_map(ctx.conn, ctx.lang_id, ctx.t_dir))

        # Loop through source characters. The increment of each loop depends on
        # the length of the token that eventually matches.
        ctx.cur = 0

        while ctx.cur < len(ctx.src):
            # Reset cursor position flags.
            # Carry over extended "beginning of word" flag.
            ctx.cur_flags = 0
            cur_char = ctx.src[ctx.cur]

            # Look for a word boundary and flag word beginning/end it if found.
            if _is_bow(ctx.cur, ctx, WORD_BOUNDARY):
                # Beginning of word.
                logger.debug(f"Beginning of word at position {ctx.cur}.")
                ctx.cur_flags |= BOW
            if _is_eow(ctx.cur, ctx, WORD_BOUNDARY):
                # End of word.
                logger.debug(f"End of word at position {ctx.cur}.")
                ctx.cur_flags |= EOW

            # This hook may skip the parsing of the current
            # token or exit the scanning loop altogether.
            hret = _run_hook("begin_input_token", ctx)
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
                for ctx.tk in get_lang_ignore(ctx.conn, ctx.lang_id):
                    hret = _run_hook("pre_ignore_token", ctx)
                    if hret == BREAK:
                        break
                    if hret == CONT:
                        continue

                    _matching = False
                    if type(ctx.tk) is Pattern:
                        # Seach RE pattern beginning at cursor.
                        if _ptn_match := ctx.tk.match(ctx.src[ctx.cur:]):
                            ctx.tk = _ptn_match[0]
                            logger.debug(f"Matched regex: {ctx.tk}")
                            step = len(ctx.tk)
                            _matching = True
                    else:
                        # Search exact match.
                        step = len(ctx.tk)
                        if ctx.tk == ctx.src[ctx.cur:ctx.cur + step]:
                            _matching = True

                    if _matching:
                        # The position matches an ignore token.
                        hret = _run_hook("on_ignore_match", ctx)
                        if hret == BREAK:
                            break
                        if hret == CONT:
                            continue

                        logger.info(f"Ignored token: {ctx.tk}")
                        ctx.dest_ls.append(ctx.tk)
                        ctx.cur += step
                        if ctx.cur >= len(ctx.src):
                            # reached end of string. Stop ignoring.
                            # The outer loop will exit imediately after.
                            ctx.ignoring = False
                            break

                        cur_char = ctx.src[ctx.cur]
                        ctx.ignoring = True
                        break
                # We looked through all ignore tokens, not found any. Move on.
                if not ctx.ignoring:
                    break
                # Otherwise, if we found a match, check if the next position
                # may be ignored as well.

            delattr(ctx, "tk")
            delattr(ctx, "ignoring")

            if ctx.cur >= len(ctx.src):
                break

            # Begin transliteration token lookup.
            ctx.match = False

            for ctx.src_tk, ctx.dest_str in lang_map:
                hret = _run_hook("pre_tx_token", ctx)
                if hret == BREAK:
                    break
                if hret == CONT:
                    continue

                step = len(ctx.src_tk.content)
                # If the token is longer than the remaining of the string,
                # it surely won't match.
                if ctx.cur + step > len(ctx.src):
                    continue

                # If the first character of the token is greater (= higher code
                # point value) than the current character, then break the loop
                # without a match, because we know there won't be any more
                # match due to the alphabetical ordering.
                if ctx.src_tk.content[0] > cur_char:
                    logger.debug(
                            f"{ctx.src_tk.content} is after "
                            f"{ctx.src[ctx.cur:ctx.cur + step]}. "
                            "Breaking loop.")
                    break

                # If src_tk has a WB flag but the token is not at WB, skip.
                if (
                    (ctx.src_tk.flags & BOW and not ctx.cur_flags & BOW)
                    or
                    # Can't rely on EOW flag, we must check on the last
                    # character of the potential match.
                    (ctx.src_tk.flags & EOW and not _is_eow(
                            ctx.cur + step - 1, ctx, WORD_BOUNDARY))
                ):
                    continue

                # Longer tokens should be guaranteed to be scanned before their
                # substrings at this point.
                # Similarly, flagged tokens are evaluated first.
                if ctx.src_tk.content == ctx.src[ctx.cur:ctx.cur + step]:
                    ctx.match = True
                    # This hook may skip this token or break out of the token
                    # lookup for the current position.
                    hret = _run_hook("on_tx_token_match", ctx)
                    if hret == BREAK:
                        break
                    if hret == CONT:
                        continue

                    # A match is found. Stop scanning tokens, append result,
                    # and proceed scanning the source.

                    # Capitalization.
                    if (
                        (ctx.options["capitalize"] == "first" and ctx.cur == 0)
                        or
                        (
                            ctx.options["capitalize"] == "all"
                            and ctx.cur_flags & BOW
                        )
                    ):
                        logger.info("Capitalizing token.")
                        double_cap = False
                        for dcap_rule in get_lang_dcap(ctx.conn, ctx.lang_id):
                            if ctx.dest_str == dcap_rule:
                                ctx.dest_str = ctx.dest_str.upper()
                                double_cap = True
                                break
                        if not double_cap:
                            ctx.dest_str = (
                                    ctx.dest_str[0].upper() + ctx.dest_str[1:])

                    ctx.dest_ls.append(ctx.dest_str)
                    ctx.cur += step
                    break

            if ctx.match is False:
                delattr(ctx, "match")
                hret = _run_hook("on_no_tx_token_match", ctx)
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

        # This hook may take care of the assembly and cause the function to
        # return its own return value.
        hret = _run_hook("pre_assembly", ctx)
        if hret is not None:
            return hret, ctx.warnings

        logger.debug(f"Output list: {ctx.dest_ls}")
        ctx.dest = "".join(ctx.dest_ls)

        # This hook may reassign the output string and/or cause the function to
        # return it immediately.
        hret = _run_hook("post_assembly", ctx)
        if hret is not None:
            return hret, ctx.warnings

        # Strip multiple spaces and leading/trailing whitespace.
        ctx.dest = MULTI_WS_RE.sub(r"\1", ctx.dest.strip())

        return ctx.dest, ctx.warnings


def _normalize_src(ctx, norm_rules):
    """
    Normalize source text according to rules.

    NOTE: this manipluates the protected source attribute so it may not
    correspond to the originally provided source.
    """
    # Normalize precomposed Unicode characters.
    #
    # In using diacritics, LC standards prefer the decomposed form (combining
    # diacritic + base character) to the pre-composed form (single Unicode
    # symbol for the letter with diacritic).
    ctx._src = precomp_normalize("NFD", ctx.src)

    for nk, nv in norm_rules.items():
        ctx._src = ctx.src.replace(nk, nv)

    return _run_hook("post_normalize", ctx)


def _is_bow(cur, ctx, word_boundary):
    return (cur == 0 or ctx.src[cur - 1] in word_boundary) and (
            ctx.src[cur] not in word_boundary)


def _is_eow(cur, ctx, word_boundary):
    return (
        cur == len(ctx.src) - 1
        or ctx.src[cur + 1] in word_boundary
    ) and (ctx.src[cur] not in word_boundary)


def _run_hook(hname, ctx):
    ret = None
    for hook_def in ctx.hooks.get(hname, []):
        fn = getattr(
                import_module("." + hook_def["module_name"], HOOK_PKG_PATH),
                hook_def["fn_name"])
        ret = fn(ctx, **hook_def["kwargs"])
        if ret in (BREAK, CONT):
            # This will stop parsing hooks functions and tell the caller to
            # break out of the outer loop or skip iteration.
            return ret

    return ret
