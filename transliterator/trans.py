import logging
import re

from transliterator.tables import load_table


# Match multiple spaces.
MULTI_WS_RE = re.compile(r"\s{2,}")


logger = logging.getLogger(__name__)


def transliterate(src, script, lang, s2r=True):
    """
    Transliterate a single string.

    Args:
        src (str): Source string.

        lang (str): Language name.

        script (str): Name of the script that the language is encoded in.

    Keyword args:
        s2r (bool): If True (the default), the source is considered to be a
        non-latin script in the language and script specified, and the output
        the Romanization thereof; if False, the source is considered to be
        romanized text to be transliterated into the specified script/language.

    Return:
        str: The transliterated string.
    """
    # TODO script is ignored at the moment.
    cfg = load_table(lang)
    # General directives.
    # general_dir = cfg.get("directives", {})

    # We could be clever here but let's give the users a precise message.
    if s2r and "script_to_roman" not in cfg:
        raise NotImplementedError(
            f"Script-to-Roman transliteration not yet supported for {lang}."
        )
    elif not s2r and "roman_to_script" not in cfg:
        raise NotImplementedError(
            f"Roman-to-script transliteration not yet supported for {lang}."
        )

    langsec = cfg["script_to_roman"] if s2r else cfg["roman_to_script"]
    langsec_dir = langsec.get("directives", {})

    i = 0
    dest_ls = []
    # Loop through source characters. The increment of each loop depends on the
    # length of the token that eventually matches.
    while i < len(src):
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
            # Copy non-mapped character (one at a time).
            logger.info(f"Token {src[i]} at position {i} is not mapped.")
            dest_ls.append(src[i])
            i += 1

    if langsec_dir.get("capitalize", False):
        dest_ls[0] = dest_ls[0].capitalize()

    logger.info(f"Output list: {dest_ls}")
    dest = "".join(dest_ls)

    dest = re.sub(MULTI_WS_RE, ' ', dest)

    return dest
