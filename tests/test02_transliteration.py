import logging

from unittest import TestCase, TestSuite, TextTestRunner
from csv import reader
from json import loads as jloads
from os import environ, path, unlink

from scriptshifter.trans import transliterate
from scriptshifter.tables import get_language, init_db
from tests import TEST_DATA_DIR


logger = logging.getLogger(__name__)


def setUpModule():
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
    def sample(self):
        """
        Test transliteration for one CSV row.

        This function name won't start with `test_` otherwise will be
        automatically run without parameters.
        """
        config = get_language(self.tbl)
        t_dir = self.options.get("t_dir", "s2r")
        if (
                t_dir == "s2r" and config["has_s2r"]
                or t_dir == "r2s" and config["has_r2s"]):
            txl = transliterate(
                    self.script, self.tbl,
                    t_dir=t_dir,
                    capitalize=self.options.get("capitalize", False),
                    options=self.options)[0]
            self.assertEqual(
                    txl, self.roman,
                    f"S2R transliteration error for {self.tbl}!\n"
                    f"Original: {self.script}")


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
                tcase = TestTrans("sample")
                tcase.tbl = row[0]
                tcase.script = row[1].strip()
                tcase.roman = row[2].strip()
                tcase.options = jloads(row[3]) if len(row[3]) else {}

                suite.addTest(tcase)

    return suite


TextTestRunner().run(make_suite())
