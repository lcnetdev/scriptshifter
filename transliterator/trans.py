import logging
import re

from transliterator.tables import load_table


# Match multiple spaces.
MULTI_WS_RE = re.compile(r"\s{2,}")


logger = logging.getLogger(__name__)


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
    # general_dir = cfg.get("directives", {})

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

    i = 0
    dest_ls = []
    # Loop through source characters. The increment of each loop depends on
    # the length of the token that eventually matches.
    ignore_list = langsec.get("ignore", [])  # Only present in R2S
    while i < len(src):
        # Check ignore list first. Find as many subsequent ignore tokens
        # as possible before moving on to looking for match tokens.
        while True:
            ignoring = False
            for tk in ignore_list:
                step = len(tk)
                if tk == src[i:i + step]:
                    logger.info(f"Ignored token: {tk}")
                    dest_ls.append(tk)
                    i += step
                    ignoring = True
                    break
            # We looked through all ignore tokens, not found any. Move on.
            if not ignoring:
                break

        match = False
        for src_tk, dest_tk in langsec["map"]:
            # Longer tokens should be guaranteed to be scanned before their
            # substrings at this point.
            step = len(src_tk)
            if src_tk == src[i:i + step]:
                # A match is found. Stop scanning tokens, append result, and
                # proceed scanning the source.
                dest_ls.append(dest_tk)
                match = True
                i += step
                break

        if not match:
            # No match found. Copy non-mapped character (one at a time).
            logger.info(f"Token {src[i]} at position {i} is not mapped.")
            dest_ls.append(src[i])
            i += 1

    if langsec_dir.get("capitalize", False):
        dest_ls[0] = dest_ls[0].capitalize()

    logger.debug(f"Output list: {dest_ls}")
    dest = "".join(dest_ls)

    dest = re.sub(MULTI_WS_RE, ' ', dest.strip())

    return dest
