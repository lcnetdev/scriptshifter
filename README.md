# transliterator

REST API service to convert non-Latin scripts to Latin, and vice versa.

## Run on Docker

Build container in current dir:

```
docker build -t transliterator:latest .
```

Start container:

```
docker run -e TXL_FLASK_SECRET=changeme -p 8000:8000 transliterator:latest
```

For running in development mode, add `-e FLASK_ENV=development` to the options.


## Web UI

`/` renders a simple HTML form to test the transliteration service.


## Further documentation

See the [`doc`](./doc) folder for additional documentation.
