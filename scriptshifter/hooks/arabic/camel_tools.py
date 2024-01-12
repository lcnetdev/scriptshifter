from os import path
from sys import path as syspath

from scriptshifter import APP_ROOT
from scriptshifter.exceptions import BREAK


CAMEL_DIR = path.join(path.dirname(APP_ROOT), "ext", "arabic_rom")
MODULE_DIR = path.join(CAMEL_DIR, "src")

MODEL_DIR = path.join(
        path.dirname(path.realpath(__file__)), "data", "model_mle")
MODEL_PATH = path.join(MODEL_DIR, "size1.0.tsv")

syspath.append(MODULE_DIR)


def s2r_post_config(ctx):
    from predict import mle_predict as mle
    from predict import translit_rules as tr

    loc_exceptional = tr.load_exceptional_spellings()
    loc_mappings = tr.load_loc_mappings()

    mle_model = mle.load_mle_model(mle_model_tsv=MODEL_PATH)
    ctx.dest = mle.apply_mle_translit_simple_backoff(
            ctx.src,
            mle_model,
            loc_mappings,
            loc_exceptional)

    return BREAK
