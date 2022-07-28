import logging


__doc__ = """ Test hook functions. """


logger = logging.getLogger(__name__)


def rotate(ctx, n):
    """
    Simple character rotation.

    Implements the Caesar's Cypher algorithm by shifting a single
    [A-Za-z] character by `n` places, and wrapping around
    the edges.

    Characters not in range are not shifted.
    """
    uc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    lc = uc.lower()
    logger.debug(f"cursor: {ctx.cur}")

    ch = ctx.src[ctx.cur]
    if ch in uc:
        idx = uc.index(ch)
        dest_ch = uc[(idx + n) % len(uc)]
    elif ch in lc:
        idx = lc.index(ch)
        dest_ch = lc[(idx + n) % len(lc)]
    else:
        dest_ch = ch
    logger.debug(f"ROT {n}: {ch} -> {dest_ch}")

    ctx.dest_ls.append(dest_ch)
    ctx.cur += 1

    return "continue"
