import json

from os import environ, unlink
from unittest import TestCase

from scriptshifter.rest_api import app


EP = "http://localhost:8000"


def setUpModule():
    from scriptshifter.tables import init_db
    init_db()


def tearDownModule():
    unlink(environ["TXL_DB_PATH"])


class TestRestAPI(TestCase):
    """ Test REST API interaction. """
    # def setUp(self):
    #     # Start webapp.
    #     app.testing = True

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
        self.assertIn("label", data["inherited"])
        self.assertNotIn("_base1", data)
        self.assertNotIn("_base2", data)
        self.assertNotIn("_base3", data)

    def test_lang_table(self):
        with app.test_client() as c:
            rsp = c.get("/table/ordering")

        self.assertEqual(rsp.status_code, 200)
        data = json.loads(rsp.get_data(as_text=True))

        self.assertIn("case_sensitive", data)
        self.assertIn("description", data)
        self.assertIn("roman_to_script", data)
        self.assertIn("map", data["roman_to_script"])
        self.assertEqual(data["has_r2s"], True)
        self.assertEqual(data["has_s2r"], False)
        self.assertEqual(data["roman_to_script"]["map"][0], ["ABCD", ""])

    def test_trans_api_s2r(self):
        with app.test_client() as c:
            rsp = c.post("/trans", json={"lang": "rot3", "text": "defg"})

        self.assertEqual(rsp.status_code, 200)
        data = json.loads(rsp.get_data(as_text=True))

        self.assertEqual(data["output"], "abcd")

    def test_trans_api_r2s(self):
        with app.test_client() as c:
            rsp = c.post(
                "/trans", json={
                    "lang": "rot3",
                    "text": "abcd",
                    "t_dir": "r2s"
                }
            )

        self.assertEqual(rsp.status_code, 200)
        data = json.loads(rsp.get_data(as_text=True))

        self.assertEqual(data["output"], "defg")

    def test_trans_api_capitalize(self):
        with app.test_client() as c:
            rsp = c.post(
                "/trans",
                json={
                    "lang": "rot3",
                    "capitalize": "first",
                    "text": "bcde",
                    "t_dir": "r2s"
                }
            )

        self.assertEqual(rsp.status_code, 200)
        data = json.loads(rsp.get_data(as_text=True))

        self.assertEqual(data["output"], "Efgh")
