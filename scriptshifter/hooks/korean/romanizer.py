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

from csv import reader
from os import path

from scriptshifter.exceptions import BREAK
from scriptshifter.hooks.korean import KCONF
from scriptshifter.hooks.general import capitalize_post_assembly


PWD = path.dirname(path.realpath(__file__))
CP_MIN = 44032
ALL_PUNCT_STR = r'[!"#$%&\'()*+,-.:;<=>?・ǂ「」『』@[\\]^_`{|}~‡‰‘’“”–—˜©·]'


# Separator symbols for coded tokens.
# Using esoteric characters most unlikely found in cataloging records.
INI = "🜁"  # Initial prefix (was: i).
MED = "🜊"  # Medial prefix (was: m).
FIN = "🜔"  # Final prefix (was: f).
EOP = "🜿"  # End of part (was: #).
EOT = "🝎"  # End of token (was: ~).
EON = "🜹"  # First-last name separator (was: +).
EOD = "🝥"  # End of document (was: E).
GLT = "🜄"  # Glottal (was: ^).


# Buid FKR index for better logging.
with open(path.join(PWD, "FKR_index.csv"), newline='') as fh:
    csv = reader(fh)
    FKR_IDX = {row[0]: row[2] for row in csv}


logger = logging.getLogger(__name__)


def s2r_nonames_post_config(ctx):
    """ Romanize a regular string NOT containing personal names. """
    ctx.dest, ctx.warnings = _romanize_nonames(
            ctx.src, ctx.options)

    if ctx.dest:
        # FKR042: Capitalize all first letters
        # FKR043: Capitalize the first letter
        logger.debug(f"Before capitalization: {ctx.dest}")
        ctx.dest = capitalize_post_assembly(ctx)

    return BREAK


def s2r_names_post_config(ctx):
    """
    Romanize a string containing ONLY Korean personal names.

    One or more names can be transcribed. A comma or middle dot (U+00B7) is
    to be used as separator for multiple names.
    """
    ctx.dest, ctx.warnings = _romanize_names(ctx.src, ctx.options)

    if ctx.dest:
        # FKR042: Capitalize all first letters
        # FKR043: Capitalize the first letter
        logger.debug(f"Before capitalization: {ctx.dest}")
        ctx.dest = capitalize_post_assembly(ctx)

    return BREAK


def _romanize_nonames(src, options):
    """ Main Romanization function for non-name strings. """

    # FKR038: Convert Chinese characters to Hangul
    if options.get("hancha", True):
        kor = _hancha2hangul(_marc8_hancha(src))
    else:
        kor = src

    # Replace ideographic spaces with ASCII space.
    kor = re.sub(r"\s+", " ", kor)
    kor = f" {kor} "

    # FKR039: Replace Proper name with spaces in advance
    # FKR040: Replace Proper name with a hyphen in advance
    # FKR041: Romanize names of Hangul consonants
    for i in range(39, 42):
        _fkr_log(i)
        kor = _replace_map(kor, KCONF[f"fkr{i:03}"])

    # NOTE This is slightly different from LL 929-930 in that it doesn't
    # result in double spaces.
    kor = kor.replace("\r\n", " ").replace("\r", " ").replace("\n", " ")
    # This is more compact but I'm unsure if the replacement order is kept.
    # kor = kor.replace({"\r\n": " ", "\r": " ", "\n": " "})

    rom = _romanize_oclc_auto(kor)

    # FKR044: Ambiguities
    ambi = re.sub("[,.\";: ]+", " ", rom)

    warnings = []
    _fkr_log(45)
    for exp, warn in KCONF["fkr045"].items():
        if exp in ambi:
            warnings.append(ambi if warn == "" else warn)

    if rom:
        rom = rom.replace("kkk", "kk")

    return rom, warnings


