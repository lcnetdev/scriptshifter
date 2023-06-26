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


CP_MIN = 44032

logger = logging.getLogger(__name__)


def s2r_nonames_post_config(ctx):
    """ Romanize a regular string NOT containing personal names. """
    ctx.dest, ctx.warnings = _romanize_nonames(ctx.src)

    return BREAK


def s2r_names_post_config(ctx):
    """
    Romanize a string containing ONLY Korean personal names.

    One or more names can be transcribed. A comma or middle dot (U+00B7) is
    to be used as separator for multiple names.
    """
    ctx.dest, ctx.warnings = _romanize_names(ctx.src)

    return BREAK


def _romanize_nonames(src, hancha=False):
    # FKR038
    if hancha:
        src = _hancha2hangul(_marc8_hancha(src))

    data = f" {src} "

    # FKR039, FKR040, FKR041
    for fkrcode in ("fkr039", "fkr040", "fkr041"):
        logger.debug(f"Applying {fkrcode}")
        data = _replace_map(data, KCONF[fkrcode])

    # NOTE This is slightly different from LL 929-930 in that it doesn't
    # result in double spaces.
    data = data.replace("\r\n", " ").replace("\r", " ").replace("\n", " ")
    # This is more compact but I'm unsure if the replacement order is kept.
    # data = data.replace({"\r\n": " ", "\r": " ", "\n": " "})

    data = _romanize_oclc_auto(data)

    # FKR042
    if capitalize = "all":
        data = data.title()
    # FKR043
    elif capitalize = "first":
        data = data.capitalize()

    # FKR044
    ambi = re.sub("[,.\";: ]+", " ", data)

    # TODO See https://github.com/lcnetdev/scriptshifter/issues/20
    no_oclc_breve = False

    if no_oclc_breve:
        data = _replace_map(data, {"ŏ": "ŏ", "ŭ": "ŭ", "Ŏ": "Ŏ", "Ŭ": "Ŭ"})

    # TODO Decide what to do with these. There is no facility for outputting
    # warnings or notes to the user yet.
    warnings = []
    for exp, warn in KCONF["fkr045"].items():
        if exp in ambi:
            warnings.append(ambi if warn == "" else warn)


    return data, warnings


def _romanize_names(src):
    return "Nothing Here Yet."


def _romanize_oclc_auto(data):
    # FKR050
    for rname, rule in KCONF["fkr050"].items():
        logger.debug(f"Applying fkr050[{rname}]")
        data = _replace_map(data, rule)

    # NOTE: Is this memant to replace " 제" followed by a digit with " 제 "?
    # This may not yield the expected results as it could replace all
    # occurrences of " 제" as long as there is a match somewhere in the text.
    if re.match(" 제[0-9]", data):
        data = data.replace(" 제", " 제 ")
    # NOTE: Maybe this was meant:
    # data = re.sub(" 제([0-9])", "제 \\1", data):

    # FKR052
    for rname, rule in KCONF["fkr052"].items():
        logger.debug(f"Applying fkr052[{rname}]")
        data = _replace_map(data, rule)

    # Strip end and multiple whitespace.
    data = re.sub("\\W{2,}", " ", data.strip())

    data = data.replace("^", " GLOTTAL ")

    data_ls = []
    for word in data.split(" "):
        data_ls.append(_kor_rom(word))
    data = " ".join(data_ls)

    # FKR059
    data = f" {data.lstrip()} ".replace({" GLOTTAL ": "", "*": "", "^": ""})

    # FKR060
    # TODO Add leading whitespace as per L1221? L1202 already added one.
    data = _replace_map(data, KCONF["fkr060"])

    data = re.sub("\\W{2,}", " ", f" {data.strip()} ")

    # FKR061
    # FKR063
    # FKR064
    # FKR065
    logger.debug("Applying FKR062-065")
    data = _replace_map(
            data,
            KCONF["fkr061"] + KCONF["fkr063"] +
            KCONF["fkr064"] + KCONF["fkr065"])

    # FKR066
    for rname, rule in KCONF["fkr066"].items():
        logger.debug(f"Applying FKR066[{rname}]")
        data = _replace_map(data, rule)

    data = re.sub("\\W{2,}", " ", data.strip())

    return data


