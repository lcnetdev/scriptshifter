# @package ext.korean
#

__doc__ = """
Korean transcription functions.

Ported from K-Romanizer: https://library.princeton.edu/eastasian/k-romanizer

Only script-to-Roman is possible for Korean.

Note that Korean Romanization must be done separately for strings containing
only personal names and strings that do not contain personal names, due to
ambiguities in the language. A non-deterministic approach using machine
learning that separates words depending on context is being attempted by other
parties, and it may be possible to eventually integrate such services here in
the future, technology and licensing permitting. At the moment there are no
such plans.

Many thanks to Hyoungbae Lee for kindly providing the original K-Romanizer
program and assistance in porting it to Python.
"""

import logging
import re

from scriptshifter.exceptions import BREAK
from scriptshifter.hooks.korean import KCONF


logger = logging.getLogger(__name__)


def s2r_nonames_post_config(ctx):
    """ Romanize a regular string NOT containing personal names. """
    ctx.dest = _romanize_nonames(ctx.src)

    return BREAK


def s2r_names_post_config(ctx):
    """
    Romanize a string containing ONLY Korean personal names.

    One or more names can be transcribed. A comma or middle dot (U+00B7) is
    to be used as separator for multiple names.
    """
    ctx.dest = _romanize_names(ctx.src)

    return BREAK


def _romanize_nonames(src):
    # FKR038
    # TODO Address Marc8Hancha() and Hancha2Hangul() (both defs missing)

    data = f" {src} "

    # FKR039, FKR040, FKR041
    for fkrcode in ("fkr039", "fkr040", "fkr041"):
        logger.debug(f"Applying {fkrcode}")
        data = data.replace(KCONF[fkrcode])

    # NOTE This is slightly different from LL 929-930 in that it doesn't
    # result in double spaces.
    data = data.replace("\r\n", " ").replace("\r", " ").replace("\n", " ")

    data = _romanize_oclc_auto(data)

    return data


def _romanize_names(src):
    return "Nothing Here Yet."


def _romanize_oclc_auto(data):
    # FKR050
    for rname, rule in KCONF["fkr050"].items():
        logger.debug(f"Applying fkr050[{rname}]")
        data = data.replace(rule)

    # NOTE: Is this memant to replace " 제" followed by a digit with " 제 "?
    # This may not yield the expected results as it could replace all
    # occurrences of " 제" as long as there is a match somewhere in the text.
    if re.match(" 제[0-9]", data):
        data = data.replace(" 제", " 제 ")
    # NOTE: Maybe this was meant:
    #data = re.sub(" 제([0-9])", "제 \\1", data):

    # FKR052
    for rname, rule in KCONF["fkr052"].items():
        logger.debug(f"Applying fkr052[{rname}]")
        data = data.replace(rule)

    # Strip end and multiple whitespace.
    data = re.sub("\W{2,}", " ", data.strip())

    data = data.replace("^", " GLOTTAL ")

    data_ls = []
    for word in data.split(" "):
        data_ls.append(_kor_rom(word))
    data = " ".join(data_ls)

    # FKR059
    data = f" {data.lstrip()} ".replace({" GLOTTAL ": "", "*": "", "^": ""})

    # FKR060
    # TODO Add leading whitespace as per L1221? L1202 already added one.
    data = data.replace(KCONF["fkr060"])

    data = re.sub("\W{2,}", " ", f" {data.strip()} ")

    #FKR061 FKR063 FKR064 FKR065
    logger.debug("Applying FKR062-065")
    data = data.replace(KCONF["fkr061"]).replace(KCONF["fkr063"]).replace(
            KCONF["fkr064"]).replace(KCONF["fkr065"])

    # FKR066
    for rname, rule in KCONF["fkr066"].items():
        logger.debug(f"Applying FKR066[{rname}]")
        data = data.replace(rule)

    data = re.sub("\W{2,}", " ", data.strip())

    return data


def kor_rom(data):
    # FKR069
    data = data.replace(KCONF["fkr069"])

    # FKR070
    niun = data.find("+")
    if niun:
        data = data.replace("+", "")
        orig = data

    non_kor = 0
    CP_MIN = 44032
    cpoints = tuple(ord(c) for c in data)
    for cp in cpoints:
        if cp < CP_MIN:
            data = data[1:] # TODO Really?

    rom_ls = []
    # TODO verify cap to 9
    for i in range(min(9,len(data))):
        cp = cpoints[i] - CP_MIN
        ini = "i" + str(cp // 588)
        med = "m" + str((cp // 28) % 21)
        fin = "f" + str(cp % 28)
        rom_ls.append("#".join((ini, med, fin)))
    rom = "~".join(rom_ls) + "E"

    # FKR071
    if niun:
        niun_loc = rom.find("~")
        rom_niun_a = rom[:niun_loc - 1]
        rom_niun_b = rom[niun_loc:]

        if "i11#m2" in rom_niun_b:
            rom_niun_b = rom_niun_b.replace("i11#m2", "i2#m2")

    return data
