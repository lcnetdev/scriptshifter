__doc__ = """ Exceptions and special return codes. """

BREAK = "__break"
CONT = "__continue"


class ApiError(Exception):
    """ Base class for all exceptions expecting an API response. """
    status_code = 400
    msg = "An undefined error occurred."

    def __init__(self, msg=None, status_code=None):
        if msg is not None:
            self.msg = msg
        if status_code is not None:
            self.status_code = status_code

    def to_json(self):
        return {
            "message": self.msg,
            "status_code": self.status_code,
        }


class ConfigError(ApiError):
    """ Raised when a malformed configuration is detected. """
    status_code = 500


class UpstreamError(ApiError):
    """ Raised when an external service responds with an error code. """
    status_code = 500
