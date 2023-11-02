import logging

from base64 import b64encode
from copy import deepcopy
from email.message import EmailMessage
from json import loads, dumps
from os import environ, urandom
from smtplib import SMTP

from flask import Flask, jsonify, render_template, request

from scriptshifter import SMTP_HOST, SMTP_PORT
from scriptshifter.tables import list_tables, load_table
from scriptshifter.trans import transliterate


logger = logging.getLogger(__name__)
logging.basicConfig(level=environ.get("TXL_LOGLEVEL", logging.INFO))


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


@app.route("/options/<lang>", methods=["GET"])
def get_options(lang):
    """
    Get extra options for a table.
    """
    tbl = load_table(lang)

    return jsonify(tbl.get("options", []))


@app.route("/trans", methods=["POST"])
def transliterate_req():
    lang = request.form["lang"]
    in_txt = request.form["text"]
    capitalize = request.form.get("capitalize", False)
    t_dir = request.form.get("t_dir", "s2r")
    if t_dir not in ("s2r", "r2s"):
        return f"Invalid direction: {t_dir}", 400

    if not len(in_txt):
        return ("No input text provided! ", 400)
    options = loads(request.form.get("options", "{}"))
    logger.debug(f"Extra options: {options}")

    try:
        out, warnings = transliterate(in_txt, lang, t_dir, capitalize, options)
    except (NotImplementedError, ValueError) as e:
        return (str(e), 400)

    return {"output": out, "warnings": warnings}


@app.route("/feedback", methods=["POST"])
def feedback():
    """
    Allows users to provide feedback to improve a specific result.
    """
    lang = request.form["lang"]
    src = request.form["src"]
    t_dir = request.form.get("t_dir", "s2r")
    result = request.form["result"]
    expected = request.form["expected"]
    options = request.form.get("options", {})
    notes = request.form.get("notes")
    contact = request.form.get("contact")

    msg = EmailMessage()
    msg["subject"] = "Scriptshifter feedback report"
    msg["from"] = "stefano@cossu.cc"
    msg["to"] = "stefano@cossu.cc"
    if contact:
        msg["cc"] = contact
    msg.set_content(f"""
        *Scriptshifter feedback report from {contact or 'anonymous'}*\n\n
        *Language:* {lang}\n
        *Direction:* {
                    'Roman to Script' if t_dir == 'r2s'
                    else 'Script to Roman'}\n
        *Source:* {src}\n
        *Result:* {result}\n
        *Expected result:* {expected}\n
        *Applied options:* {dumps(options)}\n
        *Notes:*\n
        {notes}""")

    # TODO This uses a test SMTP server:
    # python -m smtpd -n -c DebuggingServer localhost:1025
    smtp = SMTP(SMTP_HOST, SMTP_PORT);
    smtp.send_message(msg)
    smtp.quit()

    return {"message": "Feedback message sent."}
