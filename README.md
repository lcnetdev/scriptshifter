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

Test service:

```
curl localhost:8000/health
```

TODO: API endpoints are stubs at the moment.
