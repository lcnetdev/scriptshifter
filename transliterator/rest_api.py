from os import environ

from flask import Flask, Response, jsonify, request

from transliterator.tables import list_tables, load_table
from transliterator.trans import transliterate


def create_app():
    app = Flask(__name__)
    app.config.update({
        "ENV": environ.get("TXL_APP_MODE", "production"),
        "SECRET_KEY": environ["TXL_FLASK_SECRET"],
        "USE_X_SENDFILE": True,
        "JSON_AS_ASCII": False,
        "JSONIFY_PRETTYPRINT_REGULAR": True,
    })

    return app


app = create_app()


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
    return jsonify(load_table(lang))


@app.route("/trans/<lang>/r2s", methods=["POST"], defaults={"s2r": False})
@app.route("/trans/<lang>", methods=["POST"])
def transliterate_req(lang, s2r=True):
    in_txt = request.form["text"]
    if not len(in_txt):
        return ("No input text provided! ", 400)

    return Response(
            transliterate(in_txt, lang, s2r),
            content_type="text/plain")
