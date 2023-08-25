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

from os import path
from csv import reader

from scriptshifter.exceptions import BREAK
from scriptshifter.hooks.korean import KCONF


PWD = path.dirname(path.realpath(__file__))
CP_MIN = 44032

# Buid FKR index for better logging.
with open(path.join(PWD, "FKR_index.csv"), newline='') as fh:
    csv = reader(fh)
    FKR_IDX = {row[0]: row[2] for row in csv}


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


def _romanize_nonames(src, capitalize="first", hancha=True):
    """ Main Romanization function for non-name strings. """

    # FKR038: Convert Chinese characters to Hangul
    if hancha:
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

    # FKR042: Capitalize all first letters
    if capitalize == "all":
        rom = rom.title()
    # FKR043: Capitalize the first letter
    elif capitalize == "first":
        rom = rom[0].upper() + rom[1:]

    # FKR044: Ambiguities
    ambi = re.sub("[,.\";: ]+", " ", rom)

    # @TODO Move this to a generic normalization step (not only for K)
    rom = _replace_map(rom, {"ŏ": "ŏ", "ŭ": "ŭ", "Ŏ": "Ŏ", "Ŭ": "Ŭ"})

    # TODO Decide what to do with these. There is no facility for outputting
    # warnings or notes to the user yet.
    warnings = []
    _fkr_log(45)
    for exp, warn in KCONF["fkr045"].items():
        if exp in ambi:
            warnings.append(ambi if warn == "" else warn)

    if rom:
        rom = rom.replace("kkk", "kk")

    return rom, warnings


def _romanize_names(src):
    """
    Main Romanization function for names.

    K-Romanizer: KorNameRom20
    """

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
        return None, warnings

    # `parsed` can either be a modified Korean string with markers, or in case
    # of a foreign name, the final romanized name.
    parsed, _warnings = _parse_kor_name(re.sub(r"\s{2,}", " ", src.strip()))

    if len(_warnings):
        warnings += _warnings

    if parsed:
        if "~" in parsed:
            lname, fname = parsed.split("~", 1)
            fname_rom = _kor_fname_rom(fname)

            lname_rom_ls = [_kor_lname_rom(n) for n in lname.split("+")]

            if not any(lname_rom_ls):
                warnings.append(f"{parsed} is not a recognized Korean name.")
                return None, warnings

            lname_rom = " ".join(lname_rom_ls)

            rom = f"{lname_rom} {fname_rom}"

            if False:
                # TODO add option for authoritative name.
                rom_ls = rom.rsplit(" ", 1)
                rom = ", ".join(rom_ls)

            rom = rom.replace("kkk", "kk")

            return rom, warnings

        else:
            warnings.append("Romanized as a foreign name.")
            return parsed, warnings

    warnings.append(f"{src} is not a recognized Korean name.")
    return None, warnings


def _parse_kor_name(src):
    parsed = None
    warnings = []

    # FKR004: Check first two characters. Two-syllable family name or not?
    two_syl_fname = False
    for ptn in KCONF["fkr004"]:
        if src.startswith(ptn):
            two_syl_fname = True
            break

    # FKR005: Error if more than 7 syllables
    if len(src) > 7 or len(src) < 2 or " " in src[3:]:
        return _kor_corp_name_rom(src), warnings

    ct_spaces = src.count(" ")
    # FKR0006: Error if more than 2 spaces
    if ct_spaces > 2:
        warnings.append("ERROR: not a name (too many spaces)")
        return parsed, warnings

    # FKR007: 2 spaces (two family names)
    if ct_spaces == 2:
        parsed = src.replace(" ", "+", 1).replace(" ", "~", 1)
    elif ct_spaces == 1:
        # FKR008: 1 space (2nd position)
        if src[1] == " ":
            parsed = src.replace(" ", "~")

        # FKR009: 1 space (3nd position)
        if src[2] == " ":
            if two_syl_fname:
                parsed = "+" + src.replace(" ", "~")

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

    rom_tok = []
    for tok in src.split(" "):
        rom_tok.append(_romanize_oclc_auto(tok))
    rom = " ".join(rom_tok).title()

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
    # FKR050: Starts preprocessing symbol
    _fkr_log(50)
    for rname, rule in KCONF["fkr050"].items():
        logger.debug(f"Applying fkr050[{rname}]")
        kor = _replace_map(kor, rule)

    # See https://github.com/lcnetdev/scriptshifter/issues/19
    kor = re.sub("제([0-9])", "제 \\1", kor)

    # FKR052: Replace Che+number
    _fkr_log(52)
    for rname, rule in KCONF["fkr052"].items():
        logger.debug(f"Applying fkr052[{rname}]")
        kor = _replace_map(kor, rule)

    # Strip end and multiple whitespace.
    kor = re.sub(r"\s{2,}", " ", kor.strip())

    kor = kor.replace("^", " GLOTTAL ")

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
    # FKR063: Jurisdiction (국,도,군,구)
    # FKR064: Temple names of Kings, Queens, etc. (except 조/종)
    # FKR065: Frequent historical names
    for i in (61, 63, 64, 65):
        _fkr_log(i)
        rom = _replace_map(rom, KCONF[f"fkr{i:03}"])

    # FKR066: Starts restore symbols
    _fkr_log(66)
    for rname, rule in KCONF["fkr066"].items():
        logger.debug(f"Applying FKR066[{rname}]")
        rom = _replace_map(rom, rule)

    # Remove spaces from before punctuation signs.
    rom = re.sub(r" (?=[,.;:?!])", "", rom.strip())
    rom = re.sub(r"\s{2,}", " ", rom)

    return rom


