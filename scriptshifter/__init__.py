import logging

from os import environ, path

from dotenv import load_dotenv


env = load_dotenv()

APP_ROOT = path.dirname(path.realpath(__file__))

logging.basicConfig(
        # filename=environ.get("TXL_LOGFILE", "/dev/stdout"),
        level=environ.get("TXL_LOGLEVEL", logging.WARN))
logger = logging.getLogger(__name__)

if not env:
    logger.warn("No .env file found. Assuming env was passed externally.")
