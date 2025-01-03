# ScriptShifter

REST API service to convert non-Latin scripts to Latin, and vice versa.

[View supported scripts](/doc/supported_scripts.md).

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

## Initial setup

In order to run Scriptshifter, a local SQLite database must be created. The
simplest way to do that is via command-line:

```bash
./sscli admin init-db
```

This step is already included in the `entrypoint.sh` script that gets executed
by Docker, so no additional action is necessary.

Note that the DB must be recreated every time any of the configuration tables
in `scriptshifter/tables/data` changes.

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


## Environment variables

The following environment variables are available for modification:

`TXL_EMAIL_FROM`: Email address sending the feedback form on behalf of users.

`TXL_EMAIL_TO`: Recipients of the feedback form.

`TXL_FLASK_SECRET`: Seed for web server security. Set to a random-generated
string in a production environment.

`TXL_LOGLEVEL`: Logging level. Use Python notation. The default is `WARN`.

`TXL_SMTP_HOST`: SMTP host to send feedback messages through.

`TXL_SMTP_PORT`: Port of the SMTP server. Defaults to `1025`.

`TXL_FEEDBACK_PATH`: if a SMTP server is not available, the feedback message
may be written to a file under this given path for further processing. The file
will have a random name and a `.txt` suffix. This option is only available if
`TXL_SMTP_HOST` is not defined. If neither `TXL_SMTP_HOST` nor
`TXL_FEEDBACK_PATH` is defined, the feedback form will not be shown in the UI
and a POST request to the `/feedback` REST endpoint will result in a `501 Not
Implemented` error.


## Web UI

`/` renders a simple HTML form to test the transliteration service.

Adding a language as a value of the `lang` URL parameter, the UI will start
with that language selected. E.g. `/?lang=chinese` will select Chinese from
the drop-down automatically. The value must be one of the keys found in
`/languages`.


## Command-line interface

Various Scriptshifter commands can be accessed via the shell command `sscli`.
At the moment a few essential admin and testing tools are available, as well as
a transliteration function. More commands can be made available on an as-needed
basis.

Help menu:

```
/path/to/sscli --help
```

Section help:

```
/path/to/sscli admin --help
```

Transliteration:

```
echo "王正强" | /path/to/sscli trans chinese -c first -o "marc_field=100"
```


## Contributing

See the [contributing guide](./doc/contributing.md).

## Further documentation

See the [`doc`](./doc) folder for additional documentation.
