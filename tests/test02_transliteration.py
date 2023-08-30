import logging

from unittest import TestCase, TestSuite, TextTestRunner
from csv import reader
from glob import glob
from os import environ, path

from tests import TEST_DATA_DIR, reload_tables
from scriptshifter.trans import transliterate
import scriptshifter.tables


logger = logging.getLogger(__name__)


class TestTrans(TestCase):
    """
    Test S2R transliteration.

    Modified test case class to run independent tests for each CSV row.

    TODO use a comprehensive sample table and report errors for unsupported
    languages.
    """

    maxDiff = None

    def sample_s2r(self):
        """
        Test S2R transliteration for one CSV sample.

        This function name won't start with `test_` otherwise will be
        automatically run without parameters.
        """
        config = scriptshifter.tables.load_table(self.tbl)
        if "script_to_roman" in config:
            txl = transliterate(self.script, self.tbl, capitalize="first")[0]
            self.assertEqual(
                    txl, self.roman,
                    f"S2R transliteration error for {self.tbl}!\n"
                    f"Original: {self.script}")

    def sample_r2s(self):
        """
        Test R2S transliteration for one CSV sample.

        This function name won't start with `test_` otherwise will be
        automatically run without parameters.
        """
        config = scriptshifter.tables.load_table(self.tbl)
        if "roman_to_script" in config:
            txl = transliterate(
                    self.roman, self.tbl, r2s=True, capitalize="first")[0]
            self.assertEqual(
                    txl, self.script,
                    f"R2S transliteration error for {self.tbl}!\n"
                    f"Original: {self.roman}")


def make_suite():
    """
    Build parametrized test cases.
    """
    if "TXL_CONFIG_TABLE_DIR" in environ:
        del environ["TXL_CONFIG_TABLE_DIR"]
    reload_tables()

    suite = TestSuite()

    for fpath in glob(path.join(TEST_DATA_DIR, "script_samples", "*.csv")):
        with open(fpath, newline="") as fh:
            csv = reader(fh)
            # csv.__next__()  # Discard header row.

            for row in csv:
                if len(row[0]):
                    # Inject transliteration info in the test case.
                    for tname in ("sample_s2r", "sample_r2s"):
                        tcase = TestTrans(tname)
                        tcase.tbl = row[0]
                        tcase.script = row[1].strip()
                        tcase.roman = row[2].strip()
                        suite.addTest(tcase)

    return suite


TextTestRunner().run(make_suite())
