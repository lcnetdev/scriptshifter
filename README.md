# ScriptShifter

REST API service to convert non-Latin scripts to Latin, and vice versa.

## Environment variables

- `TXL_LOGLEVEL`: Application log level. Defaults to `WARN`.
- `TXL_DICTA_EP`: Endpoint for the Dicta Hebrew transliteration service. This
  is mandatory for using the Hebrew module.

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


## Web UI

`/` renders a simple HTML form to test the transliteration service.


## Contributing

See the [contributing guide](./doc/contributing.md).

## Further documentation

See the [`doc`](./doc) folder for additional documentation.