# FKR068: Exceptions, Exceptions to initial sound law, Proper names
def _kor_rom(kor):
    kor = re.sub(r"\s{2,}", " ", kor.strip())
    orig = kor

    # FKR069: Irregular sound change list
    kor = _replace_map(kor, KCONF["fkr069"])

    # FKR070: [n] insertion position mark +
    niun = kor.find("+")
    if niun > -1:
        kor = kor.replace("+", "")
        orig = kor

    non_kor = 0
    cpoints = tuple(ord(c) for c in kor)
    for cp in cpoints:
        if cp < CP_MIN:
            non_kor += 1
            kor = kor[1:]

    rom_ls = []
    if non_kor > 0:
        # Rebuild code point list with non_kor removed.
        cpoints = tuple(ord(c) for c in kor)
    for i in range(len(kor)):
        cp = cpoints[i] - CP_MIN
        ini = "i" + str(cp // 588)
        med = "m" + str((cp // 28) % 21)
        fin = "f" + str(cp % 28)
        rom_ls.append("#".join((ini, med, fin)))
    rom = "~".join(rom_ls)
    if len(rom):
        rom = rom + "E"

    # FKR071: [n] insertion
    if niun > -1:
        niun_loc = rom.find("~")
        # Advance until the niun'th occurrence of ~
        # If niun is 0 or 1 the loop will be skipped.
        for i in range(niun - 1):
            niun_loc = rom.find("~", niun_loc + 1)
        rom_niun_a = rom[:niun_loc]
        rom_niun_b = rom[niun_loc + 1:]
        if re.match("ill#m(?:2|6|12|17|20)", rom_niun_b):
            _fkr_log(71)
            rom_niun_b = rom_niun_b.replace("i11#m", "i2#m", 1)

        # FKR072: [n]+[l] >[l] + [l]
        if rom_niun_b.startswith("i5#") and rom_niun_a.endswith("f4"):
            _fkr_log(72)
            rom_niun_b = rom_niun_b.replace("i5#", "i2", 1)

        rom = f"{rom_niun_a}~{rom_niun_b}"

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
    fkr_i = 73
    for k, cmap in KCONF["fkr073-100"].items():
        if k in rom:
            _fkr_log(fkr_i)
            rom = _replace_map(rom, cmap)
        fkr_i += 1

    # FKR101: digraphic coda + ㅇ: ㄵ,ㄶ,ㄺ,ㄻ,ㄼ,ㄽ,ㄾ,ㄿ,ㅀ
    # FKR102: digraphic coda + ㅎ: ㄵ,ㄶ,ㄺ,ㄻ,ㄼ,(ㄽ),ㄾ,ㄿ,ㅀ
    # FKR103: Vocalization 1 (except ㄹ+ㄷ, ㄹ+ㅈ 제외) voiced + unvoiced
    # FKR104: Vocalization 2 (except ㄹ+ㄷ, ㄹ+ㅈ 제외) unvoiced + voiced
    # FKR105: Vocalization 3 (ㄹ+ㄷ, ㄹ+ㅈ)
    # FKR106: Final sound law
    # FKR107: Exception for '쉬' = shi
    # FKR108: Exception for 'ㄴㄱ'= n'g
    for fkr_i in range(101, 109):
        _fkr_log(fkr_i)
        _bk = rom
        rom = _replace_map(rom, KCONF[f"fkr{fkr_i:03}"])
        if _bk != rom:
            logger.debug(f"FKR{fkr_i} substitution: {rom} (was: {_bk})")

    # FKR109: Convert everything else
    _fkr_log(109)
    for pos, data in KCONF["fkr109"].items():
        rom = _replace_map(rom, data)

    # FKR110: Convert symbols
    rom = _replace_map(rom, {"#": "", "~": ""})

    if non_kor > 0:
        # Modified from K-Romanizer:1727 in that it does not append a hyphen
        # if the whole word is non-Korean.
        rom = f"{orig[:non_kor]}-{rom}" if len(rom) else orig

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
            orig.endswith(tuple(KCONF["fkr120"]))):
        rom = rom[0].upper() + rom[1:]

    # FKR121: Loan words beginning with L
    if f" {orig} " in KCONF["fkr121"]:
        rom = _replace_map(rom[0], {"R": "L", "r": "l"}) + rom[1:]

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
    # FKR176: Chinese characters 律(률)의 발음 처리
    # FKR177: Chinese characters 率(률)의 발음 처리
    # FKR178: Chinese characters 慄(률)의 발음 처리
    # FKR179: Chinese characters 栗(률)의 발음 처리
    for char in KCONF["fkr172-179"]:
        idx = [i for i, item in enumerate(data) if item == char]
        for i in idx:
            val = ord(data[i + 1])
            coda_value = (val - CP_MIN) % 28
            if coda_value == 1 or coda_value == 4 or val < 100:  # TODO verify
                data = data.replace(char, "열", 1)
            else:
                data = data.replace(char, "렬", 1)

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
        ini = "i" + str(cp // 588)
        med = "m" + str((cp // 28) % 21)
        fin = "f" + str(cp % 28)
        rom_ls.append("#".join((ini, med, fin)))
    rom = "~".join(rom_ls) + "E"

    # FKR011: Check native Korean name, by coda
    origin_by_fin = "sino"
    for tok in KCONF["fkr011"]["nat_fin"]:
        if tok in rom:
            origin_by_fin = "native"
            break

    j = False
    for tok in KCONF["fkr011"]["nat_ini"]:
        if tok in rom:
            j = True

    k = False
    for tok in KCONF["fkr011"]["sino_ini"]:
        if tok in rom:
            k = True

    if j:
        if k:
            origin_by_ini = "sino"
        else:
            origin_by_ini = "native"
    else:
        origin_by_ini = "sino"

    # FKR012: Check native Korean name, by vowel & coda
    origin_by_med = "sino"
    for tok in KCONF["fkr011"]:
        if tok in rom:
            origin_by_med = "native"
            break

    # FKR013: Check native Korean name, by ㅢ
    if "m19#" in rom:
        if "의" in fname or "희" in fname:
            origin_by_med = "sino"
        else:
            origin_by_med = "native"

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

    rom = _replace_map(rom.replace("#", ""), {"swi": "shwi", "Swi": "Shwi"}, 1)

    if len(fname) == 2:
        rom = rom.replace("~", "-")
    else:
        rom = _replace_map(rom, {"n~g": "n'g", "~": ""})

    # FKR031: ㄹ + vowels/ㅎ/ㄹ ["l-r","l-l"] does not work USE alternative
    _fkr_log(31)
    for k, cmap in KCONF["fkr031"].items():
        logger.debug(f"Applying FKR031[\"{k}\"]")
        rom = _replace_map(rom, cmap)

    # FKR032: Capitalization
    rom = rom[0].upper() + rom[1:]

    # FKR033: Remove hyphen in bisyllabic native Korean first name
    if (
            len(fname) == 2
            and "native" in (origin_by_ini, origin_by_fin, origin_by_med)):
        rom = _replace_map(rom, {"n-g": "n'g", "-": ""})

    # FKR034: First name, initial sound law
        for k, v in KCONF["fkr034"].items():
            if rom.startswith(k):
                rom = rom.replace(k, v)

    return rom


def _kor_lname_rom(lname):
    if len(lname) == 2:
        # FKR181: 2-charater names.
        _fkr_log(181)
        rom = _replace_map(lname, KCONF["fkr181"])
    else:
        # FKR182: 1-charater Chinese names.
        _fkr_log(182)
        lname = _replace_map(lname, KCONF["fkr182"])
        # FKR183: 1-charater names.
        _fkr_log(183)
        rom = _replace_map(lname, KCONF["fkr183"])

    return rom if lname != rom else False


def _fkr_log(fkr_i):
    fkr_k = f"FKR{fkr_i:03}"
    logger.debug(f"Applying {fkr_k}: {FKR_IDX[fkr_k]}")
