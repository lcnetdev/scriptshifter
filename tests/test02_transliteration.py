import logging

from unittest import TestCase, TestSuite, TextTestRunner
from csv import reader
from json import loads as jloads
from os import environ, path, unlink

from scriptshifter.trans import transliterate
from scriptshifter.tables import get_language
from tests import TEST_DATA_DIR


logger = logging.getLogger(__name__)


def setUpModule():
    from scriptshifter.tables import init_db
    init_db()


def tearDownModule():
    unlink(environ["TXL_DB_PATH"])


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
        config = get_language(self.tbl)
        if config["has_s2r"]:
            txl = transliterate(
                    self.script, self.tbl,
                    capitalize=self.options.get("capitalize", False),
                    options=self.options)[0]
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
        config = get_language(self.tbl)
        if config["has_r2s"]:
            txl = transliterate(
                    self.roman, self.tbl,
                    t_dir="r2s",
                    capitalize=self.options.get("capitalize", False),
                    options=self.options)[0]
            self.assertEqual(
                    txl, self.script,
                    f"R2S transliteration error for {self.tbl}!\n"
                    f"Original: {self.roman}")


def make_suite():
    """
    Build parametrized test cases.
    """
    suite = TestSuite()

    with open(path.join(
        TEST_DATA_DIR, "script_samples", "unittest.csv"
    ), newline="") as fh:
        csv = reader(fh)
        for row in csv:
            if len(row[0]):
                # Inject transliteration info in the test case.
                for tname in ("sample_s2r", "sample_r2s"):
                    tcase = TestTrans(tname)
                    tcase.tbl = row[0]
                    tcase.script = row[1].strip()
                    tcase.roman = row[2].strip()
                    tcase.options = jloads(row[3]) if len(row[3]) else {}
                    suite.addTest(tcase)

    return suite


TextTestRunner().run(make_suite())
