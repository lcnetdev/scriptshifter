import logging

from unittest import TestCase, TestSuite, TextTestRunner
from csv import reader

from importlib import reload
from os import environ, path

from tests import TEST_DATA_DIR
from transliterator.trans import transliterate
import transliterator.tables


logger = logging.getLogger(__name__)


class TestTrans(TestCase):
    """
    Test S2R transliteration.

    TODO use a comprehensive sample table and report errors for unsupported
    languages.
    """
    """
    Modified test case class to run independent tests for each CSV row.
    """

    def sample_s2r(self):
        """
        Test S2R transliteration for one CSV sample.

        This function name won't start with `test_` otherwise will be
        automatically run without parameters.
        """
        txl = transliterate(self.script, self.tbl)
        self.assertEqual(txl, self.roman)

    def sample_r2s(self):
        """
        Test R2S transliteration for one CSV sample.

        This function name won't start with `test_` otherwise will be
        automatically run without parameters.
        """
        txl = transliterate(self.roman, self.tbl, r2s=True)
        self.assertEqual(txl, self.script)


def make_suite():
    """
    Build parametrized test cases.
    """
    suite = TestSuite()
    with open(
            path.join(TEST_DATA_DIR, "sample_strings.csv"),
            newline="") as fh:
        csv = reader(fh)
        csv.__next__()  # Discard header row.

        for row in csv:
            if len(row[2]):
                # Inject transliteration info in the test case.
                for tname in ("sample_s2r", "sample_r2s"):
                    tcase = TestTrans(tname)
                    tcase.tbl = row[2]
                    tcase.script = row[3]
                    tcase.roman = row[4]
                    suite.addTest(tcase)

    return suite


if "TXL_CONFIG_TABLE_DIR" in environ:
    del environ["TXL_CONFIG_TABLE_DIR"]
    reload(transliterator.tables)

TextTestRunner().run(make_suite())
