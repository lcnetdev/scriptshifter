from importlib import reload
from os import path, environ
from tempfile import gettempdir

import scriptshifter
from scriptshifter import tables


TEST_DIR = path.dirname(path.realpath(__file__))
TEST_DATA_DIR = path.join(TEST_DIR, "data")
TEST_CONFIG_DIR = path.join(TEST_DIR, "tables", "data")

# Reload main SS modules after changing environment variables.
environ["TXL_DB_PATH"] = path.join(gettempdir(), "scriptshifter_unittest.db")
reload(scriptshifter)
environ["TXL_CONFIG_TABLE_DIR"] = TEST_CONFIG_DIR
reload(tables)
