FROM python:3.9-alpine3.15

RUN apk add --no-cache -t buildtools build-base
RUN apk add --no-cache linux-headers

ENV _workroot "/usr/local/scriptshifter/src"

WORKDIR ${_workroot}
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY entrypoint.sh uwsgi.ini wsgi.py ./

COPY ext ./ext/
RUN pip install ext/arabic_transliterator

COPY scriptshifter ./scriptshifter/
RUN chmod +x ./entrypoint.sh
RUN addgroup -S www && adduser -S www -G www
RUN chown -R www:www ${_workroot} .

# Remove development packages.
RUN apk del buildtools

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
