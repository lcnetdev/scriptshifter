import logging
import re
from scriptshifter.exceptions import CONT


__doc__ = """ Process contextual substitutions for prenasalization. """


logger = logging.getLogger(__name__)


def s2r_post(ctx):
    # clean up word initial pre-nasalization
    regex1 = r"\b([Nn])([Nn])([dgjDGJ])"
    subst1 = r"\g<1>\g<3>"
    ctx.dest = re.sub(regex1, subst1, ctx.dest, 0)
    regex2 = r"\b([Mm])([Mm])([bB])"
    subst2 = r"\g<1>\g<3>"
    ctx.dest = re.sub(regex2, subst2, ctx.dest, 0)
    regex3 = r"\b(N)(b)"
    subst3 = r"M\g<2>"
    # clean up nested lower case when source text is all caps
    ctx.dest = re.sub(regex3, subst3, ctx.dest, 0)
    regex4 = r"([ABƁCDƊEFGHIJKLMNŊÑOPQRSTUVWYƳZ])([abɓcdɗefghijklmnŋñopqrstuvwyƴz][bhp]?)([ABƁCDƊEFGHIJKLMNŊÑOPQRSTUVWYƳZ])"
    nested_lower = re.search(regex4, ctx.dest)
    if nested_lower:
        ctx.dest = re.sub(regex4, nested_lower.string.upper(), ctx.dest, 0)
    return(None)

def r2s_post(ctx):
    # clean up word initial pre-nasalization
    regex1 = r"\b([𞤲𞤐])𞥋([𞤄𞤁𞤘𞤔𞤦𞤣𞤺𞤶])"
    subst1 = r"\g<1>\g<2>"
    ctx.dest = re.sub(regex1, subst1, ctx.dest, 0)
    regex2 = r"\b([𞤃])([𞤦])"
    subst2 = r"𞤐\g<2>"
    ctx.dest = re.sub(regex2, subst2, ctx.dest, 0)
    return(None)