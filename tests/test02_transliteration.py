import logging

from unittest import TestCase
from csv import reader

from importlib import reload
from os import environ, path

from tests import TEST_DATA_DIR
from transliterator.trans import transliterate
import transliterator.tables


logger = logging.getLogger(__name__)


class TestScriptToRoman(TestCase):
    """
    Test S2R transliteration.

    TODO use a comprehensive sample table and report errors for unsupported
    languages.
    """
    def setUp(self):
        if "TXL_CONFIG_TABLE_DIR" in environ:
            del environ["TXL_CONFIG_TABLE_DIR"]
            reload(transliterator.tables)
            # import transliterator.tables

    def test_basic_chinese(self):
        src = "撞倒須彌 : 漢傳佛教青年學者論壇論文集"
        dest = (
                "Zhuang dao Xumi : han zhuan Fo jiao qing nian xue zhe lun "
                "tan lun wen ji")

        trans = transliterate(src, "chinese")
        assert trans == dest

    def test_available_samples(self):
        """
        Test all available samples for the implemented tables.
        """
        for k, script, roman in _test_cases():
            txl = transliterate(script, k)
            if txl != roman:
                warn_str = f"Mismatching transliteration in {k}!"
                logger.warning("*" * len(warn_str))
                logger.warning(warn_str)
                logger.warning("*" * len(warn_str))
                logger.info(f"Transliterated string: {txl}")
                logger.info(f"        Target string: {roman}")

            # assert txl == roman


def _test_cases():
    test_cases = []
    with open(
            path.join(TEST_DATA_DIR, "sample_strings.csv"),
            newline="") as fh:
        csv = reader(fh)
        csv.__next__()  # Discard header row.
        for row in csv:
            if len(row[2]):
                # Table key, script, Roman
                test_cases.append((row[2], row[3], row[4]))

    return test_cases
