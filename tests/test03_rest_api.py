import json

from os import environ
from unittest import TestCase

from scriptshifter.rest_api import app
from tests import TEST_DATA_DIR, reload_tables


EP = "http://localhost:8000"


class TestRestAPI(TestCase):
    """ Test REST API interaction. """
    def setUp(self):
        environ["TXL_CONFIG_TABLE_DIR"] = TEST_DATA_DIR
        # if "TXL_CONFIG_TABLE_DIR" in environ:
        #     del environ["TXL_CONFIG_TABLE_DIR"]
        reload_tables()

        # Start webapp.
        app.testing = True

    def test_health(self):
        with app.test_client() as c:
            rsp = c.get("/health")

        self.assertEqual(rsp.status_code, 200)

    def test_language_list(self):
        with app.test_client() as c:
            rsp = c.get("/languages")

        self.assertEqual(rsp.status_code, 200)

        data = json.loads(rsp.get_data(as_text=True))
        self.assertIn("inherited", data)
        self.assertIn("name", data["inherited"])
        self.assertNotIn("_base1", data)
        self.assertNotIn("_base2", data)
        self.assertNotIn("_base3", data)

    def test_lang_table(self):
        with app.test_client() as c:
            rsp = c.get("/table/ordering")

        self.assertEqual(rsp.status_code, 200)
        data = json.loads(rsp.get_data(as_text=True))

        self.assertIn("general", data)
        self.assertIn("roman_to_script", data)
        self.assertIn("map", data["roman_to_script"])
        self.assertEqual(data["roman_to_script"]["map"][0], ["ABCD", ""])

    def test_trans_api_s2r(self):
        with app.test_client() as c:
            rsp = c.post("/trans/rot3", data={"text": "defg"})

        self.assertEqual(rsp.status_code, 200)
        data = rsp.get_data(as_text=True)

        self.assertEqual(data, "abcd")

    def test_trans_api_r2s(self):
        with app.test_client() as c:
            rsp = c.post("/trans/rot3/r2s", data={"text": "abcd"})

        self.assertEqual(rsp.status_code, 200)
        data = rsp.get_data(as_text=True)

        self.assertEqual(data, "defg")

    def test_trans_api_capitalize(self):
        with app.test_client() as c:
            rsp = c.post(
                    "/trans/rot3/r2s",
                    data={"capitalize": "first", "text": "bcde"})

        self.assertEqual(rsp.status_code, 200)
        data = rsp.get_data(as_text=True)

        self.assertEqual(data, "Efgh")

    def test_trans_form(self):
        with app.test_client() as c:
            rsp = c.post(
                    "/transliterate", data={
                        "text": "abcd",
                        "r2s": "true",
                        "lang": "rot3",
                    })

        self.assertEqual(rsp.status_code, 200)
        data = rsp.get_data(as_text=True)

        self.assertEqual(data, "defg")
