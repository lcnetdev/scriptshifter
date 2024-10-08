__doc__ = """ Greek hooks. """


from logging import getLogger

from scriptshifter.exceptions import CONT


# Indices are positions in the numeric string from the right
DIGITS = {
    # Suffixed by ʹ (U+0374)
    1: {  # Units
        "α": 1,
        "β": 2,
        "γ": 3,
        "δ": 4,
        "ε": 5,
        "ϝ": 6,
        "ϛ": 6,
        "στ": 6,
        "ζ": 7,
        "η": 8,
        "θ": 9,
    },
    2: {  # Tens
        "ι": 1,
        "κ": 2,
        "λ": 3,
        "μ": 4,
        "ν": 5,
        "ξ": 6,
        "ο": 7,
        "π": 8,
        "ϙ": 9,
        "ϟ": 9,
    },
    3: {  # Hundreds
        "ρ": 1,
        "σ": 2,
        "τ": 3,
        "υ": 4,
        "φ": 5,
        "χ": 6,
        "ψ": 7,
        "ω": 8,
        "ϡ": 9,
    },
    # Prefixed by ͵ (U+0375)
    4: {
        "α": 1,
        "β": 2,
        "γ": 3,
        "δ": 4,
        "ε": 5,
        "ϝ": 6,
        "ϛ": 6,
        "στ": 6,
        "ζ": 7,
        "η": 8,
        "θ": 9,
    },
}

NUM_SUFFIX = "\u0374"  # ʹ
THOUSANDS_PREFIX = "\u0375"  # ͵

logger = getLogger(__name__)


def parse_numeral(ctx):
    """
    Parse a numeric string.

    Runs on begin_input_token hook.

    Note that this logic does not raise a warning or error for numeral
    characters mixed with letter characters without a space. Therefore,
    "͵ακακαα" would transliterate "1021kaa", and "͵αακαα", "1001kaa".
    """
    # Parse ≥1000.
    if ctx.src[ctx.cur] == THOUSANDS_PREFIX:
        tk = ctx.src[ctx.cur + 1]

        try:
            # Exception for 2-letter digit.
            if ctx.src[ctx.cur + 1: ctx.cur + 3] == "στ":
                ctx.dest_ls.append(str(DIGITS[4]["στ"]))
                ctx.cur += 1
            else:
                ctx.dest_ls.append(str(DIGITS[4][tk]))
            ctx.cur += 2

        except KeyError:
            ctx.warnings.append(
                    f"Character `{tk}` at position {ctx.cur + 1} "
                    "is not a valid thousands character.")
            ctx.cur += 1

            return CONT

        ext = ["0", "0", "0"]
        ext_cur = 0
        for i in range(0, 3):
            # Parse following characters until EOW or max 3.
            if ctx.cur >= len(ctx.src) or ctx.src[ctx.cur] == " ":
                break

            try:
                ext[ext_cur] = str(DIGITS[3 - i][ctx.src[ctx.cur]])
                ctx.cur += 1
            except KeyError:
                # Exception for 2-letter digit.
                if i == 2 and ctx.src[ctx.cur: ctx.cur + 2] == "στ":
                    ext[ext_cur] = "6"
                    ctx.cur += 2
                else:
                    # If the char is not in the correct position, pad with 0.
                    continue
            finally:
                ext_cur += 1
        ctx.dest_ls.extend(ext)

        logger.debug(f"Stopping numeral parsing at position #{ctx.cur}.")

        return CONT

    # Parse 1÷999.
    # This requires a different approach, i.e. backtracking previously
    # transliterated characters.
    if ctx.src[ctx.cur] == NUM_SUFFIX:
        # Move back up to 3 positions.
        offset = 0  # Added offset if στ is found.
        parsed = 0  # Parsed numeral to replace the alpha characters.
        breakout = False  # Break out of i loop.

        i = 1  # Current position in the numeral. 1 = units, 2 = tens, etc.
        mark_pos = ctx.cur  # Mark this position to resume parsing later.
        while i < 4:
            if breakout:
                break
            cur = ctx.cur - i - offset
            if cur >= 0:
                num_tk = ctx.src[cur]  # Number to be parsed
                # Exception for στ. Scan one character farther left.
                if ctx.src[cur - 1:cur + 1] == "στ":
                    num_tk = "στ"
                    offset = 1
                for j in range(i, 4):
                    i = j
                    if num_tk in DIGITS[j]:
                        # Not yet reached word boundary.
                        parsed += DIGITS[j][num_tk] * 10 ** (j - 1)
                        break

                    if num_tk == " " or cur == 0:  # Word boundary.
                        breakout = True
                        break

                    # If we got here we tried all positions without finding a
                    # match. Something's wrong.
                    if j == 3:
                        #     continue
                        ctx.warnings.append(
                                f"Character `{num_tk}` at position "
                                f"{cur} is not a valid digit character "
                                f"at place #{4 - i} in a numeral.")

                    # ctx.cur += 1 + offset
                    # return CONT  # Continue normal parsing.
            i += 1

        if parsed > 0:
            ctx.dest_ls = (
                    ctx.dest_ls[:mark_pos - len(str(parsed)) - offset]
                    + [str(parsed)])

        ctx.cur = mark_pos + 1  # Skip past numeral suffix.

        return CONT
