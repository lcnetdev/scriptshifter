import unittest

from transliterator.trans import transliterate


class TestScriptToRoman(unittest.TestCase):
    """
    Test S2R transliteration.

    TODO use a comprehensive sample table and report errors for unsupported
    languages.
    """

    def test_basic_chinese(self):
        src = "撞倒須彌 : 漢傳佛教青年學者論壇論文集"
        dest = (
                "Zhuang dao Xumi : Han chuan Fo jiao qing nian xue zhe lun "
                "tan lun wen ji ")

        assert transliterate(src, "chinese") == dest
