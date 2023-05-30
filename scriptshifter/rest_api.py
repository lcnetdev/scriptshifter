import logging

from base64 import b64encode
from copy import deepcopy
from os import environ, urandom

from flask import Flask, Response, jsonify, render_template, request

from scriptshifter.tables import list_tables, load_table
from scriptshifter.trans import transliterate


logger = logging.getLogger(__name__)


def create_app():
    flask_env = environ.get("TXL_APP_MODE", "production")
    app = Flask(__name__)
    app.config.update({
        "ENV": flask_env,
        "SECRET_KEY": environ.get("TXL_FLASK_SECRET", b64encode(urandom(64))),
        "JSON_AS_ASCII": False,
        "JSONIFY_PRETTYPRINT_REGULAR": True,

    })

    return app


app = create_app()


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html", languages=list_tables())


@app.route("/health", methods=["GET"])
def health_check():
    return "I'm alive!\n"


@app.route("/languages", methods=["GET"])
def list_languages():
    return jsonify(list_tables())


@app.route("/table/<lang>")
def dump_table(lang):
    """
    Dump parsed transliteration table for a language.
    """
    tbl = deepcopy(load_table(lang))
    for sec_name in ("roman_to_script", "script_to_roman"):
        if sec_name in tbl:
            for hname, fn_defs in tbl[sec_name].get("hooks", {}).items():
                tbl[sec_name]["hooks"][hname] = [
                        (fn.__name__, kw) for (fn, kw) in fn_defs]

    return jsonify(tbl)


@app.route("/transliterate", methods=["POST"])
def transliterate_form():
    """ UI version of the `trans` endpoint. Passes everything via form. """
    return transliterate_req(
            request.form["lang"], request.form.get("r2s", False))


@app.route("/trans/<lang>/r2s", methods=["POST"], defaults={"r2s": True})
@app.route("/trans/<lang>", methods=["POST"])
def transliterate_req(lang, r2s=False):
    in_txt = request.form["text"]
    capitalize = request.form.get("capitalize", False)
    if not len(in_txt):
        return ("No input text provided! ", 400)

    try:
        out = transliterate(in_txt, lang, r2s, capitalize)
    except (NotImplementedError, ValueError) as e:
        return (str(e), 400)

    rsp = Response(out, mimetype="text/plain")
    rsp.headers["Content-Type"] = "text/plain; charset=utf-8"

    return rsp
