import logging

from importlib import import_module
from re import Pattern, compile
from unicodedata import normalize as precomp_normalize

from scriptshifter.exceptions import BREAK, CONT
from scriptshifter.hooks.general import normalize_spacing_post_assembly
from scriptshifter.tables import (
        BOW, EOW, FEAT_R2S, FEAT_S2R, HOOK_PKG_PATH,
        get_connection, get_lang_dcap, get_lang_general, get_lang_hooks,
        get_lang_ignore, get_lang_map, get_lang_normalize)

logger = logging.getLogger(__name__)

WORD_PTN = compile(r"\w")
WB_PTN = compile(r"\W")


class Transliterator:
    """
    Context carrying the state of transliteration process.

    Use within a `with` block for proper cleanup.
    """
    @property
    def orig(self):
        return self._orig

    @orig.setter
    def orig(self, v):
        raise NotImplementedError("Attribute is read-only.")

    @orig.deleter
    def orig(self):
        raise NotImplementedError("Attribute is read-only.")

    @property
    def cur_char(self):
        return self.src[self.cur]

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
        self._orig = src
        self.src = src
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

    def run_hook(self, hname):
        ret = None
        for hook_def in self.hooks.get(hname, []):
            fn = getattr(
                import_module("." + hook_def["module_name"], HOOK_PKG_PATH),
                hook_def["fn_name"]
            )
            ret = fn(self, **hook_def["kwargs"])
            if ret in (BREAK, CONT):
                # This will stop parsing hooks functions and tell the caller to
                # break out of the outer loop or skip iteration.
                return ret

        return ret

    def normalize_src(self):
        """
        Normalize source text according to rules.

        NOTE: this manipluates the protected source attribute so it may not
        correspond to the originally provided source.
        """
        # Normalize precomposed Unicode characters.
        #
        # In using diacritics, LC standards prefer the decomposed form
        # (combining diacritic + base character) to the pre-composed form
        # (single Unicode symbol for the letter with diacritic).
        #
        # Note: only safe for R2S.
        if self.t_dir == FEAT_R2S:
            logger.debug("Normalizing pre-composed symbols.")
            self.src = precomp_normalize("NFD", self.src)

        norm_rules = get_lang_normalize(self.conn, self.lang_id)

        for nk, nv in norm_rules.items():
            self.src = self.src.replace(nk, nv)

        return self.run_hook("post_normalize")

    def cur_at_bow(self, cur=None):
        """
        Check if cursor is at the beginning of a word.

        @param cur(int): Position to check. By default, the current cursor.
        """
        if cur is None:
            cur = self.cur
        return (
            self.cur == 0
            or WB_PTN.match(self.src[cur - 1])
        ) and WORD_PTN.match(self.src[cur])

    def cur_at_eow(self, cur=None):
        """
        Check if cursor is at the end of a word.

        @param cur(int): Position to check. By default, the current cursor.
        """
        if cur is None:
            cur = self.cur
        return (
            cur == len(self.src) - 1
            or WB_PTN.match(self.src[cur + 1])
        ) and WORD_PTN.match(self.src[cur])


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
    with Transliterator(lang, src, t_dir, options) as ctx:

        if t_dir == FEAT_S2R and not ctx.general["has_s2r"]:
            raise NotImplementedError(
                f"Script-to-Roman not yet supported for {lang}."
            )
        if t_dir == FEAT_R2S and not ctx.general["has_r2s"]:
            raise NotImplementedError(
                f"Roman-to-script not yet supported for {lang}."
            )

        # Normalize case before post_config and rule-based normalization.
        if t_dir == FEAT_R2S and not ctx.general["case_sensitive"]:
            ctx.src = ctx.src.lower()

        # This hook may take over the whole transliteration process or delegate
        # it to some external process, and return the output string directly.
        if ctx.run_hook("post_config") == BREAK:
            return getattr(ctx, "dest", ""), ctx.warnings

        # ctx.normalize_src returns the results of the post_normalize hook.
        if ctx.normalize_src() == BREAK:
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

            # Look for a word boundary and flag word beginning/end it if found.
            if ctx.cur_at_bow():
                # Beginning of word.
                logger.debug(f"Beginning of word at position {ctx.cur}.")
                ctx.cur_flags |= BOW
            if ctx.cur_at_eow():
                # End of word.
                logger.debug(f"End of word at position {ctx.cur}.")
                ctx.cur_flags |= EOW

            # This hook may skip the parsing of the current
            # token or exit the scanning loop altogether.
            hret = ctx.run_hook("begin_input_token")
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
                    hret = ctx.run_hook("pre_ignore_token")
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
                        hret = ctx.run_hook("on_ignore_match")
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
                hret = ctx.run_hook("pre_tx_token")
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
                if ctx.src_tk.content[0] > ctx.cur_char:
                    logger.debug(
                            f"{ctx.src_tk.content} is after "
                            f"{ctx.src[ctx.cur:ctx.cur + step]}. "
                            "Breaking loop.")
                    break

                # If src_tk has a WB flag but the token is not at WB, skip.
                if (
                    (ctx.src_tk.flags & BOW and not ctx.cur_flags & BOW)
                    or (
                        # Can't rely on EOW flag, we must check on the last
                        # character of the potential match.
                        ctx.src_tk.flags & EOW
                        and not ctx.cur_at_eow(ctx.cur + step - 1)
                    )
                ):
                    continue

                # Longer tokens should be guaranteed to be scanned before their
                # substrings at this point.
                # Similarly, flagged tokens are evaluated first.
                if ctx.src_tk.content == ctx.src[ctx.cur:ctx.cur + step]:
                    ctx.match = True
                    # This hook may skip this token or break out of the token
                    # lookup for the current position.
                    hret = ctx.run_hook("on_tx_token_match")
                    if hret == BREAK:
                        break
                    if hret == CONT:
                        continue

                    # A match is found. Stop scanning tokens, append result,
                    # and proceed scanning the source.

                    # Capitalization. This applies double capitalization
                    # rules. The external function in
                    # scriptshifter.tools.capitalize used for non-table
                    # languages does not.
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
                hret = ctx.run_hook("on_no_tx_token_match")
                if hret == BREAK:
                    break
                if hret == CONT:
                    continue

                # No match found. Copy non-mapped character (one at a time).
                logger.info(
                        f"Token {ctx.cur_char} "
                        f"(\\u{hex(ord(ctx.cur_char))[2:]}) "
                        f"at position {ctx.cur} is not mapped.")
                ctx.dest_ls.append(ctx.cur_char)
                ctx.cur += 1
            else:
                delattr(ctx, "match")
            delattr(ctx, "cur_flags")

        delattr(ctx, "cur")

        # This hook may take care of the assembly and cause the function to
        # return its own return value.
        if ctx.run_hook("pre_assembly") == BREAK:
            return ctx.dest, ctx.warnings

        logger.debug(f"Output list: {ctx.dest_ls}")
        ctx.dest = "".join(ctx.dest_ls)

        # This hook may reassign the output string and/or cause the function to
        # return it immediately.
        if ctx.run_hook("post_assembly") == BREAK:
            return ctx.dest, ctx.warnings

        normalize_spacing_post_assembly(ctx)

        return ctx.dest, ctx.warnings
