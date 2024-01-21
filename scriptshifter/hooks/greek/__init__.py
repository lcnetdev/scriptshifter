__doc__ = """ Greek hooks. """


from scriptshifter.exceptions import CONT


# Suffixed by ʹ
# Indices are positions in the numeric string from the right
DIGITS = {
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
    # Prefixed by ͵
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

NUM_SUFFIX = "ʹ"
THOUSANDS_PREFIX = "͵"


def parse_numeral(ctx):
    # Parse thousands.
    if ctx.src[ctx.cur] == THOUSANDS_PREFIX:
        tk = ctx.src[ctx.cur + 1]

        try:
            ctx.dest.append(DIGITS[4][tk])
            # Fill 3 slots with zeroes, other digits will be captured when
            # NUM_PREFIX shows up if they are not zeroes.
            ctx.dest.extend(["0", "0", "0"])
            ctx.cur += 2

        except KeyError:
            ctx.warnings.append(
                    f"Character `{tk}` at position {ctx.cur + 1} "
                    "is not a valid thousands character.")
            ctx.cur += 1

        finally:
            return CONT

    # Parse 1÷999.
    if ctx.src[ctx.cur] == NUM_SUFFIX:
        # go back maximum 3 positions.
        for i in range(1, 4):
            cur = ctx.cur - i
            if cur >= 0:
                num_tk = ctx.src[cur]  # Number to be parsed
                if ctx.dest[-i] in DIGITS[i]:
                    # Not yet reached word boundary.
                    ctx.dest[-i] = num_tk
                else:
                    if ctx.dest[-i] != " ":  # Word boundary.
                        # Something's wrong.
                        ctx.warnings.append(
                                f"Character `{ctx.dest[-i] }` at position "
                                f"{cur} is not a valid digit character "
                                f"at place #{4 - i} in a numeral.")

                    return  # Continue normal parsing.

        ctx.cur += 1
        return CONT
