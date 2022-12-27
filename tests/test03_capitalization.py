from os import environ
from unittest import TestCase

from tests import TEST_DATA_DIR, reload_tables


class TestCapitalization(TestCase):
    """
    Test capitalization.
    """

    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        reload_tables()

    def test_cap(self):
        pass

    def test_cap_ligatures(self):
        pass
