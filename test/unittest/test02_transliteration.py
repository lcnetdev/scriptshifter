import logging

from unittest import TestCase
from os import environ, unlink

from scriptshifter.tables import init_db
from test.integration import test_sample


logger = logging.getLogger(__name__)


def setUpModule():
    init_db()


def tearDownModule():
    unlink(environ["TXL_DB_PATH"])


class TestTrans(TestCase):
    """
    Test transliteration.

    Use "unittest" sample table.
    """

    def test_integration_sample(self):
        test_sample("unittest", False)
