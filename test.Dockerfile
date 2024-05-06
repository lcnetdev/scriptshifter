FROM python:3.10-slim-bookworm

RUN apt update
RUN apt install -y build-essential libpcre2-dev

RUN pip install uwsgi

