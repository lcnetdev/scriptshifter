from os import environ
from unittest import TestCase

from scriptshifter.trans import transliterate
from tests import TEST_DATA_DIR, reload_tables


class TestCapitalization(TestCase):
    """
    Test capitalization.
    """

    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        self.tables = reload_tables()

    def test_cap(self):
        tbl = "cap_inherited"
        in_str = "зг іо"
        tx = transliterate(in_str, tbl)
        tx_cap = transliterate(in_str, tbl, capitalize="first")
        tx_all = transliterate(in_str, tbl, capitalize="all")

        self.assertEqual(tx, "zh io")
        self.assertEqual(tx_cap, "Zh io")
        self.assertEqual(tx_all, "Zh Io")

    def test_cap_ligatures(self):
        tbl = "cap_inherited"
        in_str = "жзг ёіо зг іо"
        tx = transliterate(in_str, tbl)
        tx_cap = transliterate(in_str, tbl, capitalize="first")
        tx_all = transliterate(in_str, tbl, capitalize="all")

        self.assertEqual(tx, "z︠h︡zh i︠o︡io zh io")
        self.assertEqual(tx_cap, "Z︠H︡zh i︠o︡io zh io")
        self.assertEqual(tx_all, "Z︠H︡zh I︠o︡io Zh Io")