def _romanize_names(src, options):
    """
    Main Romanization function for names.

    Separate and romanize multiple names sepearated by comma or middle dot.

    K-Romanizer: KorNameRom20
    """
    rom_ls = []
    warnings = []

    if "," in src and "·" in src:
        warnings.append(
                "both commas and middle dots are being used to separate "
                "names. Only one of the two types should be used, or "
                "unexpected results may occur.")

    kor_ls = src.split(",") if "," in src else src.split("·")

    for kor in kor_ls:
        rom, _warnings = _romanize_name(kor.strip(), options)
        rom_ls.append(rom)

        warnings.extend(_warnings)

    return ", ".join(rom_ls), warnings


def _romanize_name(src, options):
    warnings = []

    # FKR001: Conversion, Family names in Chinese (dealing with 金 and 李)
    # FKR002: Family names, Initial sound law
    replaced = False
    for ss, r in KCONF["fkr001-002"]:
        if replaced:
            break
        for s in ss:
            if src.startswith(s):
                src = r + src[1:]
                replaced = True
                break

    # FKR003: First name, Chinese Character Conversion
    src = _hancha2hangul(_marc8_hancha(src))

    if re.search("[a-zA-Z0-9]", src):
        warnings.append(f"{src} is not a recognized personal name.")
        return "", warnings

    # `parsed` can either be a modified Korean string with markers, or in case
    # of a foreign name, the final romanized name.
    parsed, _warnings = _parse_kor_name(
            re.sub(r"\s{2,}", " ", src.strip()),
            options)
    logger.debug(f"Parsed Korean name: {parsed}")

    if len(_warnings):
        warnings += _warnings

    if parsed:
        if EOT in parsed:
            lname, fname = parsed.split(EOT, 1)
            logger.debug(f"First name: {fname}; Last name: {lname}")
            fname_rom = _kor_fname_rom(fname)

            lname_rom_ls = []
            for n in lname.split(EON):
                _k = _kor_lname_rom(n)
                logger.debug(f"Split last name part: {n}")
                logger.debug(f"Split last name part romanized: {_k}")
                if _k:
                    lname_rom_ls.append(_k)

            if not any(lname_rom_ls):
                warnings.append(f"{parsed} is not a recognized Korean name.")
                return "", warnings

            lname_rom = " ".join(lname_rom_ls)

            # Add comma after the last name for certain MARC fields.
            marc_field = options.get("marc_field")
            if marc_field in ("100", "600", "700", "800"):
                rom = f"{lname_rom}, {fname_rom}"
            else:
                rom = f"{lname_rom} {fname_rom}"

            if False:
                # TODO add option for authoritative name.
                rom_ls = rom.rsplit(" ", 1)
                rom = ", ".join(rom_ls)

            return rom, warnings

        else:
            warnings.append("Romanized as a foreign name.")
            return parsed, warnings

    warnings.append(f"{src} is not a recognized Korean name.")
    return "", warnings


def _parse_kor_name(src, options):
    parsed = None
    warnings = []

    # FKR004: Check first two characters. Two-syllable family name or not?
    two_syl_lname = False
    for ptn in KCONF["fkr004"]:
        if src.startswith(ptn):
            two_syl_lname = True
            logger.debug("Name has a 2-syllable last name.")
            break

    src_len = len(src)

    # FKR005: Error if more than 7 syllables
    if src_len > 7 or src_len < 2 or src.find(" ") > 2:
        if options.get("foreign_name"):
            return _kor_corp_name_rom(src), warnings
        else:
            warnings.append("ERROR: not a Korean name.")
            return None, warnings

    ct_spaces = src.count(" ")
    # FKR0006: Error if more than 2 spaces
    if ct_spaces > 2:
        warnings.append("ERROR: not a name (too many spaces)")
        return None, warnings

    # FKR007: 2 spaces (two family names)
    if ct_spaces == 2:
        logger.debug(f"Name {src} has 2 spaces.")
        parsed = src.replace(" ", EON, 1).replace(" ", EOT, 1)
    elif ct_spaces == 1:
        # FKR008: 1 space (2nd position)
        if src[1] == " ":
            logger.debug(f"Name {src} has 1 space in the 2nd position.")
            parsed = src.replace(" ", EOT)

        # FKR009: 1 space (3nd position)
        if src[2] == " ":
            logger.debug(f"Name {src} has 1 space in the 3rd position.")
            if two_syl_lname:
                parsed = EON + src.replace(" ", EOT)

    # FKR010: When there is no space
    else:
        logger.debug(f"Name {src} has no spaces.")
        if src_len == 2:
            logger.debug("Name has 2 characters.")
            parsed = src[0] + EOT + src[1:]
        elif src_len > 2:
            logger.debug("Name has more than 2 characters.")
            if two_syl_lname:
                logger.debug("Last name has 2 syllables.")
                parsed = src[:2] + EOT + src[2:]
            else:
                logger.debug("Last name has 1 syllable.")
                parsed = src[0] + EOT + src[1:]
    return parsed, warnings


