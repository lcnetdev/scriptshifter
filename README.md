# ScriptShifter

REST API service to convert non-Latin scripts to Latin, and vice versa.

## Environment variables

The provided `example.env` can be renamed to `.env` in your deployment and/or
moved to a location that is not under version control, and adjusted to fit the
environment. The file will be parsed directly by the application if present,
or it can be pre-loaded in a Docker environment.

Currently, the following environment variables are defined:

- `TXL_LOGLEVEL`: Application log level. Defaults to `WARN`.
- `TXL_FLASK_SECRET`: Flask secret key.
- `TXL_DICTA_EP`: Endpoint for the Dicta Hebrew transliteration service. This
  is mandatory for using the Hebrew module.

## Local development server

For local development, it is easiest to run Flask without the WSGI wrapper,
possibly in a virtual environment:

``` bash
# python -m venv /path/to/venv
# source /path/to/venv/bin/activate
# pip install -r requirements.txt
# flask run
```

It is advised to set `FLASK_DEBUG=true` to reload the web app on code changes
and print detailed stack traces when exceptions are raised. Note that changes
to any .yml file do NOT trigger a reload of Flask.

Alternatively, the transliteration interface can be accessed directly from
Python: 

``` python
from scriptshifter.trans import transliterate

transliterate("some text", "some language")
```

## Run on Docker

Build container in current dir:

```
docker build -t scriptshifter:latest .
```

Start container:

```
docker run --env-file .env -p 8000:8000 scriptshifter:latest
```

For running in development mode, add `-e FLASK_ENV=development` to the options.


## Web UI

`/` renders a simple HTML form to test the transliteration service.


## Contributing

See the [contributing guide](./doc/contributing.md).

## Further documentation

See the [`doc`](./doc) folder for additional documentation.
