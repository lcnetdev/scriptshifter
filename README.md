# ScriptShifter

REST API service to convert non-Latin scripts to Latin, and vice versa.

## Run on Docker

Build container in current dir:

```
docker build -t scriptshifter:latest .
```

Start container:

```
docker run -e TXL_FLASK_SECRET=changeme -p 8000:8000 scriptshifter:latest
```

For running in development mode, add `-e FLASK_ENV=development` to the options.


## Environment variables

The following environment variables are available for modification:

`TXL_EMAIL_FROM`: Email address sending the feedback form on behalf of users.

`TXL_EMAIL_TO`: Recipients of the feedback form.

`TXL_FLASK_SECRET`: Seed for web server security. Set to a random-generated
string in a production environment.

`TXL_LOGLEVEL`: Logging level. Use Python notation. The default is `WARN`.

`TXL_SMTP_HOST`: SMTP host to send feedback messages through. Defaults to
`localhost`.

`TXL_SMTP_PORT`: Port of the SMTP server. Defaults to `1025`.

## Web UI

`/` renders a simple HTML form to test the transliteration service.


## Contributing

See the [contributing guide](./doc/contributing.md).

## Further documentation

See the [`doc`](./doc) folder for additional documentation.
