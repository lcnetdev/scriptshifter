from importlib import reload
from os import path

import scriptshifter.tables


TEST_DIR = path.dirname(path.realpath(__file__))
TEST_DATA_DIR = path.join(TEST_DIR, "data")


def reload_tables():
    reload(scriptshifter.tables)  # Reload new config dir.
    from scriptshifter import tables
    tables.list_tables.cache_clear()
    tables.load_table.cache_clear()

    return tables
