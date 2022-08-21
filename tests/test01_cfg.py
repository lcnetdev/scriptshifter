from unittest import TestCase

from importlib import reload
from os import environ

from tests import TEST_DATA_DIR
import scriptshifter.tables


class TestConfig(TestCase):
    """ Test configuration parsing. """

    def test_ordering(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        reload(scriptshifter.tables)  # Reload new config dir.
        from scriptshifter import tables
        tables.list_tables.cache_clear()
        tables.load_table.cache_clear()

        tbl = tables.load_table("ordering")
        exp_order = ["ABCD", "AB", "A", "BCDE", "BCD", "BEFGH", "B"]

        assert [s[0] for s in tbl["roman_to_script"]["map"]] == exp_order
