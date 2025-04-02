from csv import reader
from os import environ, path, unlink
from unittest import TestCase

from scriptshifter.trans import Context, FEAT_R2S
from scriptshifter.tables import init_db

from test import TEST_DATA_DIR


def setUpModule():
    init_db()


def tearDownModule():
    unlink(environ["TXL_DB_PATH"])


class TestNormalization(TestCase):
    """ Source normalization tests. """

    def test_norm_decompose_r2s(self):
        with open(path.join(
                TEST_DATA_DIR, "precomp_samples.csv"), newline="") as fh:
            data = reader(fh)

            for precomp, decomp in data:
                with Context("rot3", precomp, FEAT_R2S, {}) as ctx:
                    ctx.normalize_src()
                    self.assertEqual(ctx.src, decomp)
