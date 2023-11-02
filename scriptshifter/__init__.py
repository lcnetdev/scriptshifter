import logging

from os import environ, path


APP_ROOT = path.dirname(path.realpath(__file__))

# SMTP server for sending email. For a dummy server that just echoes the
# messages, run: `python -m smtpd -n -c DebuggingServer localhost:1025`
SMTP_HOST = environ.get("TXL_SMTP_HOST", "localhost")
try:
    SMTP_PORT = int(environ.get("TXL_SMTP_PORT", "1025"))
except ValueError:
    raise SystemError("TXL_SMTP_PORT env var is not an integer.")

logging.basicConfig(
        # filename=environ.get("TXL_LOGFILE", "/dev/stdout"),
        level=environ.get("TXL_LOGLEVEL", logging.INFO))
logger = logging.getLogger(__name__)
