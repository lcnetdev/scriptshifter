from os import environ, unlink
from unittest import TestCase

from scriptshifter.trans import transliterate
from scriptshifter.tables import init_db


def setUpModule():
    init_db()


def tearDownModule():
    unlink(environ["TXL_DB_PATH"])


class TestCapitalization(TestCase):
    """
    Test capitalization.
    """
    def test_cap(self):
        tbl = "cap_inherited"
        in_str = "зг іо"
        tx = transliterate(in_str, tbl)[0]
        tx_cap = transliterate(in_str, tbl, capitalize="first")[0]
        tx_all = transliterate(in_str, tbl, capitalize="all")[0]

        self.assertEqual(tx, "zh io")
        self.assertEqual(tx_cap, "Zh io")
        self.assertEqual(tx_all, "Zh Io")

    def test_cap_ligatures(self):
        tbl = "cap_inherited"
        in_str = "жзг ёіо зг іо"
        tx = transliterate(in_str, tbl)[0]
        tx_cap = transliterate(in_str, tbl, capitalize="first")[0]
        tx_all = transliterate(in_str, tbl, capitalize="all")[0]

        self.assertEqual(tx, "z︠h︡zh i︠o︡io zh io")
        self.assertEqual(tx_cap, "Z︠H︡zh i︠o︡io zh io")
        self.assertEqual(tx_all, "Z︠H︡zh I︠o︡io Zh Io")
