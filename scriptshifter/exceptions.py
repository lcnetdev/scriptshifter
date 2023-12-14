__doc__ = """ Exceptions and special return codes. """

BREAK = "__break"
CONT = "__continue"


class ApiError(Exception):
    """ Base class for all exceptions expecting an API response. """
    status_code = 400
    msg = "An undefined error occurred."

    def __init__(self, msg=None):
        if msg is not None:
            self.msg = msg

    def to_json(self):
        return {
            "message": self.msg,
            "status_code": self.status_code,
        }


class ConfigError(ApiError):
    """ Raised when a malformed configuration is detected. """
    pass


class UpstreamError(ApiError):
    """ Raised when an external service responds with an error code. """
    pass
