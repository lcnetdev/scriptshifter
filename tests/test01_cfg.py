from unittest import TestCase

from os import environ

import scriptshifter

from tests import TEST_DATA_DIR, reload_tables


class TestConfig(TestCase):
    """ Test configuration parsing. """
    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        self.tables = reload_tables()

    def test_ordering(self):
        tbl = self.tables.load_table("ordering")
        exp_order = ["ABCD", "AB", "A", "BCDE", "BCD", "BEFGH", "B"]

        self.assertEqual(
                [s[0] for s in tbl["roman_to_script"]["map"]], exp_order)


class TestOverride(TestCase):
    """ Test configuration overrides. """
    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        self.tables = reload_tables()

    def test_override_map(self):
        tbl = self.tables.load_table("inherited")

        self.assertEqual(tbl["general"]["name"], "Test inheritance leaf file")

        # Entries are additive.
        self.assertEqual(
                tbl["roman_to_script"]["ignore"],
                ["Fritter my wig", "Hi", "Ho", "Thing-um-a-jig"])
        self.assertEqual(
                tbl["roman_to_script"]["map"],
                (
                    ("A", "a"),
                    ("B", "b"),
                    ("C", "c"),
                    ("D", "d"),
                    ("E", "e"),
                    ("F", "f"),
                    ("G", "g"),
                    ("H", "h"),
                    ("I", "i"),
                    ("J", "j"),
                    ("K", "k"),
                    ("L", "l"),
                    ("M", "m"),
                    ("N", "n"),
                    ("O", "o"),
                    ("P", "p"),
                    ("Q", "q"),
                    ("R", "r"),
                    ("S", "s"),
                    ("T", "t"),
                    ("U", "u"),
                    ("V", "v"),
                    ("W", "w"),
                    ("X", "x"),
                    ("Y", "y"),
                    ("Z", "z"),
                ))

        # First 4 entries are overridden multiple times.
        self.assertEqual(
                tbl["script_to_roman"]["map"],
                (
                    ("a", "9"),
                    ("b", "0"),
                    ("c", "7"),
                    ("d", "8"),
                    ("e", "E"),
                    ("f", "F"),
                    ("g", "G"),
                    ("h", "H"),
                    ("i", "I"),
                    ("j", "J"),
                    ("k", "K"),
                    ("l", "L"),
                    ("m", "M"),
                    ("n", "N"),
                    ("o", "O"),
                    ("p", "P"),
                    ("q", "Q"),
                    ("r", "R"),
                    ("s", "S"),
                    ("t", "T"),
                    ("u", "U"),
                    ("v", "V"),
                    ("w", "W"),
                    ("x", "X"),
                    ("y", "Y"),
                    ("z", "Z"),
                ))


class TestHooks(TestCase):
    """ Test parsing of hook functions. """
    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        self.tables = reload_tables()

    def test_rot3(self):
        tbl = self.tables.load_table("rot3")

        self.assertEqual(
                tbl["script_to_roman"]["hooks"],
                {
                    "begin_input_token": [
                        ("test", scriptshifter.hooks.test.rotate, {"n": -3})
                    ]
                })


class TestDoubleCaps(TestCase):
    """ Test double capitalization configuration. """
    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        self.tables = reload_tables()

    def test_dcaps_base1(self):
        cap_base1 = self.tables.load_table("cap_base1")
        assert "z︠h︡" in cap_base1["script_to_roman"]["double_cap"]

    def test_dcaps_base2(self):
        cap_base2 = self.tables.load_table("cap_base2")
        dcap = cap_base2["script_to_roman"]["double_cap"]

        assert len(dcap) == 2
        assert "z︠h︡" in dcap
        assert "i︠o︡" in dcap

    def test_dcaps_inherited(self):
        cap_inherited = self.tables.load_table("cap_inherited")
        dcap = cap_inherited["script_to_roman"]["double_cap"]

        assert len(dcap) == 1
        assert "z︠h︡" in dcap
        assert "i︠o︡" not in dcap
