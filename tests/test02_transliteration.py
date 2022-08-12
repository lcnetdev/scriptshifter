from unittest import TestCase

from importlib import reload
from os import environ

from transliterator.trans import transliterate
import transliterator.tables


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
        breakpoint()
        src = "撞倒須彌 : 漢傳佛教青年學者論壇論文集"
        dest = (
                "Zhuang dao Xumi : han zhuan Fo jiao qing nian xue zhe lun "
                "tan lun wen ji")

        trans = transliterate(src, "chinese")
        assert trans == dest
