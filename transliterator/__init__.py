import logging

from os import environ, path


APP_ROOT = path.dirname(path.realpath(__file__))

logging.basicConfig(
        # filename=environ.get("TXL_LOGFILE", "/dev/stdout"),
        level=environ.get("TXL_LOGLEVEL", logging.INFO))
logger = logging.getLogger(__name__)
