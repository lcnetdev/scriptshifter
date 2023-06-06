from os import path

from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


K_BASEDIR = path.dirname(path.realpath(__file__))

with open(path.join(K_BASEDIR, "data.yml")) as fh:
    KCONF = load(fh, Loader=Loader)
