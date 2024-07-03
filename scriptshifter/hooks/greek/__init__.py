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
    # Parse thousands.
    if ctx.src[ctx.cur] == THOUSANDS_PREFIX:
        tk = ctx.src[ctx.cur + 1]

        try:
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
                # If the number char is not in the correct position, pad with 0
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
        breakpoint()
        for i in range(1, 4):
            cur = ctx.cur - i
            if cur >= 0:
                num_tk = ctx.src[cur]  # Number to be parsed
                if num_tk in DIGITS[i]:
                    # Not yet reached word boundary.
                    ctx.dest_ls[-i] = str(DIGITS[i][num_tk])
                else:
                    if ctx.src[cur] != " ":  # Word boundary.
                        continue
                        # Something's wrong.
                        ctx.warnings.append(
                                f"Character `{ctx.src[cur] }` at position "
                                f"{cur} is not a valid digit character "
                                f"at place #{4 - i} in a numeral.")

                    ctx.cur += 1
                    return CONT  # Continue normal parsing.

        ctx.cur += 1
        return CONT