def _kor_corp_name_rom(src):
    chu = yu = 0
    if src.startswith("(주) "):
        src = src[4:]
        chu = "L"
    if src.endswith(" (주)"):
        src = src[:-4]
        chu = "R"
    if src.startswith("(유) "):
        src = src[4:]
        yu = "L"
    if src.endswith(" (유)"):
        src = src[:-4]
        yu = "R"

    rom_tok = [
        _romanize_oclc_auto(tok)
        for tok in src.split(" ")
    ]
    rom = " ".join(rom_tok)

    if chu == "L":
        rom = "(Chu) " + rom
    elif chu == "R":
        rom = rom + " (Chu)"
    if yu == "L":
        rom = "(Yu) " + rom
    elif yu == "R":
        rom = rom + " (Yu)"

    # FKR035: Replace established names
    rom = _replace_map(rom, KCONF["fkr035"])

    return rom


def _romanize_oclc_auto(kor):

    # See https://github.com/lcnetdev/scriptshifter/issues/19
    kor = re.sub("제([0-9])", "제 \\1", kor)

    # FKR052: Replace Che+number
    _fkr_log(52)
    for rname, rule in KCONF["fkr052"].items():
        logger.debug(f"Applying fkr052[{rname}]")
        kor = _replace_map(kor, rule)

    # Strip end and multiple whitespace.
    kor = re.sub(r"\s{2,}", " ", kor.strip())

    kor = kor.replace(GLT, " GLOTTAL ")

    logger.debug(f"Korean before romanization: {kor}")

    rom_ls = []
    for word in kor.split(" "):
        rom_ls.append(_kor_rom(word))
    rom = " ".join(rom_ls)

    # FKR059: Apply glottalization
    rom = _replace_map(
            f" {rom.strip()} ", {" GLOTTAL ": "", "*": "", "^": ""})

    # FKR060: Process number + -년/-년도/-년대
    # TODO Add leading whitespace as per L1221? L1202 already added one.
    rom = _replace_map(rom, KCONF["fkr060"])

    rom = re.sub(r"\s{2,}", " ", f" {rom.strip()} ")

    # FKR061: Jurisdiction (시)
    # FKR062: Historical place names
    # FKR063: Jurisdiction (국,도,군,구)
    # FKR064: Temple names of Kings, Queens, etc. (except 조/종)
    # FKR065: Frequent historical names
    for i in range(61, 66):
        _fkr_log(i)
        rom = _replace_map(rom, KCONF[f"fkr{i:03}"])

    # Replace Korean punctuation.
    rom = _replace_map(rom, {"・": ", ", "·": ", "})

    # Normalize punctuation spacing.
    rom = re.sub(r"\s{2,}", " ", rom.strip())
    rom = re.sub(r" (?=[,.;:?!\]\)\}’”])", "", rom)
    rom = re.sub(r"(?<=[\[\(\{‘“]) ", "", rom)

    return rom