def _kor_rom(data):
    data = re.sub("\\W{2,}", " ", data.strip())

    # FKR069
    data = _replace_map(data, KCONF["fkr069"])

    # FKR070
    niun = data.find("+")
    if niun:
        data = data.replace("+", "")
        orig = data

    non_kor = 0
    cpoints = tuple(ord(c) for c in data)
    for cp in cpoints:
        if cp < CP_MIN:
            non_kor += 1
            data = data[1:]

    rom_ls = []
    for i in range(len(data)):
        cp = cpoints[i] - CP_MIN
        ini = "i" + str(cp // 588)
        med = "m" + str((cp // 28) % 21)
        fin = "f" + str(cp % 28)
        rom_ls.append("#".join((ini, med, fin)))
    rom = "~".join(rom_ls) + "E"

    # FKR071
    if niun:
        rom_niun_a, rom_niun_b = rom[:niun - 1].split("~", 1)
        if re.match("ill#m(?:2|6|12|17|20)", rom_niun_b):
            logger.debug("Applying FKR071")
            rom_niun_b = rom_niun_b.replace("i11#m", "i2#m", 1)

        # FKR072
        if rom_niun_b.startswith("i5#") and rom_niun_a.endswith("f4"):
            logger.debug("Applying FKR072")
            rom_niun_b = rom_niun_b.replace("i5#", "i2", 1)

        rom = f"{rom_niun_a}~{rom_niun_b}"

    # FKR073-100
    fkr_i = 73
    for k, cmap in KCONF["fkr073-100"].items():
        if k in rom:
            logger.debug(f"Applying FKR{fkr_i:03}")
            _replace_map(rom, cmap)
        fkr_i += 1

    # FKR101-108
    for fkr_i in range(101, 109):
        logger.debug(f"Applying FKR{fkr_i:03}")
        rom = _replace_map(rom, KCONF[f"fkr{fkr_i:03}"])

    # FKR109
    for pos, data in KCONF["fkr109"]
        logger.debug(f"Applying FKR109[{pos}]")
        rom = _replace_map(rom, data)

    # FKR110
    rom = _replace_map(rom, {"#": "", "~": ""})

    if non_kor > 0:
        rom = f"{orig[:non_kor]}-{rom}"

    # FKR111
    rom = _replace_map(rom, KCONF["fkr111"])

    # FKR112
    is_non_kor = False
    # FKR113
    # FKR114
    # FKR115
    if orig.strip().startswith(tuple(KCONF["fkr113-115"])):
        is_non_kor = True

    # FKR116
    is_particle = False
    if orig.strip().startswith(tuple(KCONF["fkr116"])):
        is_particle = True

    if len(orig) > 1 and not is_non_kor and not is_particle:
        rom = _replace_map(rom, KCONF["fkr116a"])

    # FKR117
    if (
            # FKR118
            orig in KCONF["fkr118"] or
            # FKR119
            orig in KCONF["fkr119"] or
            orig.endswith(tuple(KCONF["fkr119_suffix"])):
            # FKR120
            orig.endswith(tuple(KCONF["fkr120"])):
        rom = rom.capitalize()

    # FKR121
    # TODO Check global $ConvertR2L assigned in L17 and tested in L1849.
    if f" {orig} " in KCONF["fkr121"]:
        if rom.startswith("r"):
            rom = "l" + rom[1:]
        elif rom.startswith("R"):
            rom = "L" + rom[1:]

    return rom


def _marc8_hancha(data):
    # FKR142
    logger.debug("Applying FKR142")
    return _replace_map(data, KCONF["fkr142"])


def _hancha2hangul(data):
    data = " " + data.replace("\n", "\n ")

    # FKR143-170
    for i in range(143, 171):
        logger.debug(f"Applying FKR{i}")
        data = _replace_map(data, KCONF[f"fkr{i}"])

    # FKR171
    # Write down indices of occurrences of "不"
    idx = [i for i, item in enumerate(data) if item == "不"]
    for i in idx:
        val = ord(data[i + 1])
        if (val > 45795 and val < 46384) or (val > 51087 and val < 51676):
            data = data.replace("不", "부", 1)
        else:
            data = data.replace("不", "불", 1)
    # FKR172-179
    for char in KCONF["fkr172-179"]:
        idx = [i for i, item in enumerate(data) if item == char]
        for i in idx:
            val = ord(data[i + 1])
            coda_value = (val - CP_MIN) % 28
            if coda_value == 1 or coda_value == 4 or val < 100:  # TODO verify
                data = data.replace(char, "열", 1)
            else:
                data = data.replace(char, "렬", 1)

    # FKR180
    logger.debug("Applying FKR180")
    data = _replace_map(data, KCONF["fkr180"])

    return re.sub("\\W{2,}", " ", data.strip())


def _replace_map(src, rmap):
    """ Replace occurrences in a string according to a map. """
    for k, v in rmap:
        src = src.replace(k, v)

    return src
