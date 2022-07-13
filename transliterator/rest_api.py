from os import environ

from flask import Flask, request


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
    return "TODO list of supported languages goes here."


@app.route("/scripts")
@app.route("/scripts/<lang>")
def list_scripts(lang=None):
    lang_str = f"for {lang}" if lang else "for all languages"
    return f"TODO list of supported scripts {lang_str} go here."


@app.route("/trans/<script>/<lang>/<dir>", methods=["POST"])
def transliterate(script, lang, dir):
    in_txt = request.form["text"]
    return (
            f"TODO transliterate text {in_txt}, language {lang}, "
            f"script {script}, direction {dir}")