# FKR068: Exceptions, Exceptions to initial sound law, Proper names
def _kor_rom(kor):
    kor = re.sub(r"\s{2,}", " ", kor.strip())
    orig = kor

    # FKR069: Irregular sound change list
    kor = _replace_map(kor, KCONF["fkr069"])

    # FKR070: [n] insertion position mark +
    niun = kor.find(EON)
    if niun > -1:
        kor = kor.replace(EON, "")
        orig = kor

    non_kor = 0
    cpoints = tuple(ord(c) for c in kor)
    for cp in cpoints:
        if cp < CP_MIN:
            non_kor += 1
            kor = kor[1:]
        else:
            # Break as soon as a Korean code point is found.
            break

    rom_ls = []
    if non_kor > 0:
        # Rebuild code point list with non_kor removed.
        cpoints = tuple(ord(c) for c in kor)
    for i in range(len(kor)):
        cp = cpoints[i] - CP_MIN
        if cp < 0:
            # This accounts for punctuation attached to the end of the word.
            rom_ls.append(kor[i])
            continue
        ini = INI + str(cp // 588)
        med = MED + str((cp // 28) % 21)
        fin = FIN + str(cp % 28)
        rom_ls.append(EOP.join((ini, med, fin)))
    rom = EOT.join(rom_ls)
    if len(rom):
        rom = rom + EOD
    logger.debug(f"Coded romanization before replacements: {rom}")

    # FKR071: [n] insertion
    if niun > -1:
        niun_loc = rom.find(EOT)
        # Advance until the niun'th occurrence of EOT
        # If niun is 0 or 1 the loop will be skipped.
        for i in range(niun - 1):
            niun_loc = rom.find(EOT, niun_loc + 1)
        rom_niun_a = rom[:niun_loc]
        rom_niun_b = rom[niun_loc + 1:]
        if re.match(
                f"{INI}11{EOP}"
                f"{MED}(?:2|6|12|17|20)", rom_niun_b):
            _fkr_log(71)
            rom_niun_b = rom_niun_b.replace(
                    f"{INI}11{EOP}{MED}", f"{INI}2{EOP}{MED}", 1)

        # FKR072: [n]+[l] >[l] + [l]
        if (
                rom_niun_b.startswith(f"{INI}5{EOP}")
                and rom_niun_a.endswith(f"{FIN}4")):
            _fkr_log(72)
            rom_niun_b = rom_niun_b.replace(f"{INI}5{EOP}", f"{INI}2", 1)

        rom = f"{rom_niun_a}{EOT}{rom_niun_b}"

    # FKR073: Palatalization: ㄷ+이,ㄷ+여,ㄷ+히,ㄷ+혀
    # FKR074: Palatalization: ㅌ+이,ㅌ+히,ㅌ+히,ㅌ+혀
    # FKR075: Consonant assimilation ㄱ
    # FKR076: Consonant assimilation ㄲ
    # FKR077: Consonant assimilation ㄳ : ㄱ,ㄴ,ㄹ,ㅁ,ㅇ
    # FKR078: Consonant assimilation ㄴ
    # FKR079: Consonant assimilation ㄵ: ㄱ,ㄴ,ㄷ,ㅈ"
    # FKR080: Consonant assimilation ㄶ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR081: Consonant assimilation ㄷ
    # FKR082: Consonant assimilation ㄹ
    # FKR083: Consonant assimilation ㄺ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR084: Consonant assimilation ㄻ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR085: Consonant assimilation ㄼ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR086: Consonant assimilation ㄾ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR087: Consonant assimilation ㄿ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR088: Consonant assimilation ㅀ : ㄱ,ㄴ,ㄷ,ㅈ
    # FKR089: Consonant assimilation ㅁ
    # FKR090: Consonant assimilation ㅂ
    # FKR091: Consonant assimilation ㅄ
    # FKR092: Consonant assimilation ㅅ
    # FKR093: Consonant assimilation ㅆ
    # FKR094: Consonant assimilation ㅇ
    # FKR095: Consonant assimilation ㅈ
    # FKR096: Consonant assimilation ㅊ
    # FKR097: Consonant assimilation ㅋ
    # FKR098: Consonant assimilation ㅌ
    # FKR099: Consonant assimilation ㅍ
    # FKR100: Consonant assimilation ㅎ
    # FKR101: digraphic coda + ㅇ: ㄵ,ㄶ,ㄺ,ㄻ,ㄼ,ㄽ,ㄾ,ㄿ,ㅀ
    # FKR102: digraphic coda + ㅎ: ㄵ,ㄶ,ㄺ,ㄻ,ㄼ,(ㄽ),ㄾ,ㄿ,ㅀ
    # FKR103: Vocalization 1 (except ㄹ+ㄷ, ㄹ+ㅈ 제외) voiced + unvoiced
    # FKR104: Vocalization 2 (except ㄹ+ㄷ, ㄹ+ㅈ 제외) unvoiced + voiced
    # FKR105: Vocalization 3 (ㄹ+ㄷ, ㄹ+ㅈ)
    # FKR106: Final sound law
    # FKR107: Exception for '쉬' = shi
    # FKR108: Exception for 'ㄴㄱ'= n'g
    for fkr_i in range(73, 109):
        _bk = rom
        rom = _replace_map(rom, KCONF[f"fkr{fkr_i:03}"])
        if _bk != rom:
            _fkr_log(fkr_i)
            logger.debug(f"FKR{fkr_i} substitution: {rom} (was: {_bk})")

    logger.debug(f"Coded romanization after replacements: {rom}")
    # FKR109: Convert everything else
    _fkr_log(109)
    for pos, data in KCONF["fkr109"].items():
        rom = _replace_map(rom, data)

    # FKR110: Convert leftover separator symbols
    rom = _replace_map(rom, {EOP: "", EOT: "", EOD: ""})

    if non_kor > 0:
        logger.debug(f"Non-Korean part: {orig[:non_kor]}")
        # Modified from K-Romanizer:1727 in that it does not append a hyphen
        # if the whole word is non-Korean or if the last non-Korean character
        # is a punctuation symbol.
        if orig[non_kor - 1] in ALL_PUNCT_STR:
            rom = f"{orig[:non_kor]}{rom}"
        elif len(rom):
            rom = f"{orig[:non_kor]}-{rom}"
        else:
            rom = orig

    # FKR111: ㄹ + 모음/ㅎ/ㄹ, ["lr","ll"] must be in the last of the array
    rom = _replace_map(rom, KCONF["fkr111"])

    # FKR112: Exceptions to initial sound law
    is_non_kor = False
    # FKR113: Check loan words by the first 1 letter
    # FKR114: Check loan words by the first 2 letters
    # FKR115: Check loan words by the first 3 letters
    if orig.startswith(tuple(KCONF["fkr113-115"])):
        is_non_kor = True

    # FKR116: Exceptions to initial sound law - particles
    is_particle = False
    if orig.startswith(tuple(KCONF["fkr116"]["particles"])):
        is_particle = True

    if len(orig) > 1 and not is_non_kor and not is_particle:
        if rom.startswith(tuple(KCONF["fkr116"]["replace_initials"].keys())):
            rom = _replace_map(rom, KCONF["fkr116"]["replace_initials"])

    # FKR117: Proper names _StringPoper Does not work because of breves
    if (
            # FKR118
            orig in KCONF["fkr118"] or
            # FKR119
            orig in KCONF["fkr119"]["word"] or
            (
                orig[:-1] in KCONF["fkr119"]["word"] and
                orig.endswith(tuple(KCONF["fkr119"]["suffix"]))
            ) or
            # FKR120
            orig in KCONF["fkr120"]):
        rom = rom[0].upper() + rom[1:]

    # FKR121: Loan words beginning with L
    if f" {orig} " in KCONF["fkr121"]:
        rom = _replace_map(rom[0], {"R": "L", "r": "l"}) + rom[1:]

    # @TODO Move this to a generic normalization step (not only for K)
    rom = _replace_map(rom, {"ŏ": "ŏ", "ŭ": "ŭ", "Ŏ": "Ŏ", "Ŭ": "Ŭ"})
    logger.debug(f"Romanized token: {rom}")

    return rom


def _marc8_hancha(data):
    # FKR142: Chinese character list
    _fkr_log(142)
    return _replace_map(data, KCONF["fkr142"])


def _hancha2hangul(data):
    data = " " + data.replace("\n", "\n ")

    # FKR143: Process exceptions first
    # FKR144: Apply initial sound law (Except: 列, 烈, 裂, 劣)
    # FKR145: Simplified characters, variants
    # FKR146: Some characters from expanded list
    # FKR147: Chinese characters 1-500 車=차
    # FKR148: Chinese characters 501-750 串=관
    # FKR149: Chinese characters 751-1000 金=금, 娘=랑
    # FKR150: Chinese characters 1001-1250
    # FKR151: Chinese characters 1251-1500 제외: 列, 烈, 裂, 劣
    # FKR152: Chinese characters 1501-1750 제외: 律, 率, 栗, 慄
    # FKR153: Chinese characters 1751-2000
    # FKR154: 不,Chinese characters 2001-2250 제외: 不
    # FKR155: Chinese characters 2251-2500 塞=색
    # FKR156: Chinese characters 2501-2750
    # FKR157: Chinese characters 2751-3000
    # FKR158: Chinese characters 3001-2250
    # FKR159: Chinese characters 3251-3500
    # FKR160: Chinese characters 3501-3750
    # FKR161: Chinese characters 3751-4000
    # FKR162: Chinese characters 4001-4250
    # FKR163: Chinese characters 4251-4500
    # FKR164: Chinese characters 4501-4750
    # FKR165: Chinese characters 4751-5000
    # FKR166: Chinese characters 5001-5250
    # FKR167: Chinese characters 5251-5500
    # FKR168: Chinese characters 5501-5750
    # FKR169: Chinese characters 5751-5978
    # FKR170: Chinese characters 일본Chinese characters
    for i in range(143, 171):
        _fkr_log(i)
        data = _replace_map(data, KCONF[f"fkr{i}"])

    # FKR171: Chinese characters 不(부)의 발음 처리
    # Write down indices of occurrences of "不"
    idx = [i for i, item in enumerate(data) if item == "不"]
    for i in idx:
        val = ord(data[i + 1])
        if (val > 45795 and val < 46384) or (val > 51087 and val < 51676):
            data = data.replace("不", "부", 1)
        else:
            data = data.replace("不", "불", 1)
    # FKR172: Chinese characters 列(렬)의 발음 처리
    # FKR173: Chinese characters 烈(렬)의 발음 처리
    # FKR174: Chinese characters 裂(렬)의 발음 처리
    # FKR175: Chinese characters 劣(렬)의 발음 처리
    for char in KCONF["fkr172-175"]:
        idx = [i for i, item in enumerate(data) if item == char]
        for i in idx:
            val = ord(data[i - 1])
            coda_value = (val - CP_MIN) % 28
            if coda_value == 0 or coda_value == 4 or val < 100:
                data = data.replace(char, "열", 1)
            else:
                data = data.replace(char, "렬", 1)

    # FKR176: Chinese characters 律(률)의 발음 처리
    # FKR177: Chinese characters 率(률)의 발음 처리
    # FKR178: Chinese characters 慄(률)의 발음 처리
    # FKR179: Chinese characters 栗(률)의 발음 처리
    for char in KCONF["fkr176-179"]:
        idx = [i for i, item in enumerate(data) if item == char]
        for i in idx:
            val = ord(data[i - 1])
            coda_value = (val - CP_MIN) % 28
            if coda_value == 0 or coda_value == 4 or val < 100:
                data = data.replace(char, "율", 1)
            else:
                data = data.replace(char, "률", 1)

    # FKR180: Katakana
    _fkr_log(180)
    data = _replace_map(data, KCONF["fkr180"])

    return re.sub(r"\s{2,}", " ", data.strip())


def _replace_map(src, rmap, *args, **kw):
    """ Replace occurrences in a string according to a map. """
    for k, v in rmap.items():
        src = src.replace(k, v, *args, **kw)

    return src


def _kor_fname_rom(fname):
    rom_ls = []
    cpoints = tuple(ord(c) for c in fname)
    for i in range(len(fname)):
        cp = cpoints[i] - CP_MIN
        ini = INI + str(cp // 588)
        med = MED + str((cp // 28) % 21)
        fin = FIN + str(cp % 28)
        rom_ls.append(EOP.join((ini, med, fin)))
    rom = EOT.join(rom_ls) + EOD
    logger.debug(f"Encoded first name: {rom}")

    # FKR011: Check native Korean name, by coda
    native_by_fin = False
    for tok in KCONF["fkr011"]["nat_fin"]:
        if tok in rom:
            native_by_fin = True
            break

    j = k = False
    for tok in KCONF["fkr011"]["nat_ini"]:
        if tok in rom:
            j = True
            break
    for tok in KCONF["fkr011"]["sino_ini"]:
        if tok in fname:
            k = True
            break
    native_by_ini = j and not k

    # FKR012: Check native Korean name, by vowel & coda
    native_by_med = False
    for tok in KCONF["fkr011"]:
        if tok in rom:
            native_by_med = True
            break

    # FKR013: Check native Korean name, by ㅢ
    if f"{MED}19{EOP}" in rom:
        native_by_med = "의" not in fname and "희" not in fname

    # FKR014: Consonant assimilation ㄱ
    # FKR015: Consonant assimilation ㄲ
    # FKR016: Consonant assimilation ㄴ
    # FKR017: Consonant assimilation ㄷ
    # FKR018: Consonant assimilation ㄹ
    # FKR019: Consonant assimilation ㅁ
    # FKR020: Consonant assimilation ㅂ
    # FKR021: Consonant assimilation ㅅ
    # FKR022: Consonant assimilation ㅆ
    # FKR023: Consonant assimilation ㅇ
    # FKR024: Consonant assimilation ㅈ
    # FKR025: Consonant assimilation ㅊ
    # FKR026: Consonant assimilation ㅎ
    # FKR027: Final sound law
    # FKR028: Vocalization 1 (except ㄹ+ㄷ, ㄹ+ㅈ): voiced+unvoiced
    # FKR029: Vocalization 2 unvoiced+voiced
    for i in range(14, 30):
        _fkr_log(i)
        rom = _replace_map(rom, KCONF[f"fkr{i:03}"])

    # FKR030: Convert everything else
    _fkr_log(30)
    for k, cmap in KCONF["fkr030"].items():
        logger.debug(f"Applying FKR030[\"{k}\"]")
        rom = _replace_map(rom, cmap)

    rom = _replace_map(rom.replace(EOP, ""), {"swi": "shwi", "Swi": "Shwi"}, 1)

    logger.debug(f"Partly romanized first name: {rom}")
    logger.debug(f"fname: {fname} ({len(fname)})")
    if len(fname) == 2:
        rom = _replace_map(rom, {EOT: "-", EOD: ""})
    else:
        rom = _replace_map(rom, {f"n{EOT}g": "n'g", EOT: "", EOD: ""})

    # FKR031: ㄹ + vowels/ㅎ/ㄹ ["l-r","l-l"] does not work USE alternative
    _fkr_log(31)
    for k, cmap in KCONF["fkr031"].items():
        logger.debug(f"Applying FKR031[\"{k}\"]")
        rom = _replace_map(rom, cmap)

    # FKR032: Capitalization
    _fkr_log(32)
    rom = rom[0].upper() + rom[1:]

    # FKR033: Remove hyphen in bisyllabic native Korean first name
    _fkr_log(33)
    if (
            len(fname) == 2
            and any((native_by_ini, native_by_fin, native_by_med))):
        _fkr_log(33)
        logger.debug("First name is native.")
        rom = _replace_map(rom, {"n-g": "n'g", "-": ""})

    # FKR034: First name, initial sound law
    if len(fname) > 1:
        _fkr_log(34)
        for k, v in KCONF["fkr034"].items():
            if rom.startswith(k):
                rom = rom.replace(k, v)

    return rom


def _kor_lname_rom(lname):
    if len(lname) == 2:
        # FKR181: 2-character names.
        _fkr_log(181)
        rom = _replace_map(lname, KCONF["fkr181"])
    else:
        # FKR182: 1-character Chinese names.
        _fkr_log(182)
        lname = _replace_map(lname, KCONF["fkr182"])
        # FKR183: 1-character names.
        _fkr_log(183)
        rom = _replace_map(lname, KCONF["fkr183"])

    return rom if lname != rom else False


def _fkr_log(fkr_i):
    fkr_k = f"FKR{fkr_i:03}"
    logger.debug(f"Applying {fkr_k}: {FKR_IDX[fkr_k]}")
