__doc__ = """ Common tools for core and hooks. """


def capitalize(src):
    """ Only capitalize first word and words preceded by space."""
    orig_ls = src.split(" ")
    cap_ls = [orig[0].upper() + orig[1:] for orig in orig_ls]

    return " ".join(cap_ls)
