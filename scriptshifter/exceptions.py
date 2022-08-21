__doc__ = """ Exceptions and special return codes. """

BREAK = "__break"
CONT = "__continue"


class ConfigError(Exception):
    """ Raised when a malformed configuration is detected. """
    pass
