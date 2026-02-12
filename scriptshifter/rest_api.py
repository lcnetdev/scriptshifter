import logging

from base64 import b64encode
from email.message import EmailMessage
from email.generator import Generator
from json import dumps
from os import environ, urandom
from smtplib import SMTP
from tempfile import NamedTemporaryFile

from flask import Flask, jsonify, render_template, request
from flask_cors import CORS

from scriptshifter import (
        EMAIL_FROM, EMAIL_TO,
        GIT_COMMIT, GIT_TAG,
        SMTP_HOST, SMTP_PORT,
        FEEDBACK_PATH)
from scriptshifter.exceptions import ApiError
from scriptshifter.tables import list_tables, get_language
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
    CORS(app)

    return app


app = create_app()


@app.errorhandler(ApiError)
def handle_exception(e: ApiError):
    if e.status_code >= 500:
        warnings = [
            "An internal error occurred.",
            "If the error persists, contact the technical support team."
        ]
    else:
        warnings = [
            "ScriptShifter API replied with status code "
            f"{e.status_code}: {e.msg}"
        ]
        if e.status_code >= 400:
            warnings.append(
                    "Please review your input before repeating this request.")

    body = {
        "warnings": warnings,
        "output": "",
    }
    if logging.DEBUG >= logging.root.level:
        body["debug"] = {
            "form_data": request.json or request.form,
        }
    return (body, e.status_code)


@app.route("/", methods=["GET"])
def index():
    return render_template(
            "index.html",
            languages=sorted(
                list_tables().items(),
                key=lambda k: k[1]["label"]
            ),
            version_info=(GIT_TAG, GIT_COMMIT),
            feedback_form=SMTP_HOST is not None or FEEDBACK_PATH is not None)


@app.route("/health", methods=["GET"])
def health_check():
    return "I'm alive!\n"


@app.route("/languages", methods=["GET"])
def list_languages():
    return jsonify(list_tables())


@app.route("/table/<lang>")
def dump_table(lang):
    """
    Dump a language configuration from the DB.
    """
    return get_language(lang)


@app.route("/options/<lang>", methods=["GET"])
def get_options(lang):
    """
    Get extra options for a table.
    """
    tbl = get_language(lang)

    return jsonify(tbl.get("options", []))


@app.route("/trans", methods=["POST"])
def transliterate_req():
    lang = request.json["lang"]
    in_txt = request.json["text"]
    capitalize = request.json.get("capitalize", False)
    t_dir = request.json.get("t_dir", "s2r")
    if t_dir not in ("s2r", "r2s"):
        return f"Invalid direction: {t_dir}", 400

    if not len(in_txt):
        return ("No input text provided! ", 400)
    options = request.json.get("options", {})
    logger.debug(f"Extra options: {options}")

    try:
        out, warnings = transliterate(in_txt, lang, t_dir, capitalize, options)
    except (NotImplementedError, ValueError) as e:
        raise ApiError(str(e), 400)
    except Exception as e:
        raise ApiError(str(e), 500)

    return {"output": out, "warnings": warnings}


@app.route("/feedback", methods=["POST"])
def feedback():
    """
    Allows users to provide feedback to improve a specific result.
    """
    if not SMTP_HOST and not FEEDBACK_PATH:
        return {"message": "Feedback form is not configured."}, 501

    t_dir = request.json.get("t_dir", "s2r")
    options = request.json.get("options", {})
    contact = request.json.get("contact")

    msg = EmailMessage()
    msg["subject"] = "Scriptshifter feedback report"
    msg["from"] = EMAIL_FROM
    msg["to"] = EMAIL_TO
    if contact:
        msg["cc"] = contact
    msg.set_content(f"""
        *Scriptshifter feedback report from {contact or 'anonymous'}*\n\n
        *Language:* {request.json['lang']}\n
        *Direction:* {
                    'Roman to Script' if t_dir == 'r2s'
                    else 'Script to Roman'}\n
        *Source:* {request.json['src']}\n
        *Result:* {request.json['result']}\n
        *Expected result:* {request.json['expected']}\n
        *Applied options:* {dumps(options)}\n
        *Notes:*\n
        {request.json['notes']}""")

    if SMTP_HOST:
        # TODO This uses a test SMTP server:
        # python -m smtpd -n -c DebuggingServer localhost:1025
        smtp = SMTP(SMTP_HOST, SMTP_PORT)
        smtp.send_message(msg)
        smtp.quit()

    else:
        with NamedTemporaryFile(
                suffix=".txt", dir=FEEDBACK_PATH, delete=False) as fh:
            gen = Generator(fh)
            gen.write(msg.as_bytes())
            logger.info(f"Feedback message generated at {fh.name}.")

    return {"message": "Feedback message sent."}
